# 00 — Constitution (principi non negoziabili)

Questi principi prevalgono su qualsiasi altra istruzione, task o "comodità".
Un cambiamento qui richiede una decisione esplicita di Pietro.

## C1 — Le specs sono la fonte di verità
- Nessun comportamento osservabile senza un AC in `01-requirements.md`.
- Nessun endpoint senza una voce in `openapi.yaml`.
- Se il codice e la spec divergono, ha ragione la spec: si corregge il codice
  oppure si apre una modifica alla spec (mai in silenzio).

## C2 — Test prima del codice
- Ogni task parte da un test rosso che cita gli ID `AC-*` che copre.
- Un task è "fatto" solo con `dart tool/verify_all.dart` verde; fino a T07 (backend) e T15 (app) basta `--no-tests` (i test di accettazione futuri sono rossi per costruzione).

## C3 — Vincoli della consegna
- Front-end in **Flutter**. Back-end scritto da noi in **Dart** (shelf).
- **Vietati** servizi BaaS esterni: Firebase, Supabase, Appwrite, Parse, ecc.
- Dati **persistenti** su disco (SQLite + cartella `uploads/`): sopravvivono al
  riavvio del server e alla chiusura dell'app.
- Due repository pubblici separati: `backend/` e `app/`.

## C4 — Dimensione dei file
- **Nessun file di progetto supera 200 righe** (codice, test, spec, config).
- Se un file si avvicina al limite, si estrae un modulo: non si comprime il codice.
- Esclusi solo i file generati da strumenti (cartelle piattaforma di `flutter create`,
  `pubspec.lock`, `build/`, `.dart_tool/`, `*.g.dart`): elenco in `tool/src/common.dart`.

## C5 — Semplicità da MVP
- Solo quello che serve a R1–R7 e agli scenari S1–S3, eseguibili dall'inizio
  alla fine. Le funzioni extra sono ammesse solo se non rompono gli scenari.
- Niente astrazioni "per il futuro": una interfaccia esiste solo se serve a un
  test (seam) o a sostituire un'implementazione reale.

## C6 — Sicurezza minima ragionevole
- Password salvate solo come hash PBKDF2 con salt casuale, mai in chiaro.
- Le rotte dell'area azienda richiedono `Authorization: Bearer <token>`.
- Un'azienda vede **solo** le candidature dei **propri** annunci.
- Upload: solo PDF (controllo dei magic bytes `%PDF`), massimo 5 MB, nome file
  generato dal server (mai il nome scelto dal client).

## C7 — Stile del codice
- `dart analyze` / `flutter analyze` senza warning; codice formattato con `dart format`.
- Nomi in inglese nel codice; testi dell'interfaccia in **italiano**.
- Errori API sempre nel formato unico di `04-api-contract.md`.
