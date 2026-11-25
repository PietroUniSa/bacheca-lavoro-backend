// T06 — dettagli di E9–E12 non coperti da applications_test.dart.
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

  test('AC-R7-04 Content-Disposition inline con nome ripulito', () async {
    final r = await server()
        .api
        .apply(jobId, file: tinyPdf('x'), fileName: 'cv Mario Rossì.pdf');
    final id = (r.json as Map)['id'];
    final cv = await server().api.get('/api/applications/$id/cv', token: token);
    expect(cv.status, 200);
    expect(cv.headers['content-disposition'],
        startsWith('inline; filename="cv_Mario_Ross_.pdf"'));
    expect((r.json as Map)['cvOriginalName'], 'cv Mario Rossì.pdf');
  });

  test('AC-R6-01 Content-Type della parte ignorato (octet-stream accettato)',
      () async {
    // http.MultipartFile.fromBytes senza contentType invia
    // application/octet-stream, come fanno l'app e le fixture.
    final r = await server().api.apply(jobId, file: tinyPdf('x'));
    expect(r.status, 201);
    expect((r.json as Map)['cvSize'], tinyPdf('x').length);
  });

  test('AC-R3-03 E10–E12 senza token → 401', () async {
    final id = await server().api.createApplication(jobId);
    for (final path in [
      '/api/jobs/$jobId/applications',
      '/api/applications/$id',
      '/api/applications/$id/cv',
    ]) {
      final r = await server().api.get(path);
      expect(r.status, 401, reason: path);
      expect(r.errorCode, 'UNAUTHORIZED');
    }
  });

  test('AC-R7-02 candidature di un annuncio inesistente → 404', () async {
    final r =
        await server().api.get('/api/jobs/99999/applications', token: token);
    expect(r.status, 404);
    expect(r.errorCode, 'NOT_FOUND');
  });

  test('AC-R7-02 lista dalla candidatura più recente', () async {
    final first = await server().api.createApplication(jobId);
    final second = await server().api.createApplication(jobId);
    final r =
        await server().api.get('/api/jobs/$jobId/applications', token: token);
    expect(r.items.map((a) => a['id']).toList(), [second, first]);
  });
}
