import 'dart:io';

import 'package:shelf/shelf.dart';

import '../repos/session_repo.dart';
import 'api_error.dart';

/// Converte le eccezioni in risposte JSON: `ApiError` col suo stato, tutto il
/// resto in 500 `INTERNAL_ERROR` (log su stderr, mai stack trace al client).
Middleware errorMiddleware() => (Handler inner) => (Request request) async {
      try {
        return await inner(request);
      } on ApiError catch (e) {
        return e.toResponse();
      } on HijackException {
        rethrow;
      } catch (e, st) {
        stderr.writeln('ERRORE ${request.method} /${request.url}: $e\n$st');
        return const ApiError(
                500, 'INTERNAL_ERROR', 'Errore interno del server')
            .toResponse();
      }
    };

const _unauthorized = ApiError(401, 'UNAUTHORIZED', 'Autenticazione richiesta');

/// Rotte riservate (constitution C6): richiede `Authorization: Bearer <token>`
/// valido e mette l'azienda in `request.context['companyId']`; altrimenti 401.
Middleware requireAuth(SessionRepo sessions) => (Handler inner) =>
    (Request request) {
      final header = request.headers['authorization'] ?? '';
      if (!header.startsWith('Bearer ')) throw _unauthorized;
      final token = header.substring('Bearer '.length).trim();
      final companyId = sessions.companyIdFor(token);
      if (companyId == null) throw _unauthorized;
      return inner(
          request.change(context: {'companyId': companyId, 'token': token}));
    };

/// Azienda autenticata (solo dietro [requireAuth]).
int companyIdOf(Request request) => request.context['companyId']! as int;

/// Token della richiesta autenticata (solo dietro [requireAuth]).
String tokenOf(Request request) => request.context['token']! as String;

/// Helper unico di proprietà (constitution C6): un'azienda accede solo alle
/// risorse dei propri annunci; altrimenti 403 `FORBIDDEN`.
void requireOwner(Request request, int ownerCompanyId) {
  if (companyIdOf(request) != ownerCompanyId) {
    throw const ApiError(403, 'FORBIDDEN', 'Non hai accesso a questa risorsa');
  }
}

/// Una riga di log per richiesta: metodo, path, status, ms.
Middleware requestLog() => (Handler inner) => (Request request) async {
      final watch = Stopwatch()..start();
      final response = await inner(request);
      stdout.writeln('${request.method} /${request.url.path} '
          '${response.statusCode} ${watch.elapsedMilliseconds}ms');
      return response;
    };
