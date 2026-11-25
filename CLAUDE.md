# CLAUDE.md — backend (repo `bacheca-backend`)

Server HTTP in Dart (shelf) con SQLite e CV su filesystem.
Le regole generali sono in `../CLAUDE.md` e `../specs/00-constitution.md`
(nel repo pubblicato: `docs/specs/`).

## Contratti da rispettare
- Endpoint, codici di stato, schemi: `specs/04-api-contract.md` + `specs/openapi.yaml`.
- Firma obbligatoria `ServerConfig` / `RunningServer` / `startServer`:
  `specs/05-architecture.md`. I test la usano: non cambiarla.
- Formato errori unico: `{"error":{"code","message","fields?"}}` tramite `ApiError`.

## Struttura e responsabilità
- `routes/` traduce HTTP ↔ dominio; nessun SQL qui.
- `repos/` contiene solo SQL parametrizzato (`?`), mai concatenazioni di stringhe.
- `validation/` funzioni pure che ritornano `Map<String, String>` di errori per campo.
- `services/` hashing password e storage CV.
- Proprietà delle risorse (403) verificata nelle route, con un helper unico.

## Test
- I test in `test/` sono di **accettazione** e parlano HTTP con il server vero
  (`test/support/harness.dart`). Sono stati scritti prima del codice: se uno
  sembra sbagliato, segnalalo, non modificarlo per farlo passare.
- Puoi aggiungere test unitari (es. `test/unit/validators_test.dart`).
- Esegui un file: `dart test test/auth_test.dart` · tutti: `dart test`.
- Fino a T07 i test dei task futuri sono rossi per costruzione: conta il file del task.

## Avvio
```bash
dart run bin/server.dart --port 8080 --data-dir ./data
```
Ascolta su `0.0.0.0`: raggiungibile dal telefono via `http://<IP-del-PC>:8080`.
Log di una riga per richiesta (metodo, path, status, ms) su stdout.
