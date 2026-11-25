import 'dart:convert';

import 'package:shelf/shelf.dart';

/// Errore API nel formato unico di specs/04-api-contract.md:
/// `{"error": {"code", "message", "fields?"}}`.
class ApiError implements Exception {
  const ApiError(this.status, this.code, this.message, {this.fields});

  const ApiError.notFound([String message = 'Risorsa non trovata'])
      : this(404, 'NOT_FOUND', message);

  final int status;
  final String code;
  final String message;

  /// Errori per campo, solo con `VALIDATION_ERROR`.
  final Map<String, String>? fields;

  Response toResponse() => jsonResponse(status, {
        'error': {
          'code': code,
          'message': message,
          if (fields != null) 'fields': fields,
        },
      });

  @override
  String toString() => 'ApiError($status $code: $message)';
}

/// Risposta JSON UTF-8.
Response jsonResponse(int status, Object body) => Response(
      status,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
    );
