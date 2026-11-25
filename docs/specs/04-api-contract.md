# 04 — Contratto API

Versione formale: `openapi.yaml` + `openapi-components.yaml` (vince in caso di dubbio). Base path: `/api`.
JSON UTF-8, chiavi in camelCase, date ISO-8601 UTC. Liste sempre come `{"items": [...]}`.

## Autenticazione
Header `Authorization: Bearer <token>` ottenuto dal login. 🔒 = rotta riservata.

## Formato errori (unico)
```json
{ "error": { "code": "VALIDATION_ERROR", "message": "Dati non validi",
             "fields": { "email": "Email non valida" } } }
```
`fields` presente solo con `VALIDATION_ERROR`. Codici: vedi `03-domain-model.md`.

## Endpoint

| # | Metodo e path | Auth | Successo | Errori | AC |
|---|---|---|---|---|---|
| E0 | `GET /health` | – | 200 `{"status":"ok"}` | – | – |
| E1 | `POST /api/auth/register` | – | 201 `Company` | 400, 409 | R1-01..04 |
| E2 | `POST /api/auth/login` | – | 200 `{token, company}` | 400, 401 | R2-01, R2-02, R2-05 |
| E3 | `POST /api/auth/logout` | 🔒 | 204 | 401 | R3-01 |
| E4 | `GET /api/me` | 🔒 | 200 `Company` | 401 | R2-04, R3-03 |
| E5 | `GET /api/jobs` | – | 200 `{items: Job[]}` | – | R5-01 |
| E6 | `GET /api/jobs/{id}` | – | 200 `Job` | 404 | R5-02 |
| E7 | `POST /api/jobs` | 🔒 | 201 `Job` | 400, 401 | R4-01..03, R4-05 |
| E8 | `GET /api/companies/me/jobs` | 🔒 | 200 `{items: MyJob[]}` | 401 | R7-01 |
| E9 | `POST /api/jobs/{id}/applications` | – | 201 `Application` | 400, 404 | R6-01..04 |
| E10 | `GET /api/jobs/{id}/applications` | 🔒 | 200 `{items: Application[]}` | 401, 403, 404 | R7-02 |
| E11 | `GET /api/applications/{id}` | 🔒 | 200 `Application` | 401, 403, 404 | R7-03 |
| E12 | `GET /api/applications/{id}/cv` | 🔒 | 200 `application/pdf` | 401, 403, 404 | R7-04 |

## Corpi

**E1 request** `{"name":"Acme Srl","email":"hr@acme.it","password":"Password123"}`
**E2 request** `{"email":"hr@acme.it","password":"Password123"}`
**E7 request** `{"title":"…","description":"…","location":"Napoli"}` (`location` opzionale)

**E9 request**: `multipart/form-data` con campi testo `firstName`, `lastName`,
`email` e parte file `cv` (filename originale). Il `Content-Type` della parte viene
**ignorato**: il file è PDF solo se i byte iniziano con `%PDF` (C6).
Il server valida prima i campi testo, poi il file; scrive il file su disco solo
se tutto è valido; se l'INSERT fallisce, cancella il file.

## Schemi
```
Company     { id:int, name:string, email:string, createdAt:string }
Job         { id:int, title:string, description:string, location:string|null,
              companyId:int, companyName:string, createdAt:string }
MyJob       = Job + { applicationCount:int }
Application { id:int, jobId:int, firstName:string, lastName:string, email:string,
              cvOriginalName:string, cvSize:int, createdAt:string }
```

## Regole trasversali
- Ordinamento: `GET /api/jobs` e liste candidature per `createdAt` DESC, poi `id` DESC.
- Proprietà: E10/E11/E12 → se la risorsa esiste ma appartiene a un'altra azienda: 403.
- E12: header `Content-Disposition: inline; filename="<nome>"; filename*=UTF-8''<urlencoded>`,
  dove `<nome>` è `cvOriginalName` ripulito (caratteri fuori da `[A-Za-z0-9._-]` → `_`).
- Body JSON malformato → 400 `VALIDATION_ERROR` con `message: "JSON non valido"`.
- Ogni rotta può rispondere 500 `INTERNAL_ERROR` (in `openapi.yaml`: `Error500`).
- Rotte inesistenti → 404 `NOT_FOUND`. Eccezioni non gestite → 500 `INTERNAL_ERROR`
  (log su stderr, mai stack trace nella risposta).
- CORS non necessario (client mobile), ma ammesso un middleware permissivo per test da browser.
