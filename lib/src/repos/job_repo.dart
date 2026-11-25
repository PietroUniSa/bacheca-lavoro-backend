import 'package:sqlite3/sqlite3.dart';

import '../validation/job_validator.dart';

/// Annuncio come esposto dall'API (schema `Job`, o `MyJob` con il conteggio).
class Job {
  const Job(this.row);
  final Row row;

  int get id => row['id'] as int;
  int get companyId => row['company_id'] as int;

  Map<String, Object?> toJson() => {
        'id': id,
        'title': row['title'],
        'description': row['description'],
        'location': row['location'],
        'companyId': companyId,
        'companyName': row['company_name'],
        'createdAt': row['created_at'],
        if (row.containsKey('application_count'))
          'applicationCount': row['application_count'],
      };
}

const _select = 'SELECT j.id, j.company_id, j.title, j.description, '
    'j.location, j.created_at, c.name AS company_name';
const _from = 'FROM jobs j JOIN companies c ON c.id = j.company_id';
const _order = 'ORDER BY j.created_at DESC, j.id DESC';

/// Accesso SQL alla tabella `jobs` (solo query parametrizzate).
class JobRepo {
  JobRepo(this._db);
  final Database _db;

  Job insert(int companyId, JobInput input) {
    _db.execute(
      'INSERT INTO jobs (company_id, title, description, location, created_at) '
      'VALUES (?, ?, ?, ?, ?)',
      [
        companyId,
        input.title,
        input.description,
        input.location,
        DateTime.now().toUtc().toIso8601String(),
      ],
    );
    return findById(_db.lastInsertRowId)!;
  }

  Job? findById(int id) {
    final rows = _db.select('$_select $_from WHERE j.id = ?', [id]);
    return rows.isEmpty ? null : Job(rows.first);
  }

  /// Bacheca pubblica (E5): dal più recente.
  List<Job> listAll() =>
      _db.select('$_select $_from $_order').map(Job.new).toList();

  /// I miei annunci (E8) con il numero di candidature.
  List<Job> listByCompany(int companyId) => _db
      .select(
        '$_select, (SELECT COUNT(*) FROM applications a WHERE a.job_id = j.id) '
        'AS application_count $_from WHERE j.company_id = ? $_order',
        [companyId],
      )
      .map(Job.new)
      .toList();
}
