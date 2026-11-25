import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

import 'config.dart';
import 'db/database.dart';
import 'http/api_error.dart';
import 'http/middleware.dart';
import 'repos/company_repo.dart';
import 'repos/application_repo.dart';
import 'repos/job_repo.dart';
import 'repos/session_repo.dart';
import 'routes/application_routes.dart';
import 'routes/auth_routes.dart';
import 'routes/job_routes.dart';
import 'services/cv_storage.dart';
import 'services/password_hasher.dart';

/// Server in esecuzione (firma obbligatoria: specs/05-architecture.md).
abstract class RunningServer {
  /// Porta effettiva (0 in config = porta libera).
  int get port;

  /// Chiude HTTP e database (su Windows serve per liberare i file).
  Future<void> close();
}

class _RunningServer implements RunningServer {
  _RunningServer(this._http, this._db);
  final HttpServer _http;
  final Database _db;

  @override
  int get port => _http.port;

  @override
  Future<void> close() async {
    await _http.close(force: true);
    _db.close();
  }
}

/// Avvia il server HTTP con le rotte dell'API.
Future<RunningServer> startServer(ServerConfig config) async {
  final db = openDatabase(config.dataDir);
  final sessions = SessionRepo(db);
  final auth = AuthRoutes(CompanyRepo(db), sessions,
      PasswordHasher(iterations: config.pbkdf2Iterations));
  final jobRepo = JobRepo(db);
  final jobs = JobRoutes(jobRepo);
  final applications = ApplicationRoutes(
      jobRepo, ApplicationRepo(db), CvStorage(config.dataDir));
  Handler authed(Handler h) =>
      const Pipeline().addMiddleware(requireAuth(sessions)).addHandler(h);

  final router = Router(notFoundHandler: _notFound)
    ..get('/health', (Request _) => jsonResponse(200, {'status': 'ok'}))
    ..post('/api/auth/register', auth.register)
    ..post('/api/auth/login', auth.login)
    ..post('/api/auth/logout', authed(auth.logout))
    ..get('/api/me', authed(auth.me))
    ..get('/api/jobs', jobs.list)
    ..get('/api/jobs/<id|[0-9]+>', jobs.detail)
    ..post('/api/jobs', authed(jobs.create))
    ..get('/api/companies/me/jobs', authed(jobs.mine))
    ..post('/api/jobs/<id|[0-9]+>/applications', applications.create)
    ..get('/api/jobs/<id|[0-9]+>/applications',
        authed(_withId(applications.listForJob)))
    ..get('/api/applications/<id|[0-9]+>', authed(_withId(applications.detail)))
    ..get('/api/applications/<id|[0-9]+>/cv', authed(_withId(applications.cv)));

  final handler = const Pipeline()
      .addMiddleware(requestLog())
      .addMiddleware(errorMiddleware())
      .addHandler(router.call);

  try {
    final http = await shelf_io.serve(handler, config.host, config.port);
    return _RunningServer(http, db);
  } catch (_) {
    db.close();
    rethrow;
  }
}

Response _notFound(Request request) => const ApiError.notFound().toResponse();

/// Adatta un handler `(Request, String id)` a `Handler` per poterlo avvolgere
/// in `requireAuth`: l'id arriva dai parametri di shelf_router.
Handler _withId(FutureOr<Response> Function(Request, String) handler) =>
    (Request request) => handler(request, request.params['id']!);
