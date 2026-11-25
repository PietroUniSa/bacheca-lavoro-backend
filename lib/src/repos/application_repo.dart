import 'package:sqlite3/sqlite3.dart';

/// Candidatura (schema `Application`) + dati interni non esposti.
class JobApplication {
  const JobApplication(this.row);
  final Row row;

  int get id => row['id'] as int;

  /// Azienda proprietaria dell'annuncio (per il controllo 403).
  int get ownerCompanyId => row['owner_company_id'] as int;
  String get cvFileName => row['cv_file_name'] as String;
  String get cvOriginalName => row['cv_original_name'] as String;

  Map<String, Object?> toJson() => {
        'id': id,
        'jobId': row['job_id'],
        'firstName': row['first_name'],
        'lastName': row['last_name'],
        'email': row['email'],
        'cvOriginalName': cvOriginalName,
        'cvSize': row['cv_size'],
        'createdAt': row['created_at'],
      };
}

class NewApplication {
  const NewApplication(this.jobId, this.firstName, this.lastName, this.email,
      this.cvFileName, this.cvOriginalName, this.cvSize);
  final int jobId;
  final String firstName, lastName, email, cvFileName, cvOriginalName;
  final int cvSize;
}

const _select = 'SELECT a.*, j.company_id AS owner_company_id '
    'FROM applications a JOIN jobs j ON j.id = a.job_id';

/// Accesso SQL alla tabella `applications` (solo query parametrizzate).
class ApplicationRepo {
  ApplicationRepo(this._db);
  final Database _db;

  JobApplication insert(NewApplication a) {
    _db.execute(
      'INSERT INTO applications (job_id, first_name, last_name, email, '
      'cv_file_name, cv_original_name, cv_size, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [
        a.jobId, a.firstName, a.lastName, a.email, a.cvFileName, //
        a.cvOriginalName, a.cvSize, DateTime.now().toUtc().toIso8601String(),
      ],
    );
    return findById(_db.lastInsertRowId)!;
  }

  JobApplication? findById(int id) {
    final rows = _db.select('$_select WHERE a.id = ?', [id]);
    return rows.isEmpty ? null : JobApplication(rows.first);
  }

  /// Candidature di un annuncio, dalla più recente (specs/04).
  List<JobApplication> listByJob(int jobId) => _db
      .select(
          '$_select WHERE a.job_id = ? '
          'ORDER BY a.created_at DESC, a.id DESC',
          [jobId])
      .map(JobApplication.new)
      .toList();
}
