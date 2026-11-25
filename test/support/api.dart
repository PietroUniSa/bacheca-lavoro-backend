// Client di test che parla HTTP col server reale + fixture riusabili.
import 'dart:convert';

import 'package:http/http.dart' as http;

class Res {
  Res(this.status, this.bytes, this.headers);
  final int status;
  final List<int> bytes;
  final Map<String, String> headers;
  dynamic get json => jsonDecode(utf8.decode(bytes));
  String? get errorCode => (json as Map)['error']?['code'] as String?;
  List<dynamic> get items => (json as Map)['items'] as List<dynamic>;
}

class Api {
  Api(this.base);
  final Uri base;

  Map<String, String> _auth(String? token) =>
      token == null ? {} : {'Authorization': 'Bearer $token'};

  Future<Res> get(String path, {String? token}) async {
    final r = await http.get(base.resolve(path), headers: _auth(token));
    return Res(r.statusCode, r.bodyBytes, r.headers);
  }

  Future<Res> post(
    String path, {
    Object? json,
    String? token,
    String? rawBody,
  }) async {
    final r = await http.post(
      base.resolve(path),
      headers: {'Content-Type': 'application/json', ..._auth(token)},
      body: rawBody ?? (json == null ? null : jsonEncode(json)),
    );
    return Res(r.statusCode, r.bodyBytes, r.headers);
  }

  Future<Res> apply(
    int jobId, {
    Map<String, String>? fields,
    List<int>? file,
    String fileName = 'cv.pdf',
  }) async {
    final req = http.MultipartRequest(
      'POST',
      base.resolve('/api/jobs/$jobId/applications'),
    )..fields.addAll(fields ?? validApplicant);
    if (file != null) {
      req.files.add(
        http.MultipartFile.fromBytes('cv', file, filename: fileName),
      );
    }
    final r = await http.Response.fromStream(await req.send());
    return Res(r.statusCode, r.bodyBytes, r.headers);
  }

  // ---------- fixture ----------

  Future<Res> register(
    String email, {
    String name = 'Acme Srl',
    String password = 'Password123',
  }) => post(
    '/api/auth/register',
    json: {'name': name, 'email': email, 'password': password},
  );

  Future<String> registerAndLogin(
    String email, {
    String name = 'Acme Srl',
  }) async {
    await register(email, name: name);
    final r = await post(
      '/api/auth/login',
      json: {'email': email, 'password': 'Password123'},
    );
    return (r.json as Map)['token'] as String;
  }

  Future<int> createJob(
    String token, {
    String title = 'Sviluppatore Flutter Junior',
  }) async {
    final r = await post(
      '/api/jobs',
      token: token,
      json: {
        'title': title,
        'description':
            'Cerchiamo uno sviluppatore Flutter junior per app mobile.',
        'location': 'Napoli',
      },
    );
    return (r.json as Map)['id'] as int;
  }

  Future<int> createApplication(int jobId, {List<int>? file}) async {
    final r = await apply(
      jobId,
      file: file ?? tinyPdf('Mario Rossi'),
      fileName: 'cv_mario_rossi.pdf',
    );
    return (r.json as Map)['id'] as int;
  }
}

const validApplicant = {
  'firstName': 'Mario',
  'lastName': 'Rossi',
  'email': 'mario.rossi@example.com',
};

/// PDF minimo valido (inizia con %PDF).
List<int> tinyPdf(String label) => utf8.encode(
  '%PDF-1.4\n'
  '1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n'
  '2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n'
  '3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 200 200]>>endobj\n'
  '% $label\ntrailer<</Root 1 0 R>>\n%%EOF\n',
);
