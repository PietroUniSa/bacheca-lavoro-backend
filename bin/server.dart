// Avvio: dart run bin/server.dart --port 8080 --data-dir ./data
import 'dart:io';

import 'package:args/args.dart';
import 'package:bacheca_backend/bacheca_backend.dart';

Future<void> main(List<String> argv) async {
  final parser = ArgParser()
    ..addOption('port', defaultsTo: '8080', help: 'Porta HTTP')
    ..addOption('data-dir',
        help: 'Cartella dati (default: env DATA_DIR o ./data)')
    ..addFlag('help', abbr: 'h', negatable: false);

  final ArgResults args;
  try {
    args = parser.parse(argv);
  } on FormatException catch (e) {
    stderr.writeln('${e.message}\n${parser.usage}');
    exit(64);
  }
  if (args.flag('help')) {
    stdout.writeln(parser.usage);
    return;
  }

  final port = int.tryParse(args.option('port')!);
  if (port == null) {
    stderr.writeln('--port non valida: ${args.option('port')}');
    exit(64);
  }
  final dataDir =
      args.option('data-dir') ?? Platform.environment['DATA_DIR'] ?? './data';

  final server = await startServer(ServerConfig(dataDir: dataDir, port: port));
  stdout.writeln('Bacheca backend su http://0.0.0.0:${server.port} '
      '(dati: $dataDir)');
}
