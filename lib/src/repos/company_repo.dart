import 'package:sqlite3/sqlite3.dart';

/// Azienda come esposta dall'API (mai l'hash della password).
class Company {
  const Company(this.id, this.name, this.email, this.createdAt);
  final int id;
  final String name;
  final String email;
  final String createdAt;

  Map<String, Object> toJson() =>
      {'id': id, 'name': name, 'email': email, 'createdAt': createdAt};
}

/// Accesso SQL alla tabella `companies` (solo query parametrizzate).
class CompanyRepo {
  CompanyRepo(this._db);
  final Database _db;

  bool emailExists(String email) =>
      _db.select('SELECT 1 FROM companies WHERE email = ?', [email]).isNotEmpty;

  /// Azienda e hash della password, per il login. Null se l'email non esiste.
  ({Company company, String passwordHash})? findByEmail(String email) {
    final rows = _db.select(
        'SELECT id, name, email, created_at, password_hash '
        'FROM companies WHERE email = ?',
        [email]);
    if (rows.isEmpty) return null;
    return (
      company: _fromRow(rows.first),
      passwordHash: rows.first['password_hash'] as String,
    );
  }

  Company? findById(int id) {
    final rows = _db.select(
        'SELECT id, name, email, created_at FROM companies WHERE id = ?', [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  static Company _fromRow(Row r) => Company(r['id'] as int, r['name'] as String,
      r['email'] as String, r['created_at'] as String);

  Company insert(String name, String email, String passwordHash) {
    final createdAt = DateTime.now().toUtc().toIso8601String();
    _db.execute(
      'INSERT INTO companies (name, email, password_hash, created_at) '
      'VALUES (?, ?, ?, ?)',
      [name, email, passwordHash, createdAt],
    );
    return Company(_db.lastInsertRowId, name, email, createdAt);
  }
}
