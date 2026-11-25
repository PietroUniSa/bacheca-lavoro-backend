/// Configurazione del server (firma obbligatoria: specs/05-architecture.md).
class ServerConfig {
  const ServerConfig({
    required this.dataDir,
    this.host = '0.0.0.0',
    this.port = 8080,
    this.pbkdf2Iterations = 100000,
  });

  /// Cartella con `bacheca.db` e `uploads/`.
  final String dataDir;
  final String host;

  /// 0 = porta libera scelta dal sistema (usato dai test).
  final int port;
  final int pbkdf2Iterations;
}
