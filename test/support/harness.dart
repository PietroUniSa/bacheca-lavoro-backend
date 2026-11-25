// Harness dei test di accettazione: avvia il server VERO (porta libera,
// cartella dati temporanea, PBKDF2 leggero) e lo chiude a fine test.
// Usa solo la firma obbligatoria di specs/05-architecture.md.
import 'dart:io';

import 'package:bacheca_backend/bacheca_backend.dart';
import 'package:test/test.dart';

import 'api.dart';

class TestServer {
  TestServer._(this._server, this.dataDir);

  RunningServer _server;
  final Directory dataDir;

  Api get api => Api(Uri.parse('http://127.0.0.1:${_server.port}'));

  static Future<TestServer> start({Directory? dataDir}) async {
    final dir =
        dataDir ?? await Directory.systemTemp.createTemp('bacheca_test_');
    final server = await startServer(_config(dir));
    return TestServer._(server, dir);
  }

  static ServerConfig _config(Directory dir) => ServerConfig(
        dataDir: dir.path,
        host: '127.0.0.1',
        port: 0,
        pbkdf2Iterations: 1000,
      );

  /// Riavvia il server sulla STESSA cartella dati (test di persistenza).
  Future<void> restart() async {
    await _server.close();
    _server = await startServer(_config(dataDir));
  }

  Future<void> stop() async {
    await _server.close();
    if (dataDir.existsSync()) await dataDir.delete(recursive: true);
  }
}

/// Registra setUp/tearDown di un server isolato per ogni test del gruppo.
TestServer Function() useTestServer() {
  late TestServer server;
  setUp(() async => server = await TestServer.start());
  tearDown(() async => server.stop());
  return () => server;
}
