import 'package:shelf/shelf.dart';

import '../http/api_error.dart';
import '../http/json_body.dart';
import '../http/middleware.dart';
import '../http/multipart_form.dart';
import '../repos/application_repo.dart';
import '../repos/job_repo.dart';
import '../services/cv_storage.dart';
import '../validation/application_validator.dart';

const _jobNotFound = ApiError.notFound('Annuncio non trovato');
const _invalidFile = ApiError(
    400, 'INVALID_FILE', 'Il curriculum deve essere un PDF (max 5 MB)');

/// Rotte delle candidature (specs/04: E9–E12).
class ApplicationRoutes {
  ApplicationRoutes(this._jobs, this._applications, this._cvs);
  final JobRepo _jobs;
  final ApplicationRepo _applications;
  final CvStorage _cvs;

  /// E9 `POST /api/jobs/{id}/applications` → 201 | 400 | 404.
  /// Ordine: annuncio, campi testo, file; il file si scrive solo se è tutto
  /// valido e si cancella se l'INSERT fallisce.
  Future<Response> create(Request request, String id) async {
    final jobId = int.parse(id);
    if (_jobs.findById(jobId) == null) {
      await request.read().drain<void>();
      throw _jobNotFound;
    }
    final form = await readApplicationForm(request, maxCvBytes);
    final errors = validateApplicant(form.fields);
    if (errors.isNotEmpty) throw validationError(errors);
    final cv = form.cvBytes;
    if (form.cvTooBig || cv == null || !isValidCv(cv)) throw _invalidFile;

    final fileName = await _cvs.save(cv);
    try {
      final saved = _applications.insert(NewApplication(
        jobId,
        form.fields['firstName']!.trim(),
        form.fields['lastName']!.trim(),
        form.fields['email']!.trim(),
        fileName,
        originalCvName(form.cvName),
        cv.length,
      ));
      return jsonResponse(201, saved.toJson());
    } catch (_) {
      await _cvs.delete(fileName);
      rethrow;
    }
  }

  /// E10 `GET /api/jobs/{id}/applications` 🔒 → 200 | 403 | 404.
  Response listForJob(Request request, String id) {
    final job = _jobs.findById(int.parse(id));
    if (job == null) throw _jobNotFound;
    requireOwner(request, job.companyId);
    final items = _applications.listByJob(job.id).map((a) => a.toJson());
    return jsonResponse(200, {'items': items.toList()});
  }

  /// E11 `GET /api/applications/{id}` 🔒 → 200 | 403 | 404.
  Response detail(Request request, String id) =>
      jsonResponse(200, _owned(request, id).toJson());

  /// E12 `GET /api/applications/{id}/cv` 🔒 → 200 application/pdf.
  Future<Response> cv(Request request, String id) async {
    final application = _owned(request, id);
    final bytes = await _cvs.read(application.cvFileName);
    if (bytes == null) throw const ApiError.notFound('Curriculum non trovato');
    final name = application.cvOriginalName;
    return Response.ok(bytes, headers: {
      'Content-Type': 'application/pdf',
      'Content-Length': '${bytes.length}',
      'Content-Disposition': 'inline; filename="${safeFileName(name)}"; '
          "filename*=UTF-8''${Uri.encodeComponent(name)}",
    });
  }

  JobApplication _owned(Request request, String id) {
    final application = _applications.findById(int.parse(id));
    if (application == null) {
      throw const ApiError.notFound('Candidatura non trovata');
    }
    requireOwner(request, application.ownerCompanyId);
    return application;
  }
}
