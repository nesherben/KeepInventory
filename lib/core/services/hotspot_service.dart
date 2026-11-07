import 'package:flutter/services.dart';

/// Datos del punto de acceso creado por el emisor.
class HotspotInfo {
  const HotspotInfo({
    required this.ssid,
    required this.password,
    required this.security,
  });

  final String ssid;
  final String password;
  final String security;
}

/// Motivos de fallo que la interfaz sabe explicar al usuario.
enum HotspotError {
  permissionDenied,
  locationOff,
  incompatibleMode,
  unsupported,
  unavailable,
  failed,
}

class HotspotException implements Exception {
  const HotspotException(this.error, [this.message]);

  final HotspotError error;
  final String? message;

  static HotspotException fromPlatform(PlatformException e) =>
      HotspotException(switch (e.code) {
        'permission_denied' => HotspotError.permissionDenied,
        'location_off' => HotspotError.locationOff,
        'incompatible_mode' || 'busy' => HotspotError.incompatibleMode,
        'unsupported' => HotspotError.unsupported,
        'unavailable' => HotspotError.unavailable,
        _ => HotspotError.failed,
      }, e.message);

  @override
  String toString() => 'HotspotException($error, $message)';
}

/// Puente con el código nativo de Android (HotspotChannel.kt).
abstract final class HotspotService {
  static const _channel = MethodChannel('com.example.keepinventory/hotspot');

  /// Emisor: crea un punto de acceso local (pide permisos si hace falta).
  static Future<HotspotInfo> start() async {
    try {
      final map = await _channel.invokeMapMethod<String, String>(
        'startHotspot',
      );
      if (map == null || (map['ssid'] ?? '').isEmpty) {
        throw const HotspotException(HotspotError.failed);
      }
      return HotspotInfo(
        ssid: map['ssid']!,
        password: map['password'] ?? '',
        security: map['security'] ?? 'wpa2',
      );
    } on PlatformException catch (e) {
      throw HotspotException.fromPlatform(e);
    } on MissingPluginException {
      throw const HotspotException(HotspotError.unsupported);
    }
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stopHotspot');
    } catch (_) {}
  }

  /// Receptor (Android 10+): se conecta a la red del emisor. Devuelve la
  /// puerta de enlace (normalmente la IP del emisor) si se conoce.
  static Future<String?> connect({
    required String ssid,
    String? password,
    String security = 'wpa2',
  }) async {
    try {
      final map = await _channel.invokeMapMethod<String, String?>('connect', {
        'ssid': ssid,
        'password': password,
        'security': security,
      });
      return map?['gateway'];
    } on PlatformException catch (e) {
      throw HotspotException.fromPlatform(e);
    } on MissingPluginException {
      throw const HotspotException(HotspotError.unsupported);
    }
  }

  /// Vuelve a la red normal del móvil.
  static Future<void> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');
    } catch (_) {}
  }

  /// Nombre legible de este móvil (marca y modelo).
  static Future<String> deviceName() async {
    try {
      return await _channel.invokeMethod<String>('deviceName') ?? 'Android';
    } catch (_) {
      return 'Android';
    }
  }

  static Future<bool> canConnectAutomatically() async {
    try {
      return await _channel.invokeMethod<bool>('canConnectAutomatically') ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openLocationSettings() async {
    try {
      await _channel.invokeMethod('openLocationSettings');
    } catch (_) {}
  }
}
