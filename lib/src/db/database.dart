import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'schema.dart';

/// Apre (creandoli se mancano) `dataDir` e `<dataDir>/bacheca.db`, attiva le
/// foreign key e applica lo schema. Chi apre il database lo chiude (`close`).
Database openDatabase(String dataDir) {
  Directory(dataDir).createSync(recursive: true);
  final db = sqlite3.open('$dataDir${Platform.pathSeparator}bacheca.db');
  try {
    db.execute('PRAGMA foreign_keys = ON');
    for (final statement in schemaStatements) {
      db.execute(statement);
    }
    return db;
  } catch (_) {
    db.close();
    rethrow;
  }
}
