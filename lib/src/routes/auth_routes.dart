import 'package:shelf/shelf.dart';

import '../http/api_error.dart';
import '../http/json_body.dart';
import '../http/middleware.dart';
import '../repos/company_repo.dart';
import '../repos/session_repo.dart';
import '../services/password_hasher.dart';
import '../validation/company_validator.dart';
import '../validation/email.dart';

const _invalidCredentials =
    ApiError(401, 'INVALID_CREDENTIALS', 'Credenziali non valide');

/// Rotte di autenticazione (specs/04: E1–E4).
class AuthRoutes {
  AuthRoutes(this._companies, this._sessions, this._hasher);
  final CompanyRepo _companies;
  final SessionRepo _sessions;
  final PasswordHasher _hasher;

  /// E1 `POST /api/auth/register` → 201 Company | 400 | 409.
  Future<Response> register(Request request) async {
    final body = await readJsonObject(request);
    final errors = validateRegistration(body);
    if (errors.isNotEmpty) throw validationError(errors);
    final data = toRegistration(body);
    if (_companies.emailExists(data.email)) {
      throw const ApiError(409, 'EMAIL_TAKEN', 'Email già registrata');
    }
    final hash = await _hasher.hash(data.password);
    final company = _companies.insert(data.name, data.email, hash);
    return jsonResponse(201, company.toJson());
  }

  /// E2 `POST /api/auth/login` → 200 {token, company} | 400 | 401.
  /// Email sconosciuta e password errata danno lo stesso errore (AC-R2-02).
  Future<Response> login(Request request) async {
    final body = await readJsonObject(request);
    final errors = validateLogin(body);
    if (errors.isNotEmpty) throw validationError(errors);
    final found =
        _companies.findByEmail(normalizeEmail(body['email'] as String));
    if (found == null ||
        !await _hasher.verify(body['password'] as String, found.passwordHash)) {
      throw _invalidCredentials;
    }
    final token = _sessions.create(found.company.id);
    return jsonResponse(
        200, {'token': token, 'company': found.company.toJson()});
  }

  /// E3 `POST /api/auth/logout` 🔒 → 204: il token non vale più (AC-R3-01).
  Response logout(Request request) {
    _sessions.delete(tokenOf(request));
    return Response(204);
  }

  /// E4 `GET /api/me` 🔒 → 200 Company.
  Response me(Request request) {
    final company = _companies.findById(companyIdOf(request));
    // La sessione esiste solo se l'azienda esiste (FK con CASCADE).
    if (company == null) throw const ApiError.notFound();
    return jsonResponse(200, company.toJson());
  }
}
