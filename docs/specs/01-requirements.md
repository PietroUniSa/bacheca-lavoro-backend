# 01 — Requisiti e criteri di accettazione

Formato **EARS** (*Easy Approach to Requirements Syntax*):
`Quando <evento>, il sistema deve <risposta>` · `Se <condizione indesiderata>, allora…`.
Ogni AC ha un ID stabile. **Gli ID non si rinumerano mai**: un AC eliminato
resta come `~~AC-…~~ (rimosso: motivo)`.
Colonna *Verifica*: `API` = test in `backend/test/`, `UI` = test in
`app/integration_test/` o `app/test/`, `TOOL` = script in `tool/`.

## Attori
- **Azienda**: registrata, autenticata, pubblica annunci, legge candidature.
- **Candidato**: anonimo, non fa login, consulta la bacheca e si candida.

## R1 — Registrazione (azienda)
| ID | Criterio | Verifica |
|---|---|---|
| AC-R1-01 | Quando un'azienda invia ragione sociale, email e password valide, il sistema deve creare l'account e rispondere 201 con i dati pubblici dell'azienda. | API |
| AC-R1-02 | Se l'email è già registrata (confronto case-insensitive), allora il sistema deve rispondere 409 `EMAIL_TAKEN`. | API |
| AC-R1-03 | Se un campo non è valido (vedi `03-domain-model.md`), allora il sistema deve rispondere 400 `VALIDATION_ERROR` indicando i campi. | API |
| AC-R1-04 | Il sistema non deve mai salvare né restituire la password in chiaro. | API |
| AC-R1-05 | Quando la registrazione riesce, l'app deve mostrare «Account creato» e aprire il login con l'email precompilata. | UI |

## R2 — Login (azienda)
| ID | Criterio | Verifica |
|---|---|---|
| AC-R2-01 | Quando l'azienda invia credenziali corrette, il sistema deve rispondere 200 con un token di sessione e i dati dell'azienda. | API |
| AC-R2-02 | Se email o password sono errate, allora il sistema deve rispondere 401 `INVALID_CREDENTIALS` con lo stesso messaggio in entrambi i casi. | API |
| AC-R2-03 | Quando il login riesce, l'app deve mostrare l'area riservata (dashboard azienda). | UI |
| AC-R2-04 | Finché l'azienda non fa logout, l'app deve mantenere la sessione anche dopo la chiusura e riapertura. All'avvio, se il `TokenStore` contiene un token, l'app chiama E4: con 200 ripristina la sessione; con 401 cancella il token; se la rete fallisce conserva il token. In ogni caso apre la bacheca. | UI |
| AC-R2-05 | Se email o password mancano o il body non è JSON valido, allora il sistema deve rispondere 400 `VALIDATION_ERROR`. | API |

## R3 — Logout (azienda)
| ID | Criterio | Verifica |
|---|---|---|
| AC-R3-01 | Quando l'azienda fa logout, il sistema deve invalidare il token; ogni uso successivo deve ricevere 401. | API |
| AC-R3-02 | Quando il logout riesce, l'app deve cancellare il token, tornare alla bacheca pubblica e impedire di rientrare nell'area riservata (anche col tasto indietro). | UI |
| AC-R3-03 | Se una rotta riservata è chiamata senza token valido, allora il sistema deve rispondere 401 `UNAUTHORIZED`. | API |

## R4 — Pubblicazione annuncio (azienda)
| ID | Criterio | Verifica |
|---|---|---|
| AC-R4-01 | Quando un'azienda autenticata invia titolo e descrizione validi, il sistema deve creare l'annuncio (201) e renderlo visibile in bacheca. | API |
| AC-R4-02 | Se la richiesta non è autenticata, allora il sistema deve rispondere 401 senza creare nulla. | API |
| AC-R4-03 | Se titolo o descrizione non sono validi, allora il sistema deve rispondere 400 `VALIDATION_ERROR`. | API |
| AC-R4-04 | Quando la pubblicazione riesce, l'app deve mostrare l'annuncio tra "I miei annunci" e nella bacheca pubblica. | UI |
| AC-R4-05 | Il sistema deve prendere il proprietario dell'annuncio (`companyId`) sempre dal token; un `companyId` nel body viene ignorato. | API |

## R5 — Consultazione bacheca (candidato)
| ID | Criterio | Verifica |
|---|---|---|
| AC-R5-01 | Il sistema deve restituire senza autenticazione l'elenco degli annunci, dal più recente, con il nome dell'azienda. | API |
| AC-R5-02 | Quando si richiede un annuncio esistente il sistema deve restituirne il dettaglio; se non esiste, 404 `NOT_FOUND`. | API |
| AC-R5-03 | Quando `BachecaApp` viene avviata senza login con dipendenze iniettate, deve mostrare la bacheca; toccando un annuncio deve mostrarne il dettaglio. Con bacheca vuota mostra «Nessun annuncio pubblicato». | UI |

## R6 — Candidatura (candidato)
| ID | Criterio | Verifica |
|---|---|---|
| AC-R6-01 | Quando un candidato invia nome, cognome, email validi e un CV PDF, il sistema deve salvare candidatura e file e rispondere 201. | API |
| AC-R6-02 | Se mancano campi o l'email non è valida, allora il sistema deve rispondere 400 `VALIDATION_ERROR` senza salvare il file. | API |
| AC-R6-03 | Se il file manca, è vuoto, non inizia con i byte `%PDF` o supera 5 MB, allora il sistema deve rispondere 400 `INVALID_FILE`. | API |
| AC-R6-04 | Se l'annuncio non esiste, allora il sistema deve rispondere 404 `NOT_FOUND`. | API |
| AC-R6-05 | Quando l'invio riesce, l'app deve mostrare «Candidatura inviata!»; durante l'invio il pulsante è disabilitato. | UI |

## R7 — Consultazione candidature (azienda)
| ID | Criterio | Verifica |
|---|---|---|
| AC-R7-01 | Il sistema deve restituire all'azienda autenticata i propri annunci con il numero di candidature. | API |
| AC-R7-02 | Il sistema deve restituire le candidature di un annuncio solo al proprietario; a un'altra azienda risponde 403 `FORBIDDEN`. | API |
| AC-R7-03 | Il sistema deve restituire il dettaglio di una candidatura (nome, cognome, email, data) al proprietario dell'annuncio. | API |
| AC-R7-04 | Il sistema deve restituire il CV come `application/pdf` identico al file caricato, solo al proprietario (altrimenti 403). | API |
| AC-R7-05 | Dalla lista candidature l'app deve aprire il dettaglio e, col pulsante "Apri curriculum", scaricare il CV (E12) e passarne byte e `cvOriginalName` a `CvOpener`, che lo apre col visualizzatore di sistema. Se l'apertura fallisce, l'app mostra «Nessuna app per aprire il PDF». | UI |

## Requisiti non funzionali
| ID | Criterio | Verifica |
|---|---|---|
| AC-NF-01 | Dopo il riavvio del server, aziende, annunci, candidature e CV devono essere ancora disponibili. | API |
| AC-NF-02 | L'indirizzo del server deve essere configurabile senza modificare il codice (`--dart-define=API_BASE_URL`): in `app/lib/` nessun URL `http(s)://` letterale. | TOOL |
| AC-NF-03 | Nessun file dei due repository deve superare 200 righe. | TOOL |
| AC-NF-04 | L'app deve convertire gli errori API nei messaggi italiani di `03-domain-model.md`, preservare `fields` per `VALIDATION_ERROR` e distinguere `NOT_FOUND` per E6/E9 dagli altri endpoint. | UI |
| AC-NF-05 | Quando `TokenStore` contiene un token, `ApiClient` deve inviarlo come `Authorization: Bearer <token>`; senza token deve omettere l'header. | UI |
| AC-NF-06 | I `fromJson` dei modelli app devono leggere i campi degli schemi API; `createdAt` arriva come stringa ISO-8601 e `Job.location` può essere null. | UI |
| AC-NF-07 | `InMemoryTokenStore` deve leggere il token iniziale, conservare quello scritto e restituire null dopo `clear()`. | UI |
