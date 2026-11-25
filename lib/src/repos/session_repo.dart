import 'dart:convert';
import 'dart:math';

import 'package:sqlite3/sqlite3.dart';

/// Sessioni con token opaco (ADR A3): il logout cancella la riga.
class SessionRepo {
  SessionRepo(this._db);
  final Database _db;
  static final _random = Random.secure();

  /// Nuovo token: 32 byte casuali in base64url (senza padding).
  String create(int companyId) {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    final token = base64Url.encode(bytes).replaceAll('=', '');
    _db.execute(
      'INSERT INTO sessions (token, company_id, created_at) VALUES (?, ?, ?)',
      [token, companyId, DateTime.now().toUtc().toIso8601String()],
    );
    return token;
  }

  /// Azienda proprietaria del token, o null se il token non esiste.
  int? companyIdFor(String token) {
    final rows =
        _db.select('SELECT company_id FROM sessions WHERE token = ?', [token]);
    return rows.isEmpty ? null : rows.first['company_id'] as int;
  }

  void delete(String token) =>
      _db.execute('DELETE FROM sessions WHERE token = ?', [token]);
}
