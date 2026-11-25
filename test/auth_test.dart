// T03–T04 — Registrazione, login, logout (R1, R2, R3).
import 'dart:io';

import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  final server = useTestServer();

  group('R1 registrazione', () {
    test('AC-R1-01 dati validi → 201 con dati pubblici', () async {
      final r = await server().api.register('hr@acme.it');
      expect(r.status, 201);
      final body = r.json as Map;
      expect(body['id'], isA<int>());
      expect(body['name'], 'Acme Srl');
      expect(body['email'], 'hr@acme.it');
      expect(body['createdAt'], isA<String>());
    });

    test('AC-R1-02 email già registrata (anche con maiuscole) → 409', () async {
      await server().api.register('hr@acme.it');
      final r = await server().api.register('HR@Acme.it');
      expect(r.status, 409);
      expect(r.errorCode, 'EMAIL_TAKEN');
    });

    test('AC-R1-03 campi non validi → 400 con elenco campi', () async {
      final r = await server().api.post(
        '/api/auth/register',
        json: {'name': 'A', 'email': 'non-una-email', 'password': '123'},
      );
      expect(r.status, 400);
      expect(r.errorCode, 'VALIDATION_ERROR');
      final fields = (r.json as Map)['error']['fields'] as Map;
      expect(fields.keys, containsAll(['name', 'email', 'password']));
    });

    test('AC-R1-03 JSON malformato → 400', () async {
      final r = await server().api.post('/api/auth/register', rawBody: '{oops');
      expect(r.status, 400);
      expect(r.errorCode, 'VALIDATION_ERROR');
    });

    test('AC-R1-04 password mai restituita né salvata in chiaro', () async {
      const secret = 'PasswordSegretissima42';
      final r = await server().api.register('hr@acme.it', password: secret);
      expect(r.json.toString(), isNot(contains(secret)));
      expect((r.json as Map).containsKey('password'), isFalse);
      expect((r.json as Map).containsKey('passwordHash'), isFalse);
      final db = File('${server().dataDir.path}/bacheca.db');
      expect(
        db.existsSync(),
        isTrue,
        reason: 'DB atteso in <dataDir>/bacheca.db',
      );
      // controlla anche eventuali file -wal / -journal di SQLite
      for (final f in server().dataDir.listSync().whereType<File>()) {
        if (!f.path.contains('bacheca.db')) continue;
        expect(
          String.fromCharCodes(f.readAsBytesSync()),
          isNot(contains(secret)),
        );
      }
    });
  });

  group('R2 login', () {
    setUp(() async => server().api.register('hr@acme.it'));

    test('AC-R2-01 credenziali corrette → 200 token + azienda', () async {
      final r = await server().api.post(
        '/api/auth/login',
        json: {'email': 'hr@acme.it', 'password': 'Password123'},
      );
      expect(r.status, 200);
      expect((r.json as Map)['token'], isA<String>());
      expect((r.json as Map)['company']['email'], 'hr@acme.it');
    });

    test(
      'AC-R2-02 password errata ed email sconosciuta → stesso 401',
      () async {
        final wrongPwd = await server().api.post(
          '/api/auth/login',
          json: {'email': 'hr@acme.it', 'password': 'Sbagliata123'},
        );
        final unknown = await server().api.post(
          '/api/auth/login',
          json: {'email': 'nessuno@acme.it', 'password': 'Password123'},
        );
        expect(wrongPwd.status, 401);
        expect(unknown.status, 401);
        expect(wrongPwd.errorCode, 'INVALID_CREDENTIALS');
        expect(wrongPwd.json, unknown.json);
      },
    );

    test('AC-R2-05 campi mancanti o JSON malformato → 400', () async {
      final missing = await server().api.post(
        '/api/auth/login',
        json: {'email': 'hr@acme.it'},
      );
      final bad = await server().api.post('/api/auth/login', rawBody: '{oops');
      for (final r in [missing, bad]) {
        expect(r.status, 400);
        expect(r.errorCode, 'VALIDATION_ERROR');
      }
    });

    test('AC-R2-01 email confrontata senza maiuscole/spazi', () async {
      final r = await server().api.post(
        '/api/auth/login',
        json: {'email': ' HR@Acme.it ', 'password': 'Password123'},
      );
      expect(r.status, 200);
    });
  });

  group('R3 logout e rotte protette', () {
    test('AC-R3-01 dopo il logout il token non vale più', () async {
      final token = await server().api.registerAndLogin('hr@acme.it');
      expect((await server().api.get('/api/me', token: token)).status, 200);
      final out = await server().api.post('/api/auth/logout', token: token);
      expect(out.status, 204);
      final me = await server().api.get('/api/me', token: token);
      expect(me.status, 401);
    });

    test(
      'AC-R3-03 rotta riservata senza token o con token falso → 401',
      () async {
        final none = await server().api.get('/api/me');
        final fake = await server().api.get(
              '/api/me',
              token: 'token-inventato',
            );
        expect(none.status, 401);
        expect(none.errorCode, 'UNAUTHORIZED');
        expect(fake.status, 401);
      },
    );
  });
}
