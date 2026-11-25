// T02 — Database e schema (specs/03-domain-model.md § Persistenza).
import 'dart:io';

import 'package:bacheca_backend/bacheca_backend.dart';
import 'package:bacheca_backend/src/db/database.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('bacheca_db_'));
  tearDown(() async => dir.delete(recursive: true));

  Set<String> tables(Database db) => db
      .select("SELECT name FROM sqlite_master WHERE type = 'table'")
      .map((r) => r['name'] as String)
      .toSet();

  test('crea <dataDir>/bacheca.db con le quattro tabelle', () {
    final dataDir = '${dir.path}/nuova';
    final db = openDatabase(dataDir);
    addTearDown(db.close);
    expect(File('$dataDir/bacheca.db').existsSync(), isTrue);
    expect(tables(db),
        containsAll(['companies', 'sessions', 'jobs', 'applications']));
  });

  test('foreign key attive: sessione di un\'azienda inesistente rifiutata', () {
    final db = openDatabase(dir.path);
    addTearDown(db.close);
    expect(db.select('PRAGMA foreign_keys').first.values.first, 1);
    expect(
      () => db.execute(
          "INSERT INTO sessions (token, company_id, created_at) VALUES ('t', 999, 'x')"),
      throwsA(isA<SqliteException>()),
    );
  });

  // AC-NF-01 (base): riaprire il database non ricrea né cancella i dati.
  test('idempotente: riapertura senza errori e dati conservati', () {
    final first = openDatabase(dir.path);
    first.execute(
        'INSERT INTO companies (name, email, password_hash, created_at) '
        "VALUES ('Acme Srl', 'hr@acme.it', 'h', '2026-11-25T00:00:00Z')");
    first.close();

    final second = openDatabase(dir.path);
    addTearDown(second.close);
    expect(
        second.select('SELECT name FROM companies').single['name'], 'Acme Srl');
  });

  test('email azienda univoca a livello di schema', () {
    final db = openDatabase(dir.path);
    addTearDown(db.close);
    const insert =
        'INSERT INTO companies (name, email, password_hash, created_at) '
        "VALUES ('A', 'hr@acme.it', 'h', 'x')";
    db.execute(insert);
    expect(() => db.execute(insert), throwsA(isA<SqliteException>()));
  });

  test('startServer apre il database nella dataDir e close() lo rilascia',
      () async {
    final server = await startServer(
        ServerConfig(dataDir: dir.path, host: '127.0.0.1', port: 0));
    expect(File('${dir.path}/bacheca.db').existsSync(), isTrue);
    await server.close();
    // Su Windows un file ancora aperto non si può cancellare.
    File('${dir.path}/bacheca.db').deleteSync();
  });
}
