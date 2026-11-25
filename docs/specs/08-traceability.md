# 08 — Matrice di tracciabilità

Verificata automaticamente da `dart tool/check_traceability.dart`, che cerca ogni
`AC-*` di `01-requirements.md` nei file di test (`backend/test`, `app/test`,
`app/integration_test`, `tool`). Questa tabella è la vista umana: aggiornala
quando aggiungi test o schermate (i widget test T10–T14 vanno in `app/test/`).

| Req | AC | Endpoint | Test API | Schermata | Test UI | Scenario |
|---|---|---|---|---|---|---|
| R1 | AC-R1-01..04 | E1 | `auth_test.dart`, `unit/validators_test.dart`, `unit/password_hasher_test.dart` | Registrazione | – | S1 |
| R1 | AC-R1-05 | – | – | Registrazione → Login | `app/test/register_page_test.dart`, `s1_publish_job_test.dart` | S1 |
| R2 | AC-R2-01, 02 | E2 | `auth_test.dart`, `unit/password_hasher_test.dart` | Login | – | S1 |
| R2 | AC-R2-03 | – | – | I miei annunci | `app/test/login_page_test.dart`, `s1_publish_job_test.dart` | S1 |
| R2 | AC-R2-04 | E4 | `persistence_test.dart` | avvio app | `session_test.dart` (T09), `s3_…` | – |
| R2 | AC-R2-05 | E2 | `auth_test.dart` | – | – | – |
| R3 | AC-R3-01, 03 | E3, E4 | `auth_test.dart` | – | – | S3 |
| R3 | AC-R3-02 | – | – | I miei annunci → Bacheca | `s3_review_and_logout_test.dart`, `app/test/session_test.dart`, `app/test/company_logout_test.dart` | S3 |
| R4 | AC-R4-01..03 | E7 | `jobs_test.dart`, `unit/job_validator_test.dart` | Nuovo annuncio | – | S1 |
| R4 | AC-R4-04 | E5, E8 | – | I miei annunci, Bacheca | `s1_publish_job_test.dart`, `app/test/my_jobs_page_test.dart` | S1 |
| R4 | AC-R4-05 | E7 | `jobs_test.dart`, `unit/job_validator_test.dart` | – | – | – |
| R5 | AC-R5-01, 02 | E5, E6 | `jobs_test.dart`, `my_jobs_test.dart` | Bacheca, Dettaglio | `app/test/board_page_test.dart` | S2 |
| R5 | AC-R5-03 | – | – | Bacheca, Dettaglio | `s2_apply_test.dart`, `app/test/board_page_test.dart` | S2 |
| R6 | AC-R6-01..04 | E9 | `applications_test.dart`, `cv_download_test.dart`, `unit/application_validator_test.dart` | – | – | S2 |
| R6 | AC-R6-05 | – | – | Form candidatura | `s2_apply_test.dart`, `app/test/apply_page_test.dart` | S2 |
| R7 | AC-R7-01 | E8 | `jobs_test.dart`, `my_jobs_test.dart` | I miei annunci | `app/test/my_jobs_page_test.dart` | – |
| R7 | AC-R7-02..04 | E10–E12 | `applications_test.dart`, `cv_download_test.dart` | – | – | S3 |
| R7 | AC-R7-05 | E12 | – | Dettaglio candidatura | `s3_review_and_logout_test.dart`, `app/test/application_detail_page_test.dart` | S3 |
| NF | AC-NF-01 | tutti | `persistence_test.dart`, `db_test.dart` (base, T02) | – | – | – |
| NF | AC-NF-02 | – | – | – | `tool/check_no_hardcoded_url.dart` | – |
| NF | AC-NF-03 | – | – | – | `tool/check_line_limit.dart` | – |
| NF | AC-NF-04 | – | – | – | `app/test/api_client_test.dart` | – |
| NF | AC-NF-05 | – | – | – | `app/test/api_client_test.dart` | – |
| NF | AC-NF-06 | – | – | – | `app/test/models_test.dart` | – |
| NF | AC-NF-07 | – | – | – | `app/test/token_store_test.dart` | – |
