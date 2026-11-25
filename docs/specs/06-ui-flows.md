# 06 — Schermate, flussi e contratto delle Key

Le `Key` dei widget sono **contratto**: gli integration test le usano. Si possono
aggiungere, non rinominare senza aggiornare questa tabella e i test.
Testi in italiano. Ogni schermata gestisce 4 stati: caricamento, dati, vuoto, errore.
Le Key `job_detail_*`, `application_*` e `apply_cv_name` stanno su un `Text` che contiene
**solo** il valore (niente etichette tipo "Email: …"), oppure su un `KeyedSubtree` il cui unico
figlio è quel `Text`: i test confrontano il testo esatto, anche con `find.descendant`.

**Navigazione**: in avanti sempre `context.push` (annuncio → `/jobs/:id`, Candidati →
`/jobs/:id/apply`, Area aziende → `/company`, riga di I miei annunci → `/company/jobs/:id`,
riga candidatura → `/company/applications/:id`). Solo login e logout usano `context.go`.

**Errori**: Text con Key `<schermata>_error` + `retry_button` ("Riprova") dove si carica:
`board_error`, `job_detail_error`, `my_jobs_error`, `applications_error`,
`application_error`; nei form: `login_error`, `register_error`, `job_publish_error`, `apply_error`.

## Mappa dei flussi
```
[Bacheca /] ──tap annuncio──▶ [Dettaglio] ──Candidati──▶ [Form candidatura] ──Invia──▶ conferma
     │
     └──"Area aziende"──▶ [Login] ◀──conferma── [Registrazione]
                              │ Accedi
                              ▼
                       [I miei annunci] ──Nuovo annuncio──▶ [Nuovo annuncio] ──Pubblica──▶ ritorno
                              │ tap annuncio
                              ▼
                       [Candidature] ──tap──▶ [Dettaglio candidatura] ──Apri curriculum──▶ PDF
                              │
                         "Esci" (AppBar di I miei annunci) ──▶ [Bacheca /] (stack azzerato)
```

## Schermate e Key

### Bacheca pubblica `/` (AC-R5-01, AC-R5-03)
| Key | Widget | Note |
|---|---|---|
| `board_list` | ListView | una card per annuncio: titolo, azienda, data |
| `board_empty` | Text | "Nessun annuncio pubblicato" |
| `company_area_button` | IconButton/TextButton in AppBar | "Area aziende" → `push('/company')`; senza sessione il redirect porta al login |
| `board_refresh` | RefreshIndicator | pull-to-refresh |

### Dettaglio annuncio `/jobs/:id` (AC-R5-02)
`job_detail_title`, `job_detail_company`, `job_detail_date`, `job_detail_description`,
`apply_button` ("Candidati").

### Form candidatura `/jobs/:id/apply` (AC-R6-01..05)
| Key | Widget |
|---|---|
| `apply_first_name`, `apply_last_name`, `apply_email` | TextFormField |
| `apply_pick_cv` | OutlinedButton "Allega curriculum (PDF)" |
| `apply_cv_name` | Text col nome del file scelto |
| `apply_submit` | FilledButton "Invia candidatura" (disabilitato durante l'invio) |
| `apply_success` | schermata/Text "Candidatura inviata!" + bottone "Torna alla bacheca" |

Validazione client identica a `03-domain-model.md` (il server rivalida comunque).

### Login `/company/login` (AC-R2-01..03)
`login_email`, `login_password`, `login_submit` ("Accedi"), `login_go_register` ("Registrati"),
`login_error` (Text sotto al form). Riceve l'email precompilata via `extra` o query `?email=`.

### Registrazione `/company/register` (AC-R1-01..05)
`register_name`, `register_email`, `register_password`, `register_submit` ("Crea account"),
`register_error` (es. "Email già registrata").
Successo → SnackBar "Account creato" + `context.go('/company/login?email=…')`.

### I miei annunci `/company` — area riservata (AC-R2-03, AC-R7-01)
`dashboard_title` ("I miei annunci"), `new_job_button` (FAB "Nuovo annuncio"),
`my_jobs_list`, `my_jobs_empty`, `dashboard_board_button` ("Bacheca pubblica" in AppBar,
`context.push('/')`: la sessione resta attiva), `logout_button` ("Esci" in AppBar).
Ogni riga: titolo + "N candidature".

### Nuovo annuncio `/company/jobs/new` (AC-R4-01..04)
`job_title_field`, `job_description_field` (multilinea), `job_location_field`,
`job_publish` ("Pubblica"). Successo → `pop(true)` e ricarica di I miei annunci.

### Candidature `/company/jobs/:id` (AC-R7-02)
`applications_list`, `applications_empty` ("Ancora nessuna candidatura").
Riga: "Nome Cognome" in un unico `Text`, email, data.

### Dettaglio candidatura `/company/applications/:id` (AC-R7-03..05)
`application_name`, `application_email`, `application_date`, `application_cv_name`,
`open_cv_button` ("Apri curriculum") → `CvOpener.open(bytes, cvOriginalName)`; se fallisce
SnackBar «Nessuna app per aprire il PDF».

## Dati di demo consigliati (uguali in test e video)
- Azienda: "Acme Srl" · `hr@acme.it` · `Password123`
- Annuncio: "Sviluppatore Flutter Junior" · "Cerchiamo uno sviluppatore Flutter
  junior per app mobile in un team agile. Sede a Napoli, ibrido." · "Napoli"
- Candidato: Mario Rossi · `mario.rossi@example.com` · `cv_mario_rossi.pdf`
