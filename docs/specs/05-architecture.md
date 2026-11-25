# 05 — Architettura e decisioni (ADR)

```
 Smartphone (Flutter app)  ──HTTP/JSON + multipart──▶  PC locale (Dart shelf :8080)
   API_BASE_URL via --dart-define                       ├── data/bacheca.db (SQLite)
                                                        └── data/uploads/*.pdf
```
Telefono e PC sulla **stessa rete Wi-Fi**; il server ascolta su `0.0.0.0:8080`.

## Backend (`backend/`, repo `bacheca-backend`)
```
bin/server.dart              # legge --port, --data-dir; chiama startServer
lib/bacheca_backend.dart     # export di startServer e ServerConfig
lib/src/server.dart          # startServer(ServerConfig) → Future<RunningServer>
lib/src/config.dart          # ServerConfig {dataDir, host, port, pbkdf2Iterations}
lib/src/db/schema.dart       # CREATE TABLE IF NOT EXISTS …
lib/src/db/database.dart     # apertura DB, PRAGMA, migrazione
lib/src/repos/*.dart         # company, session, job, application (solo SQL)
lib/src/services/password_hasher.dart   # PBKDF2 (package cryptography)
lib/src/services/cv_storage.dart        # salva/legge/cancella PDF in uploads/
lib/src/http/api_error.dart  # ApiError(status, code, message, fields) → Response
lib/src/http/middleware.dart # errori → JSON, auth Bearer → request.context['companyId']
lib/src/validation/*.dart    # validatori puri (testabili senza HTTP)
lib/src/routes/*.dart        # auth_routes, job_routes, application_routes
test/support/harness.dart    # avvia il server su porta 0 e dataDir temporanea
```
**Firma obbligatoria** (usata dai test, non cambiarla senza aggiornare la spec):
```dart
class ServerConfig {
  const ServerConfig({required this.dataDir, this.host = '0.0.0.0',
      this.port = 8080, this.pbkdf2Iterations = 100000});
}
abstract class RunningServer {
  int get port;                 // porta effettiva (0 in config = porta libera)
  Future<void> close();         // chiude HTTP e database (serve su Windows)
}
Future<RunningServer> startServer(ServerConfig config);
```
Dipendenze: `shelf`, `shelf_router`, `shelf_multipart`, `sqlite3`, `cryptography`, `args`;
dev: `test`, `http`, `lints`. Aggiungerle con `dart pub add` (versioni correnti).

## App (`app/`, repo `bacheca-app`)
```
lib/main.dart                 # runApp(BachecaApp(deps: AppDeps.production())) (T14)
lib/app.dart                  # MaterialApp.router, tema (T09)
lib/config.dart               # apiBaseUrl = String.fromEnvironment('API_BASE_URL')
lib/deps.dart                 # AppDeps: ApiClient, TokenStore, CvPicker, CvOpener
lib/router.dart               # go_router + redirect di protezione area /company
lib/core/api_client.dart      # http + header Bearer + mappatura errori
lib/core/api_exception.dart   # ApiException(code, message, fields)
lib/core/token_store.dart     # shared_preferences
lib/data/models.dart          # Company, Job, MyJob, JobApplication (fromJson)
lib/data/*_api.dart           # auth_api, jobs_api, applications_api
lib/state/session.dart        # ChangeNotifier: company?, token?, login/logout/restore
lib/services/cv_picker.dart   # interfaccia + FilePickerCvPicker
lib/services/cv_opener.dart   # interfaccia + TempFileCvOpener (open_filex)
lib/ui/public/*.dart          # board_page, job_detail_page, apply_page
lib/ui/company/*.dart         # login, register, dashboard, new_job,
                              # job_applications, application_detail
integration_test/*.dart       # S1, S2, S3 end-to-end contro un backend vero
```
**Firme obbligatorie** (usate dagli integration test, `lib/deps.dart` e `lib/services/`):
```dart
class PickedCv { const PickedCv({required this.name, required this.bytes}); }
abstract class CvPicker { Future<PickedCv?> pick(); }            // null = annullato
abstract class CvOpener { Future<void> open(List<int> bytes, String fileName); }
abstract class TokenStore { Future<String?> read(); Future<void> write(String t);
                            Future<void> clear(); }
class InMemoryTokenStore implements TokenStore { InMemoryTokenStore([String? t]); }
class AppDeps { AppDeps({required String apiBaseUrl, required TokenStore tokenStore,
    required CvPicker cvPicker, required CvOpener cvOpener,
    http.Client? httpClient}); }                                  // httpClient: seam MockClient
}
class BachecaApp extends StatefulWidget { const BachecaApp({super.key, required this.deps}); }
```
`AppDeps.production()` viene completata in T14, quando sono disponibili tutti
gli adapter production (`TokenStore`, `CvPicker`, `CvOpener`); fino ad allora
T08 definisce solo i contratti e il costruttore iniettabile.
`BachecaApp` e `app.dart` vengono introdotti in T09 insieme al router.
Fino a T14, i test/widget avviano `BachecaApp` con `AppDeps` iniettate; il
wiring production in `main.dart` viene completato in T14.
Dipendenze: `http`, `go_router`, `provider`, `shared_preferences`, `file_picker`,
`path_provider`, `open_filex`, `intl`; dev: `integration_test`, `flutter_test`, `flutter_lints`.

Implementazioni reali dei seams:
- `FilePickerCvPicker`: `pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], withData: true)`;
  se `bytes` è null legge `File(path)`. Nessun permesso di storage (Android usa SAF).
- `TempFileCvOpener`: scrive in `getTemporaryDirectory()` con il nome ripulito
  (`[A-Za-z0-9._-]`, altri → `_`), poi `OpenFilex.open`; se `type != ResultType.done`
  lancia un errore che la pagina mostra come «Nessuna app per aprire il PDF».

### Rotte
| Path | Pagina | Protetta |
|---|---|---|
| `/` | Bacheca pubblica | no |
| `/jobs/:id` | Dettaglio annuncio | no |
| `/jobs/:id/apply` | Form candidatura | no |
| `/company/login`, `/company/register` | Login, registrazione | no |
| `/company` | I miei annunci (area riservata) | sì |
| `/company/jobs/new` (dichiarata **prima** di `:id`) | Nuovo annuncio | sì |
| `/company/jobs/:id` | Candidature dell'annuncio | sì |
| `/company/applications/:id` | Dettaglio candidatura | sì |

Redirect: rotta protetta senza sessione → `/company/login`. Login riuscito → `context.go('/company')`.
Logout → `context.go('/')` (sostituisce lo stack: "indietro" non riporta nell'area riservata).
Tutta la navigazione in avanti usa `context.push` (vedi `06`); solo login e logout usano `go`.

## ADR (decisioni)
| # | Decisione | Motivo | Alternativa scartata |
|---|---|---|---|
| A1 | Backend in Dart/shelf | stesso linguaggio dell'app, consigliato dalla consegna | Node/Express |
| A2 | SQLite su file | persistente, zero installazioni, SQL testabile | JSON su file (no vincoli FK) |
| A3 | Token opaco in tabella `sessions` | logout = DELETE, invalidazione certa (AC-R3-01) | JWT (logout non revoca) |
| A4 | PBKDF2 con iterazioni configurabili | sicuro in produzione, veloce nei test (1000) | SHA-256 semplice |
| A5 | CV su filesystem, metadati in DB | DB leggero, file serviti in streaming | BLOB nel DB |
| A6 | Seams `CvPicker`/`CvOpener` | gli integration test non possono pilotare i dialog nativi | test solo manuali |
| A7 | Token in `shared_preferences` | semplice, cross-platform; dato non critico per un MVP | flutter_secure_storage |
| A8 | Nessuna scadenza sessione | fuori scope MVP; documentato | scadenza 24h |

## Rete e piattaforme (da sapere prima dei video)
- Android: in `android/app/src/main/AndroidManifest.xml` (**non solo** in `debug/` e
  `profile/`, altrimenti la build `--release` non va in rete)
  `<uses-permission android:name="android.permission.INTERNET"/>` e
  `android:usesCleartextTraffic="true"` su `<application>` (HTTP in LAN).
- I video si registrano su **Android**; iOS è best-effort.
- iOS: in `Info.plist` `NSAppTransportSecurity → NSAllowsLocalNetworking = YES` e
  `NSLocalNetworkUsageDescription`. **Installare su iPhone richiede un Mac con Xcode.**
- `sqlite3` ≥ 3.x include la libreria nativa (build hook: al primo `dart run`/`dart test`
  la scarica da GitHub, serve internet una volta). Nessuna `sqlite3.dll` da installare.
- Firewall del PC: rete Wi-Fi impostata come *Privata* e regola in ingresso
  `netsh advfirewall firewall add rule name="bacheca 8080" dir=in action=allow protocol=TCP localport=8080 profile=private`.
- Alternativa senza Wi-Fi (USB, IP stabile): `adb reverse tcp:8080 tcp:8080` e
  `--dart-define=API_BASE_URL=http://127.0.0.1:8080`.
