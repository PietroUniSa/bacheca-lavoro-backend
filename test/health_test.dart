// T01 — walking skeleton: server avviabile, /health, errori JSON uniformi.
import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  final server = useTestServer();

  test('GET /health risponde 200 {"status":"ok"}', () async {
    final r = await server().api.get('/health');
    expect(r.status, 200);
    expect(r.json, {'status': 'ok'});
  });

  test('rotta inesistente → 404 nel formato errore unico', () async {
    final r = await server().api.get('/api/non-esiste');
    expect(r.status, 404);
    expect(r.errorCode, 'NOT_FOUND');
    expect((r.json as Map)['error']['message'], isA<String>());
  });
}
