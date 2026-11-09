import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/core/services/sync_invite.dart';

void main() {
  group('SyncInvite', () {
    test('hotspot invite round-trips through the QR text', () {
      const invite = SyncInvite(
        port: 8080,
        hosts: ['192.168.49.1', '10.0.0.7'],
        token: 'abc123',
        ssid: 'AndroidShare_1234',
        password: 'p@ss w&rd=;',
        security: 'wpa3',
      );
      final parsed = SyncInvite.parse(invite.toQrData())!;

      expect(parsed.usesHotspot, isTrue);
      expect(parsed.ssid, 'AndroidShare_1234');
      expect(parsed.password, 'p@ss w&rd=;'); // caracteres especiales
      expect(parsed.security, 'wpa3');
      expect(parsed.port, 8080);
      expect(parsed.hosts, ['192.168.49.1', '10.0.0.7']);
      expect(parsed.token, 'abc123');
      expect(parsed.legacyUrl, isNull);
    });

    test('carries the sender app version (null in old QRs)', () {
      const invite = SyncInvite(
        port: 8080,
        hosts: ['10.0.0.1'],
        token: 't',
        appVersion: '1.14.1',
      );
      expect(SyncInvite.parse(invite.toQrData())!.appVersion, '1.14.1');
      const old = SyncInvite(port: 8080, hosts: ['10.0.0.1'], token: 't');
      expect(SyncInvite.parse(old.toQrData())!.appVersion, isNull);
      expect(
        invite
            .requestUri('h', 'id', 'dev', appVersion: '1.14.1')
            .queryParameters['app'],
        '1.14.1',
      );
    });

    test('same-wifi invite has no hotspot data', () {
      const invite = SyncInvite(
        port: 8080,
        hosts: ['192.168.1.20'],
        token: 't',
      );
      final parsed = SyncInvite.parse(invite.toQrData())!;
      expect(parsed.usesHotspot, isFalse);
      expect(parsed.ssid, isNull);
      expect(invite.toQrData(), isNot(contains('ssid')));
    });

    test('download and ping URIs carry the token', () {
      const invite = SyncInvite(port: 8080, hosts: ['10.0.0.1'], token: 'tok');
      expect(
        invite.downloadUri('10.0.0.1').toString(),
        'http://10.0.0.1:8080/download-db?token=tok',
      );
      expect(
        invite.pingUri('10.0.0.1').toString(),
        'http://10.0.0.1:8080/ping?token=tok',
      );
    });

    test('accepts the legacy QR of older app versions', () {
      final parsed = SyncInvite.parse('http://192.168.1.33:8080/download-db')!;
      expect(parsed.hosts, ['192.168.1.33']);
      expect(parsed.port, 8080);
      expect(parsed.usesHotspot, isFalse);
      expect(
        parsed.downloadUri('ignored').toString(),
        'http://192.168.1.33:8080/download-db',
      );
    });

    test('rejects unrelated or malformed QR codes', () {
      expect(SyncInvite.parse(null), isNull);
      expect(SyncInvite.parse(''), isNull);
      expect(SyncInvite.parse('https://example.com'), isNull);
      expect(SyncInvite.parse('WIFI:S:net;P:pw;;'), isNull);
      expect(SyncInvite.parse('keepinventory://sync?v=2&port=abc'), isNull);
      expect(SyncInvite.parse('keepinventory://sync?v=2&port=99999'), isNull);
      expect(SyncInvite.parse('keepinventory://other?port=8080'), isNull);
    });

    test('tokens are random and unambiguous', () {
      final a = SyncInvite.newToken();
      final b = SyncInvite.newToken();
      expect(a, hasLength(24));
      expect(a, isNot(b));
      expect(a, isNot(matches(RegExp('[0O1lI]'))));
    });
  });
}
