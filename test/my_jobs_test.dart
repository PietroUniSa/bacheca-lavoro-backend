// T05 — E8 e E6 senza dipendere dalle candidature (che arrivano in T06).
import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  final server = useTestServer();

  test('AC-R7-01 i miei annunci senza candidature: applicationCount 0',
      () async {
    final token = await server().api.registerAndLogin('hr@acme.it');
    final id = await server().api.createJob(token);
    final r = await server().api.get('/api/companies/me/jobs', token: token);
    expect(r.status, 200);
    expect(r.items.single['id'], id);
    expect(r.items.single['companyName'], 'Acme Srl');
    expect(r.items.single['applicationCount'], 0);
  });

  test('AC-R7-01 i miei annunci senza token → 401', () async {
    final r = await server().api.get('/api/companies/me/jobs');
    expect(r.status, 401);
    expect(r.errorCode, 'UNAUTHORIZED');
  });

  test('AC-R5-02 id non numerico → 404', () async {
    final r = await server().api.get('/api/jobs/abc');
    expect(r.status, 404);
    expect(r.errorCode, 'NOT_FOUND');
  });
}
