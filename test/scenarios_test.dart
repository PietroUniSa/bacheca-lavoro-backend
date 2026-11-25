// T07 — Scenari S1–S3 di specs/02-scenarios.md, eseguiti a livello API
// in sequenza sullo stesso server (i dati si concatenano come nei video).
import 'package:test/test.dart';

import 'support/api.dart';
import 'support/harness.dart';

void main() {
  late TestServer server;
  late String token;
  late int jobId;
  late int appId;

  setUpAll(() async => server = await TestServer.start());
  tearDownAll(() async => server.stop());

  test(
    'S1 pubblicare un annuncio (AC-R1-01, AC-R2-01, AC-R4-01, AC-R5-01)',
    () async {
      final reg = await server.api.register('hr@acme.it');
      expect(reg.status, 201);
      final login = await server.api.post(
        '/api/auth/login',
        json: {'email': 'hr@acme.it', 'password': 'Password123'},
      );
      expect(login.status, 200);
      token = (login.json as Map)['token'] as String;
      jobId = await server.api.createJob(token);
      final board = await server.api.get('/api/jobs');
      expect(board.items.single['title'], 'Sviluppatore Flutter Junior');
    },
  );

  test('S2 candidarsi a un annuncio (AC-R5-01, AC-R5-02, AC-R6-01)', () async {
    final board = await server.api.get('/api/jobs');
    expect(board.items, isNotEmpty);
    final detail = await server.api.get('/api/jobs/$jobId');
    expect(detail.status, 200);
    final r = await server.api.apply(
      jobId,
      file: tinyPdf('Mario Rossi'),
      fileName: 'cv_mario_rossi.pdf',
    );
    expect(r.status, 201);
    appId = (r.json as Map)['id'] as int;
  });

  test(
    'S3 consultare le candidature e uscire (AC-R7-01..04, AC-R3-01)',
    () async {
      final mine = await server.api.get('/api/companies/me/jobs', token: token);
      expect(mine.items.single['applicationCount'], 1);
      final apps = await server.api.get(
        '/api/jobs/$jobId/applications',
        token: token,
      );
      expect(apps.items.single['lastName'], 'Rossi');
      final detail = await server.api.get(
        '/api/applications/$appId',
        token: token,
      );
      expect((detail.json as Map)['email'], 'mario.rossi@example.com');
      final cv = await server.api.get(
        '/api/applications/$appId/cv',
        token: token,
      );
      expect(cv.bytes, tinyPdf('Mario Rossi'));
      expect(
        (await server.api.post('/api/auth/logout', token: token)).status,
        204,
      );
      expect(
        (await server.api.get('/api/companies/me/jobs', token: token)).status,
        401,
      );
    },
  );
}
