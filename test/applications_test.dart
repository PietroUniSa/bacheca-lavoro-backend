// T06 — Candidature (R6) e consultazione con CV (R7).
import 'dart:io';

import 'package:test/test.dart';

import 'support/api.dart';
import 'support/harness.dart';

void main() {
  final server = useTestServer();
  late String token;
  late int jobId;

  setUp(() async {
    token = await server().api.registerAndLogin('hr@acme.it');
    jobId = await server().api.createJob(token);
  });

  int uploadedFiles() {
    final dir = Directory('${server().dataDir.path}/uploads');
    return dir.existsSync() ? dir.listSync().length : 0;
  }

  group('R6 candidatura', () {
    test('AC-R6-01 dati validi + PDF → 201 e file salvato', () async {
      final r = await server().api.apply(
            jobId,
            file: tinyPdf('x'),
            fileName: 'cv_mario_rossi.pdf',
          );
      expect(r.status, 201);
      final body = r.json as Map;
      expect(body['firstName'], 'Mario');
      expect(body['jobId'], jobId);
      expect(body['cvOriginalName'], 'cv_mario_rossi.pdf');
      expect(uploadedFiles(), 1);
    });

    test(
      'AC-R6-02 campi mancanti o email non valida → 400, nessun file',
      () async {
        final r = await server().api.apply(
              jobId,
              fields: {'firstName': '', 'lastName': 'Rossi', 'email': 'mario@'},
              file: tinyPdf('x'),
            );
        expect(r.status, 400);
        expect(r.errorCode, 'VALIDATION_ERROR');
        final fields = (r.json as Map)['error']['fields'] as Map;
        expect(fields.keys, containsAll(['firstName', 'email']));
        expect(uploadedFiles(), 0);
      },
    );

    test(
      'AC-R6-03 file mancante, non PDF o oltre 5 MB → 400 INVALID_FILE',
      () async {
        final missing = await server().api.apply(jobId);
        final notPdf = await server().api.apply(
              jobId,
              file: 'ciao'.codeUnits,
              fileName: 'cv.pdf',
            );
        final big = List<int>.filled(5 * 1024 * 1024 + 1, 32)
          ..setAll(0, '%PDF'.codeUnits);
        final tooBig = await server().api.apply(jobId, file: big);
        for (final r in [missing, notPdf, tooBig]) {
          expect(r.status, 400);
          expect(r.errorCode, 'INVALID_FILE');
        }
        expect(uploadedFiles(), 0);
      },
    );

    test('AC-R6-04 annuncio inesistente → 404', () async {
      final r = await server().api.apply(99999, file: tinyPdf('x'));
      expect(r.status, 404);
      expect(r.errorCode, 'NOT_FOUND');
    });
  });

  group('R7 consultazione candidature', () {
    late int appId;
    late String otherToken;

    setUp(() async {
      appId = await server().api.createApplication(jobId);
      otherToken = await server().api.registerAndLogin(
            'hr@beta.it',
            name: 'Beta Spa',
          );
    });

    test('AC-R7-02 il proprietario vede le candidature; altri → 403', () async {
      final mine = await server().api.get(
            '/api/jobs/$jobId/applications',
            token: token,
          );
      expect(mine.status, 200);
      expect(mine.items.single['id'], appId);
      final other = await server().api.get(
            '/api/jobs/$jobId/applications',
            token: otherToken,
          );
      expect(other.status, 403);
      expect(other.errorCode, 'FORBIDDEN');
      final anon = await server().api.get('/api/jobs/$jobId/applications');
      expect(anon.status, 401);
    });

    test('AC-R7-03 dettaglio candidatura con i dati del candidato', () async {
      final r = await server().api.get(
            '/api/applications/$appId',
            token: token,
          );
      expect(r.status, 200);
      final a = r.json as Map;
      expect(
        [a['firstName'], a['lastName'], a['email']],
        ['Mario', 'Rossi', 'mario.rossi@example.com'],
      );
      expect(DateTime.tryParse(a['createdAt'] as String), isNotNull);
      final other = await server().api.get(
            '/api/applications/$appId',
            token: otherToken,
          );
      expect(other.status, 403);
    });

    test('AC-R7-04 CV identico all\'originale, solo al proprietario', () async {
      final original = tinyPdf('Mario Rossi');
      final r = await server().api.get(
            '/api/applications/$appId/cv',
            token: token,
          );
      expect(r.status, 200);
      expect(r.headers['content-type'], startsWith('application/pdf'));
      expect(r.bytes, original);
      final other = await server().api.get(
            '/api/applications/$appId/cv',
            token: otherToken,
          );
      expect(other.status, 403);
      final missing = await server().api.get(
            '/api/applications/99999/cv',
            token: token,
          );
      expect(missing.status, 404);
    });
  });
}
