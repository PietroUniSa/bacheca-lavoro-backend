// T05 — Annunci: pubblicazione (R4), bacheca (R5), i miei annunci (R7).
import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  final server = useTestServer();
  late String token;

  setUp(() async => token = await server().api.registerAndLogin('hr@acme.it'));

  group('R4 pubblicazione', () {
    test('AC-R4-01 annuncio valido → 201 e visibile in bacheca', () async {
      final r = await server().api.post(
        '/api/jobs',
        token: token,
        json: {
          'title': 'Sviluppatore Flutter Junior',
          'description': 'Cerchiamo uno sviluppatore Flutter junior.',
        },
      );
      expect(r.status, 201);
      final job = r.json as Map;
      expect(job['title'], 'Sviluppatore Flutter Junior');
      expect(job['companyName'], 'Acme Srl');
      expect(job['location'], isNull);
      final board = await server().api.get('/api/jobs');
      expect(board.items.map((j) => j['id']), contains(job['id']));
    });

    test('AC-R4-02 senza token → 401 e nessun annuncio creato', () async {
      final r = await server().api.post(
        '/api/jobs',
        json: {'title': 'Titolo valido', 'description': 'Descrizione valida.'},
      );
      expect(r.status, 401);
      expect((await server().api.get('/api/jobs')).items, isEmpty);
    });

    test('AC-R4-03 titolo o descrizione non validi → 400', () async {
      final r = await server().api.post(
        '/api/jobs',
        token: token,
        json: {'title': 'ab', 'description': 'corta'},
      );
      expect(r.status, 400);
      expect(r.errorCode, 'VALIDATION_ERROR');
      final fields = (r.json as Map)['error']['fields'] as Map;
      expect(fields.keys, containsAll(['title', 'description']));
    });

    test('AC-R4-05 companyId nel body viene ignorato', () async {
      final r = await server().api.post(
        '/api/jobs',
        token: token,
        json: {
          'title': 'Titolo valido',
          'description': 'Descrizione valida.',
          'companyId': 999,
        },
      );
      expect(r.status, 201);
      expect((r.json as Map)['companyId'], isNot(999));
    });
  });

  group('R5 bacheca pubblica', () {
    test('AC-R5-01 elenco senza auth, dal più recente', () async {
      final first = await server().api.createJob(
            token,
            title: 'Primo annuncio',
          );
      final second = await server().api.createJob(
            token,
            title: 'Secondo annuncio',
          );
      final r = await server().api.get('/api/jobs');
      expect(r.status, 200);
      expect(r.items.map((j) => j['id']).toList(), [second, first]);
      expect(r.items.first['companyName'], 'Acme Srl');
    });

    test('AC-R5-02 dettaglio esistente → 200; inesistente → 404', () async {
      final id = await server().api.createJob(token);
      final ok = await server().api.get('/api/jobs/$id');
      expect(ok.status, 200);
      expect((ok.json as Map)['description'], contains('Flutter'));
      final missing = await server().api.get('/api/jobs/99999');
      expect(missing.status, 404);
      expect(missing.errorCode, 'NOT_FOUND');
    });
  });

  group('R7 i miei annunci', () {
    test('AC-R7-01 solo i propri annunci, con numero candidature', () async {
      final mine = await server().api.createJob(token);
      final other = await server().api.registerAndLogin(
            'hr@beta.it',
            name: 'Beta Spa',
          );
      await server().api.createJob(other, title: 'Annuncio di Beta');
      await server().api.createApplication(mine);
      await server().api.createApplication(mine);

      final r = await server().api.get('/api/companies/me/jobs', token: token);
      expect(r.status, 200);
      expect(r.items, hasLength(1));
      expect(r.items.single['id'], mine);
      expect(r.items.single['applicationCount'], 2);
    });
  });
}
