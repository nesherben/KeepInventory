import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:keepinventory/l10n/generated/app_localizations.dart';

import '../database/database_helper.dart';
import 'database_file_installer.dart';
import 'sync_approval.dart';
import 'sync_invite.dart';

class SyncService {
  static HttpServer? _server;

  static const int port = 8080;

  /// Direcciones IPv4 de este móvil (Wi‑Fi, punto de acceso…), con las
  /// típicas de punto de acceso/Wi‑Fi Direct primero.
  static Future<List<String>> localIPv4Addresses() async {
    final result = <String>[];
    try {
      final wifiIp = await NetworkInfo().getWifiIP();
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && !addr.isLinkLocal) result.add(addr.address);
        }
      }
      if (wifiIp != null && wifiIp != '0.0.0.0' && !result.contains(wifiIp)) {
        result.add(wifiIp);
      }
    } catch (_) {}
    int rank(String ip) =>
        ip.startsWith('192.168.43.') || ip.startsWith('192.168.49.') ? 0 : 1;
    result.sort((a, b) => rank(a).compareTo(rank(b)));
    return result;
  }

  /// Rutas del servidor. Exige el [token] del QR y, además, que el emisor
  /// apruebe cada solicitud en pantalla ([gate]):
  ///
  /// 1. `/request?id=&device=` → registra la solicitud (el emisor la ve).
  /// 2. `/status?id=` → pending | approved | denied | unknown.
  /// 3. `/download-db?id=` → solo si está aprobada.
  static shelf.Handler buildSyncHandler(
    File file,
    String token,
    SyncApprovalGate gate,
  ) {
    final router = shelf_router.Router();
    bool authorized(shelf.Request request) =>
        request.url.queryParameters['token'] == token;
    final forbidden = shelf.Response.forbidden('forbidden');

    router.get('/ping', (shelf.Request request) {
      return authorized(request)
          ? shelf.Response.ok('keepinventory')
          : forbidden;
    });

    router.get('/request', (shelf.Request request) {
      if (!authorized(request)) return forbidden;
      final q = request.url.queryParameters;
      final id = q['id'];
      if (id == null || id.length < 8) return shelf.Response.badRequest();
      final info =
          request.context['shelf.io.connection_info'] as HttpConnectionInfo?;
      final accepted = gate.register(
        SyncRequest(
          id: id,
          device: (q['device'] ?? '').trim().isEmpty ? '?' : q['device']!,
          address: info?.remoteAddress.address,
        ),
      );
      return accepted
          ? shelf.Response.ok(gate.status(id).name)
          : shelf.Response(429, body: 'busy');
    });

    router.get('/status', (shelf.Request request) {
      if (!authorized(request)) return forbidden;
      return shelf.Response.ok(
        gate.status(request.url.queryParameters['id']).name,
      );
    });

    router.get('/download-db', (shelf.Request request) {
      if (!authorized(request)) return forbidden;
      if (!gate.consumeDownload(request.url.queryParameters['id'])) {
        return forbidden;
      }
      return shelf.Response.ok(
        file.openRead(),
        headers: {
          'Content-Type': 'application/octet-stream',
          'Content-Length': file.lengthSync().toString(),
        },
      );
    });
    return router.call;
  }

  /// Arranca el servidor. Devuelve las direcciones en las que escucha
  /// (null si falla; el motivo se comunica con [onError]).
  static Future<List<String>?> startServer(
    AppLocalizations l10n,
    Function(String) onError, {
    required String token,
    required SyncApprovalGate gate,
  }) async {
    try {
      final hosts = await localIPv4Addresses();
      if (hosts.isEmpty) {
        onError(l10n.syncNoIp);
        return null;
      }

      await DatabaseHelper.instance.resetDatabase();

      final dbPath = await getDatabasesPath();
      final file = File('$dbPath/keepinventory.db');
      if (!await file.exists()) {
        onError(l10n.syncLocalDbMissing);
        return null;
      }

      await stopServer();
      _server = await io.serve(
        buildSyncHandler(file, token, gate),
        InternetAddress.anyIPv4,
        port,
      );
      debugPrint('Sync server active on $hosts:$port');
      return hosts;
    } catch (e) {
      onError(l10n.syncStartFailed);
      return null;
    }
  }

  /// Busca qué dirección del emisor responde (prueba [preferredHosts]
  /// primero, p. ej. la puerta de enlace del punto de acceso).
  static Future<String?> findReachableHost(
    SyncInvite invite, {
    List<String> preferredHosts = const [],
  }) async {
    if (invite.legacyUrl != null) return invite.hosts.first;
    final candidates = {...preferredHosts, ...invite.hosts}.toList();
    for (var round = 0; round < 3; round++) {
      for (final host in candidates) {
        final client = http.Client();
        try {
          final response = await client
              .get(invite.pingUri(host))
              .timeout(const Duration(seconds: 3));
          if (response.statusCode == 200) return host;
        } catch (_) {
        } finally {
          client.close();
        }
      }
      // La red del punto de acceso puede tardar unos segundos en estar lista
      await Future.delayed(const Duration(seconds: 2));
    }
    return null;
  }

  static Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      debugPrint('Sync server stopped.');
    }
  }

  // --- 2. EL RECEPTOR DESCARGA EN STREAMING ---
  /// Pide la copia al emisor y espera a que la apruebe en su pantalla.
  /// Devuelve el estado final (approved, denied o unknown si no responde).
  static Future<SyncRequestStatus> requestApproval(
    SyncInvite invite,
    String host,
    String requestId,
    String deviceName, {
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final client = http.Client();
    try {
      final response = await client
          .get(invite.requestUri(host, requestId, deviceName))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return SyncRequestStatus.denied;

      final deadline = DateTime.now().add(timeout);
      while (DateTime.now().isBefore(deadline)) {
        try {
          final status = await client
              .get(invite.statusUri(host, requestId))
              .timeout(const Duration(seconds: 5));
          final value = SyncRequestStatus.values.firstWhere(
            (s) => s.name == status.body.trim(),
            orElse: () => SyncRequestStatus.unknown,
          );
          if (value == SyncRequestStatus.approved ||
              value == SyncRequestStatus.denied) {
            return value;
          }
        } catch (_) {}
        await Future.delayed(const Duration(seconds: 1));
      }
      return SyncRequestStatus.unknown;
    } catch (_) {
      return SyncRequestStatus.unknown;
    } finally {
      client.close();
    }
  }

  static Future<bool> importDatabase(
    SyncInvite invite,
    AppLocalizations l10n,
    Function(String status, double progress) onProgress, {
    List<String> preferredHosts = const [],
    String deviceName = 'Android',
  }) async {
    // 💡 1. LOCALIZAR AL EMISOR (prueba cada dirección del QR)
    onProgress(l10n.syncVerifyNetwork, 0.0);
    final host = await findReachableHost(
      invite,
      preferredHosts: preferredHosts,
    );
    if (host == null) {
      onProgress(l10n.syncSenderNotFound, -1.0);
      return false;
    }

    // 💡 2. EL EMISOR DEBE APROBAR LA COPIA (no aplica al QR antiguo)
    String? requestId;
    if (invite.legacyUrl == null) {
      requestId = SyncInvite.newToken(length: 16);
      onProgress(l10n.syncWaitingApproval(verificationCode(requestId)), -1.0);
      final decision = await requestApproval(
        invite,
        host,
        requestId,
        deviceName,
      );
      if (decision != SyncRequestStatus.approved) {
        onProgress(
          decision == SyncRequestStatus.denied
              ? l10n.syncDeniedBySender
              : l10n.syncApprovalTimeout,
          -1.0,
        );
        return false;
      }
    }
    final url = invite.downloadUri(host, requestId: requestId).toString();

    // 💡 2. DESCARGA CON AUTO-REINTENTO
    const int maxRetries = 3;
    const int delayBetweenRetries = 2; // Segundos

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      final client = http.Client();
      try {
        onProgress(
          l10n.syncSearchingConnection(
            attempt.toString(),
            maxRetries.toString(),
          ),
          0.0,
        );

        final request = http.Request('GET', Uri.parse(url));
        final response = await client
            .send(request)
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final totalBytes = response.contentLength ?? 0;
          int receivedBytes = 0;

          final dbPath = await getDatabasesPath();
          final realPath = '$dbPath/keepinventory.db';
          final tempPath = '$dbPath/keepinventory_temp.db';

          final tempFile = File(tempPath);
          if (await tempFile.exists()) await tempFile.delete();

          final sink = tempFile.openWrite();
          bool hasStreamError = false;

          try {
            await response.stream
                .listen(
                  (List<int> chunk) {
                    receivedBytes += chunk.length;
                    sink.add(chunk);

                    if (totalBytes > 0) {
                      final progress = receivedBytes / totalBytes;
                      onProgress(
                        l10n.syncDownloadingPercent(
                          (progress * 100).toStringAsFixed(0),
                        ),
                        progress,
                      );
                    } else {
                      onProgress(
                        l10n.syncDownloadingMegabytes(
                          (receivedBytes / 1024 / 1024).toStringAsFixed(2),
                        ),
                        -1.0,
                      );
                    }
                  },
                  onError: (e) {
                    hasStreamError = true;
                    debugPrint('Sync stream error: $e');
                  },
                  cancelOnError: true,
                )
                .asFuture();
          } catch (e) {
            hasStreamError = true;
          }

          await sink.flush();
          await sink.close();
          client.close();

          // 💡 VERIFICACIÓN DE INTEGRIDAD
          if (hasStreamError ||
              (totalBytes > 0 && receivedBytes < totalBytes)) {
            if (await tempFile.exists()) await tempFile.delete();

            if (attempt < maxRetries) {
              onProgress(l10n.syncNetworkCutRetry, 0.0);
              await Future.delayed(
                const Duration(seconds: delayBetweenRetries),
              );
              continue;
            } else {
              onProgress(l10n.syncUnstableDownload, -1.0);
              return false;
            }
          }

          // --- INSTALACIÓN SEGURA ---
          onProgress(l10n.syncInstalling, 1.0);

          await DatabaseHelper.instance.resetDatabase();

          final realFile = File(realPath);
          final backupPath = '$dbPath/keepinventory_failsafe.db';
          final backupFile = File(backupPath);

          if (await realFile.exists()) {
            await realFile.copy(backupFile.path);
          }

          return await DatabaseFileInstaller.installDownloadedFile(
            temporaryFile: tempFile,
            databaseFile: realFile,
            backupFile: backupFile,
            onProgress: onProgress,
            completedMessage: l10n.syncCompleted,
            failedMessage: l10n.syncApplyFailed,
          );
        } else {
          client.close();
          if (attempt < maxRetries) {
            await Future.delayed(const Duration(seconds: delayBetweenRetries));
            continue;
          }
          onProgress(l10n.syncServerRejected, -1.0);
          return false;
        }
      } catch (e) {
        client.close();
        if (attempt < maxRetries) {
          onProgress(l10n.syncNetworkRetry(attempt.toString()), 0.0);
          await Future.delayed(const Duration(seconds: delayBetweenRetries));
          continue;
        }
        onProgress(l10n.syncSenderNotFound, -1.0);
        return false;
      }
    }
    return false;
  }
}
