# 09 — Checklist per i video S1–S3

## Prima di registrare
- [ ] `dart tool/verify_all.dart` verde.
- [ ] PC e telefono sulla stessa Wi-Fi (rete *Privata*); IP del PC annotato (es. `192.168.1.50`).
      Se l'IP cambia o la Wi-Fi è inaffidabile: USB + `adb reverse tcp:8080 tcp:8080`
      e `API_BASE_URL=http://127.0.0.1:8080` (vedi `05`).
- [ ] Server avviato su una **cartella dati pulita**:
      `cd backend && dart run bin/server.dart --port 8080 --data-dir ./data-demo`
- [ ] Dal browser del telefono `http://<IP>:8080/health` risponde `{"status":"ok"}`.
- [ ] `dart tool/e2e_smoke.dart http://<IP>:8080` verde (poi riavvia su cartella
      pulita: lo smoke crea dati di prova).
- [ ] App installata in release o profile:
      `flutter run --release --dart-define=API_BASE_URL=http://<IP>:8080`
- [ ] Sul telefono è presente `cv_mario_rossi.pdf` (< 5 MB, cartella Download / File).
- [ ] Un PDF si apre dall'app File del telefono (esiste un visualizzatore PDF).
- [ ] Notifiche silenziate, luminosità alta, registrazione schermo attiva.

## Ordine di registrazione (i dati si concatenano)
1. **S1** con dati puliti: registrazione Acme → login → nuovo annuncio → si vede in
   "I miei annunci" → tocca "Bacheca pubblica" nell'AppBar → l'annuncio è in bacheca.
   A registrazione ferma: indietro → "Esci" (S2 deve partire senza sessione).
2. **S2** partendo dall'app aperta sulla bacheca senza login: annuncio → dettaglio
   → Candidati → dati di Mario Rossi → allega PDF → Invia → "Candidatura inviata!".
3. **S3**: login Acme (punto di partenza "azienda autenticata": il login può
   avvenire prima dell'inizio del video) → I miei annunci → annuncio → candidatura
   → dati → Apri curriculum → indietro fino a I miei annunci → Esci → bacheca → tasto indietro non
   riporta nell'area riservata.

## Dopo
- [ ] Persistenza: chiudi l'app e riavvia il server; i dati sono ancora lì.
- [ ] `dart tool/sync_specs.dart`, commit e push dei due repo.
- [ ] Verifica che entrambi i repo siano **pubblici** e che i README spieghino l'avvio.
