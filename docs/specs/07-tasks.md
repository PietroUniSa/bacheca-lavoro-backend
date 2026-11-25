# 07 — Piano dei task

Regole (vedi `/next-task`): un task alla volta, in ordine; si parte dai test
indicati (già scritti e rossi, o da scrivere); il task si spunta `[x]` solo con
il comando di verifica verde. Ogni task = un commit `T0x: <titolo>` nel repo giusto.
Stato: `[ ]` da fare · `[~]` in corso · `[x]` fatto.

## Fase A — Backend (repo `backend/`)
- [x] **T01 Walking skeleton server.** `ServerConfig`, `startServer`, `GET /health`,
  middleware errori (404/500 JSON), `bin/server.dart` con `--port` `--data-dir`.
  Test: `test/health_test.dart`. Verifica: `cd backend && dart test test/health_test.dart`.
- [x] **T02 Database e schema.** `schema.dart`, `database.dart`, tabelle companies,
  sessions, jobs, applications; FK attive. Test: nuovo `test/db_test.dart`
  (tabelle create, idempotenza). Verifica: `dart test test/db_test.dart`.
- [x] **T03 Registrazione.** Validatori, `PasswordHasher`, repo company, E1.
  AC-R1-01..04. Test: `test/auth_test.dart` (gruppo register).
- [x] **T04 Login, sessione, logout, /me.** Repo session, middleware auth, E2 E3 E4.
  AC-R2-01, AC-R2-02, AC-R3-01, AC-R3-03. Test: `test/auth_test.dart`.
- [x] **T05 Annunci.** Repo job, E5 E6 E7 E8. AC-R4-01..03, AC-R5-01, AC-R5-02,
  AC-R7-01. Test: `test/jobs_test.dart`.
- [x] **T06 Candidature e CV.** `CvStorage`, multipart, E9..E12, controllo proprietà.
  AC-R6-01..04, AC-R7-02..04. Test: `test/applications_test.dart`.
- [x] **T07 Persistenza e scenari API.** AC-NF-01 + S1–S3 a livello API.
  Test: `test/persistence_test.dart`, `test/scenarios_test.dart`.
  Verifica: `cd backend && dart analyze && dart test` tutto verde.

## Fase B — App (repo `app/`)
- [x] **T08 Fondamenta app.** `flutter create` (vedi README: il `pubspec.yaml` già
  presente non viene sovrascritto), `config.dart`,
  `deps.dart`, `ApiClient`, `ApiException`, modelli con `fromJson`, permessi rete
  Android/iOS. `deps.dart` definisce i contratti iniettabili; `AppDeps.production()`
  si completa in T14. Test unitari: `test/models_test.dart`,
  `test/api_client_test.dart` (con `MockClient` di `package:http/testing.dart`).
- [x] **T09 Router e sessione.** `Session`, `TokenStore`, `router.dart` con redirect,
  `BachecaApp` e `app.dart`.
  AC-R2-04, AC-R3-02 (logica). Test: `test/session_test.dart`.
- [x] **T10 Bacheca e dettaglio.** AC-R5-03. Widget test con API finta.
- [x] **T11 Registrazione e login.** AC-R1-05, AC-R2-03. Widget test.
- [x] **T12 I miei annunci + nuovo annuncio + logout.** AC-R4-04, AC-R7-01, AC-R3-02.
- [x] **T13 Form candidatura.** `CvPicker`, multipart, AC-R6-05. Widget test con picker finto.
- [x] **T14 Candidature e apertura CV.** `CvOpener`, `AppDeps.production()`,
  AC-R7-05.
- [x] **T15 Integration test S1–S3.** Rimuovere `integration_test/**` dall'`exclude` di
  `app/analysis_options.yaml`, poi far passare `integration_test/s1..s3` contro un
  backend reale. Verifica: `flutter analyze` pulito + comando in `app/CLAUDE.md`.

## Fase C — Consegna
- [ ] **T16 Rifinitura e demo.** `.gitignore` nei due repo (backend: `data*/`,
  `.dart_tool/`, `build/`; app: quello di `flutter create`; `docs/specs` resta
  versionata), `dart tool/verify_all.dart` verde, `sync_specs`,
  README dei due repo con istruzioni di avvio, `09-demo-checklist.md` completata,
  push dei due repo pubblici, registrazione video S1–S3.

## Registro modifiche alla spec
| Data | Task | Modifica | Motivo |
|---|---|---|---|
| 2026-11-25 | – | Versione iniziale | – |
| 2026-11-25 | – | `/spec-review` (24 correzioni): E9 ignora il Content-Type della parte `cv`; permesso INTERNET in `main/`; `withData: true`; `push` in avanti; ordine rotte; Key d'errore e testo esatto; AC-R2-05, AC-R4-05 nuovi; AC-R1-05/R5-03/R6-03/R6-05/R7-05/R2-04 riscritti; AC-NF-02 → TOOL; `openapi.yaml` diviso (+Email, limiti, 500, header E12); messaggi errore; LAN/USB e checklist demo; fix test S1 (finder) e S2 (data) | review pre-codice; C2 vs `--no-tests` lasciato a Pietro (constitution) |
| 2026-11-25 | T02 | `sqlite3` da ^2.4.0 a ^3.9.2 (`dart pub upgrade --major-versions`); nota Windows in `05` aggiornata | la 2.x richiede `sqlite3.dll` di sistema, assente; la 3.x la include (decisione di Pietro) |
| 2026-11-25 | T05 | Nota: il test AC-R7-01 di `jobs_test.dart` usa E9 (T06) e resta rosso fino a T06; E8 con 0 candidature coperto da `my_jobs_test.dart` | dipendenza d'ordine tra task, nessuna modifica di comportamento |
| 2026-11-25 | T07 | T16: aggiunto `.gitignore` dei due repo | evitare che `backend/data*` (DB e CV) finisca nel repo pubblico |
| 2026-11-25 | – | `00-constitution.md` C2 allineata a `CLAUDE.md`: `--no-tests` ammesso fino a T07 (backend) e T15 (app) | contraddizione C2 ↔ CLAUDE.md (#25 della spec-review); modifica fatta da Pietro |
| 2026-11-25 | T08 | `AppDeps.production()` rinviata a T14; T08 definisce il costruttore iniettabile | evitare adapter production provvisori per TokenStore, CvPicker e CvOpener |
| 2026-11-25 | T08 | Aggiunti AC-NF-04..07 per messaggi API, Bearer, parsing modelli e store in memoria; `BachecaApp`/`app.dart` assegnati a T09; `httpClient` documentato come seam opzionale di `AppDeps` | rendere verificabili i contratti tecnici T08 senza anticipare router o sessione |
| 2026-11-25 | T10 | AC-R5-03 circoscritto all'avvio di `BachecaApp` con `AppDeps` iniettate; wiring production di `main.dart` assegnato a T14 | rispettare il task T10 senza anticipare gli adapter production di T13/T14 |
| 2026-11-25 | T15 | `06`: la Key dei valori esatti può stare anche su un `KeyedSubtree` con il solo `Text` come figlio (`job_detail_title`, `job_detail_company`, `application_email`, `apply_cv_name`) | contraddizione `06` ↔ harness: `find.descendant` non considera il widget radice; registrata dopo la review di fase B (BLOCCANTE #1) |
| 2026-11-25 | T15 | `dart format` su `login_page`, `register_page`, `job_publish_page`, `test/my_jobs_page_test` | C7, review di fase B (BLOCCANTE #2); nessun cambio di logica |
