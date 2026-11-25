# 02 — Scenari (Gherkin)

Sono gli scenari della consegna, resi eseguibili. Ogni passo cita gli AC.
Sono implementati due volte:
- a livello API: `backend/test/scenarios_test.dart`
- a livello app: `app/integration_test/s1_…`, `s2_…`, `s3_…`
I video si registrano seguendo **esattamente** questi passi (`09-demo-checklist.md`).

## S1 — Pubblicare un annuncio (R1, R2, R4)
```gherkin
Scenario: un'azienda senza account pubblica il primo annuncio
  Given l'azienda non ha un account
  And l'app è aperta sulla bacheca pubblica
  When tocca "Area aziende" e poi "Registrati"
  And inserisce ragione sociale "Acme Srl", email "hr@acme.it", password "Password123"
  And conferma
  Then l'app mostra "Account creato" e apre il login con l'email precompilata  # AC-R1-01, AC-R1-05
  When inserisce la password e tocca "Accedi"
  Then l'app mostra l'area riservata "I miei annunci"                          # AC-R2-01, AC-R2-03
  When tocca "Nuovo annuncio"
  And inserisce titolo "Sviluppatore Flutter Junior" e una descrizione
  And tocca "Pubblica"
  Then l'annuncio compare in "I miei annunci"                                  # AC-R4-01, AC-R4-04
  When tocca "Bacheca pubblica"
  Then l'annuncio compare nella bacheca pubblica                               # AC-R4-04, AC-R5-01
```

## S2 — Candidarsi a un annuncio (R5, R6)
```gherkin
Scenario: un candidato anonimo invia la candidatura con CV
  Given esiste almeno un annuncio pubblicato
  And il candidato apre l'app senza autenticarsi
  Then l'app mostra l'elenco degli annunci                                     # AC-R5-01, AC-R5-03
  When tocca un annuncio
  Then l'app mostra titolo, azienda, data e descrizione                        # AC-R5-02, AC-R5-03
  When tocca "Candidati"
  And inserisce nome "Mario", cognome "Rossi", email "mario.rossi@example.com"
  And allega il file "cv_mario_rossi.pdf"
  And tocca "Invia candidatura"
  Then l'app mostra "Candidatura inviata!"                                     # AC-R6-01, AC-R6-05
```

## S3 — Consultare le candidature e uscire (R7, R3)
```gherkin
Scenario: l'azienda legge una candidatura, apre il CV ed esce
  Given l'azienda è autenticata
  And ha almeno un annuncio con almeno una candidatura
  When apre "I miei annunci" e tocca l'annuncio
  Then l'app mostra le candidature ricevute                                    # AC-R7-01, AC-R7-02
  When tocca la candidatura di "Mario Rossi"
  Then l'app mostra nome, cognome, email e data                                # AC-R7-03
  When tocca "Apri curriculum"
  Then il PDF del candidato viene visualizzato                                 # AC-R7-04, AC-R7-05
  When torna indietro fino a "I miei annunci" e tocca "Esci"
  Then l'app mostra la bacheca pubblica                                        # AC-R3-01, AC-R3-02
  And premendo "indietro" l'area riservata non è più raggiungibile             # AC-R3-02
```

## Scenari negativi minimi (non nei video, ma testati)
- Registrazione con email già usata → messaggio "Email già registrata" (AC-R1-02).
- Login con password errata → "Credenziali non valide" (AC-R2-02).
- Candidatura con file non PDF → "Il curriculum deve essere un PDF (max 5 MB)" (AC-R6-03).
- Azienda B prova a leggere candidature di A → 403 (AC-R7-02).
