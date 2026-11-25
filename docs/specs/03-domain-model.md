# 03 — Modello di dominio e validazione

## Entità

```
Company 1 ──── * JobPost 1 ──── * Application ── 1 CV (file PDF)
Company 1 ──── * Session
```

### Company
| Campo | Tipo | Regole |
|---|---|---|
| id | int (PK autoincrement) | generato |
| name | string | 2–100 caratteri dopo trim |
| email | string | formato email; univoca; trim + minuscolo in registrazione **e** login |
| passwordHash | string | PBKDF2-HMAC-SHA256, 100 000 iterazioni, salt 16 byte; **mai esposto** |
| createdAt | ISO-8601 UTC | generato |

Password in ingresso: 8–128 caratteri.

### Session
| Campo | Tipo | Regole |
|---|---|---|
| token | string (PK) | 32 byte casuali (`Random.secure`) in base64url |
| companyId | int (FK) | |
| createdAt | ISO-8601 UTC | |

Il logout cancella la riga. Nessuna scadenza nell'MVP (scelta documentata in `05-architecture.md`).

### JobPost
| Campo | Tipo | Regole |
|---|---|---|
| id | int (PK) | generato |
| companyId | int (FK) | dal token, **mai** dal body |
| title | string | 3–120 caratteri dopo trim |
| description | string | 10–5000 caratteri dopo trim |
| location | string? | opzionale, max 100 |
| createdAt | ISO-8601 UTC | generato; ordinamento bacheca DESC |

### Application
| Campo | Tipo | Regole |
|---|---|---|
| id | int (PK) | generato |
| jobId | int (FK) | dal path |
| firstName | string | 1–60 dopo trim |
| lastName | string | 1–60 dopo trim |
| email | string | formato email |
| cvFileName | string | generato dal server: `<32 hex casuali>.pdf` |
| cvOriginalName | string | nome dato dal client, max 255, solo per visualizzazione |
| cvSize | int | byte, 1–5 242 880 |
| createdAt | ISO-8601 UTC | generato |

## Validazione email
Regex unica, condivisa da backend e app (copiata, non importata):
`^[^\s@]+@[^\s@]+\.[^\s@]{2,}$`

## Messaggi utente (italiano) per codice errore
| Codice | Messaggio mostrato dall'app |
|---|---|
| VALIDATION_ERROR | messaggio del campo sotto all'input |
| EMAIL_TAKEN | Email già registrata |
| INVALID_CREDENTIALS | Credenziali non valide |
| UNAUTHORIZED | Sessione non valida, accedi di nuovo |
| FORBIDDEN | Non hai accesso a questa risorsa |
| NOT_FOUND | Annuncio non trovato (E6, E9); altrove: Risorsa non trovata |
| INVALID_FILE | Il curriculum deve essere un PDF (max 5 MB) |
| (rete) | Server non raggiungibile. Controlla la connessione. |

## Persistenza
- Database: `<dataDir>/bacheca.db` (SQLite, `PRAGMA foreign_keys = ON`).
- CV: `<dataDir>/uploads/<32 hex casuali>.pdf`.
- `dataDir` di default `./data`, configurabile con `--data-dir` o env `DATA_DIR`.
- Schema creato all'avvio con `CREATE TABLE IF NOT EXISTS` (vedi `backend/lib/src/db/schema.dart`).
