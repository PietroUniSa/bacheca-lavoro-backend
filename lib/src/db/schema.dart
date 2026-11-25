/// Schema SQLite (specs/03-domain-model.md). Idempotente: `IF NOT EXISTS`,
/// eseguito a ogni avvio. Date in ISO-8601 UTC come TEXT.
const schemaStatements = [
  '''
CREATE TABLE IF NOT EXISTS companies (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  name          TEXT NOT NULL,
  email         TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  created_at    TEXT NOT NULL
)''',
  '''
CREATE TABLE IF NOT EXISTS sessions (
  token      TEXT PRIMARY KEY,
  company_id INTEGER NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  created_at TEXT NOT NULL
)''',
  '''
CREATE TABLE IF NOT EXISTS jobs (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  company_id  INTEGER NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  description TEXT NOT NULL,
  location    TEXT,
  created_at  TEXT NOT NULL
)''',
  '''
CREATE TABLE IF NOT EXISTS applications (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  job_id           INTEGER NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  first_name       TEXT NOT NULL,
  last_name        TEXT NOT NULL,
  email            TEXT NOT NULL,
  cv_file_name     TEXT NOT NULL UNIQUE,
  cv_original_name TEXT NOT NULL,
  cv_size          INTEGER NOT NULL,
  created_at       TEXT NOT NULL
)''',
  'CREATE INDEX IF NOT EXISTS idx_jobs_created ON jobs (created_at DESC, id DESC)',
  'CREATE INDEX IF NOT EXISTS idx_jobs_company ON jobs (company_id)',
  'CREATE INDEX IF NOT EXISTS idx_applications_job '
      'ON applications (job_id, created_at DESC, id DESC)',
  'CREATE INDEX IF NOT EXISTS idx_sessions_company ON sessions (company_id)',
];
