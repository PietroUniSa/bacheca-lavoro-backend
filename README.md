# Bacheca Lavoro — back-end

API REST per la bacheca di annunci di lavoro (progetto universitario).
Dart 3 · shelf · SQLite · CV PDF salvati su filesystem.

## Requisiti
- Dart SDK ≥ 3.5 (incluso in Flutter)
- Libreria SQLite di sistema (macOS e la maggior parte delle distro Linux la
  includono; su Windows: `sqlite3.dll` nel PATH, vedi `docs/specs/05-architecture.md`)

## Avvio
```bash
dart pub get
dart run bin/server.dart --port 8080 --data-dir ./data
```
Il server ascolta su tutte le interfacce. Dal telefono, sulla stessa Wi-Fi:
`http://<IP-del-PC>:8080/health` deve rispondere `{"status":"ok"}`.

## Test
```bash
dart test
```
I test avviano il server reale su una porta libera e una cartella temporanea.

## API
Contratto completo in [`docs/specs/openapi.yaml`](docs/specs/openapi.yaml) e
[`docs/specs/04-api-contract.md`](docs/specs/04-api-contract.md).

| Metodo | Path | Auth |
|---|---|---|
| POST | `/api/auth/register` · `/api/auth/login` | – |
| POST | `/api/auth/logout` | Bearer |
| GET | `/api/jobs` · `/api/jobs/{id}` | – |
| POST | `/api/jobs` | Bearer |
| GET | `/api/companies/me/jobs` | Bearer |
| POST | `/api/jobs/{id}/applications` (multipart) | – |
| GET | `/api/jobs/{id}/applications` · `/api/applications/{id}` · `/api/applications/{id}/cv` | Bearer |

## Metodo di sviluppo
Spec-driven development: le specifiche in `docs/specs/` sono la fonte di verità,
i test di accettazione sono stati scritti prima del codice e citano gli ID dei
criteri (`AC-*`). Front-end: repository `bacheca-app`.
