import 'package:shelf/shelf.dart';

import '../http/api_error.dart';
import '../http/json_body.dart';
import '../http/middleware.dart';
import '../repos/job_repo.dart';
import '../validation/job_validator.dart';

/// Rotte degli annunci (specs/04: E5–E8).
class JobRoutes {
  JobRoutes(this._jobs);
  final JobRepo _jobs;

  /// E5 `GET /api/jobs` → 200 {items: Job[]}, senza autenticazione.
  Response list(Request request) => jsonResponse(
      200, {'items': _jobs.listAll().map((j) => j.toJson()).toList()});

  /// E6 `GET /api/jobs/{id}` → 200 Job | 404.
  Response detail(Request request, String id) {
    final job = _jobs.findById(int.parse(id));
    if (job == null) throw const ApiError.notFound('Annuncio non trovato');
    return jsonResponse(200, job.toJson());
  }

  /// E7 `POST /api/jobs` 🔒 → 201 Job | 400. Proprietario dal token.
  Future<Response> create(Request request) async {
    final body = await readJsonObject(request);
    final errors = validateJob(body);
    if (errors.isNotEmpty) throw validationError(errors);
    final job = _jobs.insert(companyIdOf(request), toJobInput(body));
    return jsonResponse(201, job.toJson());
  }

  /// E8 `GET /api/companies/me/jobs` 🔒 → 200 {items: MyJob[]}.
  Response mine(Request request) => jsonResponse(200, {
        'items': _jobs
            .listByCompany(companyIdOf(request))
            .map((j) => j.toJson())
            .toList(),
      });
}
