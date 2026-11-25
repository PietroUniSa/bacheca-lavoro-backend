import 'dart:convert';

import 'package:shelf/shelf.dart';

import 'api_error.dart';

const _invalidJson = ApiError(400, 'VALIDATION_ERROR', 'JSON non valido');

/// Legge il body come oggetto JSON; se malformato o non oggetto → 400
/// `VALIDATION_ERROR` "JSON non valido" (specs/04 § Regole trasversali).
Future<Map<String, dynamic>> readJsonObject(Request request) async {
  final Object? decoded;
  try {
    decoded = jsonDecode(await request.readAsString());
  } on FormatException {
    throw _invalidJson;
  }
  if (decoded is! Map<String, dynamic>) throw _invalidJson;
  return decoded;
}

/// 400 `VALIDATION_ERROR` con gli errori per campo.
ApiError validationError(Map<String, String> fields) =>
    ApiError(400, 'VALIDATION_ERROR', 'Dati non validi', fields: fields);
