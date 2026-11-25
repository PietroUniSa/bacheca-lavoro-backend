// T07 — Persistenza: i dati sopravvivono al riavvio del server.
import 'package:test/test.dart';

import 'support/api.dart';
import 'support/harness.dart';

void main() {
  final server = useTestServer();

  test(
    'AC-NF-01 aziende, annunci, candidature e CV restano dopo il riavvio',
    () async {
      final token = await server().api.registerAndLogin('hr@acme.it');
      final jobId = await server().api.createJob(token);
      final appId = await server().api.createApplication(jobId);

      await server().restart();

      // l'account esiste ancora: si può rifare login
      final login = await server().api.post(
        '/api/auth/login',
        json: {'email': 'hr@acme.it', 'password': 'Password123'},
      );
      expect(login.status, 200);
      final newToken = (login.json as Map)['token'] as String;

      // anche la vecchia sessione è persistente (fino al logout): AC-R2-04 lato server
      expect((await server().api.get('/api/me', token: token)).status, 200);

      final board = await server().api.get('/api/jobs');
      expect(board.items.map((j) => j['id']), contains(jobId));

      final apps = await server().api.get(
        '/api/jobs/$jobId/applications',
        token: newToken,
      );
      expect(apps.items.single['id'], appId);

      final cv = await server().api.get(
        '/api/applications/$appId/cv',
        token: newToken,
      );
      expect(cv.status, 200);
      expect(cv.bytes, tinyPdf('Mario Rossi'));
    },
  );
}
