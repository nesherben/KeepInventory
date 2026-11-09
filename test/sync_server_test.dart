import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/core/services/sync_approval.dart';
import 'package:keepinventory/core/services/sync_invite.dart';
import 'package:keepinventory/core/services/sync_service.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;

void main() {
  late Directory dir;
  late File db;
  late SyncApprovalGate gate;
  late List<SyncRequest> requests;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('sync_server_test');
    db = File('${dir.path}/keepinventory.db')..writeAsBytesSync([1, 2, 3, 4]);
    requests = [];
    gate = SyncApprovalGate(onRequest: requests.add, maxDownloads: 2);
  });

  tearDown(() async {
    gate.dispose();
    await dir.delete(recursive: true);
  });

  Future<shelf.Response> get(String path) async {
    final handler = SyncService.buildSyncHandler(db, 'secret', gate);
    return await handler(
      shelf.Request('GET', Uri.parse('http://localhost:8080$path')),
    );
  }

  Future<String> body(String path) async => (await get(path)).readAsString();

  const id = 'request-123456';

  test('every route requires the QR token', () async {
    for (final path in [
      '/ping',
      '/request?id=$id&device=X',
      '/status?id=$id',
      '/download-db?id=$id',
    ]) {
      expect((await get(path)).statusCode, 403, reason: path);
      final sep = path.contains('?') ? '&' : '?';
      expect(
        (await get('$path${sep}token=wrong')).statusCode,
        403,
        reason: path,
      );
    }
    expect(requests, isEmpty);
  });

  test('data is NOT served until the sender approves', () async {
    expect(
      await body('/request?token=secret&id=$id&device=Pixel 8'),
      'pending',
    );
    expect(requests.single.device, 'Pixel 8');
    expect(await body('/status?token=secret&id=$id'), 'pending');
    expect((await get('/download-db?token=secret&id=$id')).statusCode, 403);

    gate.approve(id);

    expect(await body('/status?token=secret&id=$id'), 'approved');
    final ok = await get('/download-db?token=secret&id=$id');
    expect(ok.statusCode, 200);
    expect(await ok.read().expand((c) => c).toList(), [1, 2, 3, 4]);
  });

  test('a denied request never gets the data', () async {
    await get('/request?token=secret&id=$id&device=X');
    gate.deny(id);
    expect(await body('/status?token=secret&id=$id'), 'denied');
    expect((await get('/download-db?token=secret&id=$id')).statusCode, 403);
    // Aprobar después de rechazar no tiene efecto
    gate.approve(id);
    expect(await body('/status?token=secret&id=$id'), 'denied');
  });

  test('approval allows a limited number of downloads (retries)', () async {
    await get('/request?token=secret&id=$id&device=X');
    gate.approve(id);
    expect((await get('/download-db?token=secret&id=$id')).statusCode, 200);
    expect((await get('/download-db?token=secret&id=$id')).statusCode, 200);
    expect((await get('/download-db?token=secret&id=$id')).statusCode, 403);
  });

  test('another request id cannot reuse an approval', () async {
    await get('/request?token=secret&id=$id&device=X');
    gate.approve(id);
    expect(
      (await get('/download-db?token=secret&id=other-request-999')).statusCode,
      403,
    );
    expect(await body('/status?token=secret&id=other-request-999'), 'unknown');
  });

  test('repeated /request for the same id notifies the sender once', () async {
    await get('/request?token=secret&id=$id&device=X');
    await get('/request?token=secret&id=$id&device=X');
    expect(requests, hasLength(1));
  });

  test('rejects too-short request ids', () async {
    expect((await get('/request?token=secret&id=abc')).statusCode, 400);
  });

  group('SyncApprovalGate', () {
    test('unanswered requests are denied after the timeout', () async {
      final quick = SyncApprovalGate(
        onRequest: (_) {},
        pendingTimeout: const Duration(milliseconds: 30),
      );
      quick.register(SyncRequest(id: id, device: 'X'));
      await Future.delayed(const Duration(milliseconds: 80));
      expect(quick.status(id), SyncRequestStatus.denied);
      quick.dispose();
    });

    test('approvals expire', () async {
      final quick = SyncApprovalGate(
        onRequest: (_) {},
        approvalValidity: const Duration(milliseconds: 30),
      );
      quick.register(SyncRequest(id: id, device: 'X'));
      quick.approve(id);
      await Future.delayed(const Duration(milliseconds: 80));
      expect(quick.consumeDownload(id), isFalse);
      quick.dispose();
    });

    test('limits simultaneous pending requests', () {
      final small = SyncApprovalGate(onRequest: (_) {}, maxPending: 2);
      expect(small.register(SyncRequest(id: 'aaaaaaaa1', device: 'X')), isTrue);
      expect(small.register(SyncRequest(id: 'aaaaaaaa2', device: 'X')), isTrue);
      expect(
        small.register(SyncRequest(id: 'aaaaaaaa3', device: 'X')),
        isFalse,
      );
      small.dispose();
    });

    test('verification code is stable, 4 digits and differs by id', () {
      expect(verificationCode('abc'), verificationCode('abc'));
      expect(verificationCode('abc'), matches(RegExp(r'^\d{4}$')));
      final codes = {
        for (var i = 0; i < 50; i++) verificationCode('request-$i'),
      };
      expect(codes.length, greaterThan(40));
    });
  });
  group('end to end over a real local server', () {
    Future<(HttpServer, SyncInvite)> serve(SyncApprovalGate g) async {
      final server = await io.serve(
        SyncService.buildSyncHandler(db, 'secret', g),
        InternetAddress.loopbackIPv4,
        0,
      );
      final invite = SyncInvite(
        port: server.port,
        hosts: const ['127.0.0.1'],
        token: 'secret',
      );
      return (server, invite);
    }

    test('receiver waits until the sender approves', () async {
      late SyncApprovalGate g;
      g = SyncApprovalGate(
        onRequest: (r) => Future.delayed(
          const Duration(milliseconds: 300),
          () => g.approve(r.id),
        ),
      );
      final (server, invite) = await serve(g);
      final host = await SyncService.findReachableHost(invite);
      expect(host, '127.0.0.1');

      final status = await SyncService.requestApproval(
        invite,
        host!,
        'request-e2e-1',
        'Pixel',
      );
      expect(status, SyncRequestStatus.approved);
      g.dispose();
      await server.close(force: true);
    });

    test('receiver gets "denied" when the sender rejects', () async {
      late SyncApprovalGate g;
      g = SyncApprovalGate(onRequest: (r) => g.deny(r.id));
      final (server, invite) = await serve(g);
      final status = await SyncService.requestApproval(
        invite,
        '127.0.0.1',
        'request-e2e-2',
        'Pixel',
      );
      expect(status, SyncRequestStatus.denied);
      g.dispose();
      await server.close(force: true);
    });
  });

  group('same app version is required', () {
    Future<(HttpServer, SyncInvite)> serveVersion(
      SyncApprovalGate g,
      String version,
    ) async {
      final server = await io.serve(
        SyncService.buildSyncHandler(db, 'secret', g, appVersion: version),
        InternetAddress.loopbackIPv4,
        0,
      );
      final invite = SyncInvite(
        port: server.port,
        hosts: const ['127.0.0.1'],
        token: 'secret',
        appVersion: version,
      );
      return (server, invite);
    }

    test('sender rejects a receiver on another version', () async {
      final requested = <SyncRequest>[];
      final g = SyncApprovalGate(onRequest: requested.add);
      final (server, invite) = await serveVersion(g, '1.14.1');
      final status = await SyncService.requestApproval(
        invite,
        '127.0.0.1',
        'request-ver-1',
        'Pixel',
        appVersion: '1.14.0',
      );
      expect(status, SyncRequestStatus.versionMismatch);
      expect(requested, isEmpty); // el emisor ni siquiera ve la solicitud
      g.dispose();
      await server.close(force: true);
    });

    test('old receivers that send no version are rejected too', () async {
      final g = SyncApprovalGate(onRequest: (_) {});
      final (server, invite) = await serveVersion(g, '1.14.1');
      final status = await SyncService.requestApproval(
        invite,
        '127.0.0.1',
        'request-ver-2',
        'Pixel',
      );
      expect(status, SyncRequestStatus.versionMismatch);
      g.dispose();
      await server.close(force: true);
    });

    test('same version goes through to approval', () async {
      late SyncApprovalGate g;
      g = SyncApprovalGate(onRequest: (r) => g.approve(r.id));
      final (server, invite) = await serveVersion(g, '1.14.1');
      final status = await SyncService.requestApproval(
        invite,
        '127.0.0.1',
        'request-ver-3',
        'Pixel',
        appVersion: '1.14.1',
      );
      expect(status, SyncRequestStatus.approved);
      g.dispose();
      await server.close(force: true);
    });
  });
}
