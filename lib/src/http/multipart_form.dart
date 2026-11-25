import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:shelf_multipart/shelf_multipart.dart';

/// Contenuto di un form `multipart/form-data` di candidatura (E9).
class ApplicationForm {
  ApplicationForm(this.fields, this.cvBytes, this.cvName, this.cvTooBig);

  /// Campi testo (solo i nomi noti; gli altri sono ignorati).
  final Map<String, String> fields;

  /// Byte della parte `cv` (al massimo `maxCvBytes`), null se assente.
  final Uint8List? cvBytes;

  /// Nome file dato dal client, null se assente.
  final String? cvName;

  /// Vero se la parte `cv` superava `maxCvBytes` (il resto è stato scartato).
  final bool cvTooBig;
}

const textFields = {'firstName', 'lastName', 'email'};

/// Legge il form. Il `Content-Type` della parte `cv` è ignorato (specs/04 E9).
/// Il body viene letto fino in fondo anche oltre il limite, così il client
/// riceve la risposta invece di una connessione chiusa.
Future<ApplicationForm> readApplicationForm(
    Request request, int maxCvBytes) async {
  final fields = <String, String>{};
  Uint8List? cvBytes;
  String? cvName;
  var tooBig = false;

  final form = request.formData();
  if (form == null) return ApplicationForm(fields, null, null, false);

  await for (final data in form.formData) {
    if (data.name == 'cv' && cvBytes == null && !tooBig) {
      cvName = data.filename;
      final builder = BytesBuilder(copy: false);
      await for (final chunk in data.part) {
        if (tooBig) continue; // scarta il resto
        builder.add(chunk);
        if (builder.length > maxCvBytes) {
          tooBig = true;
          builder.clear();
        }
      }
      if (!tooBig) cvBytes = builder.takeBytes();
    } else if (textFields.contains(data.name) && data.filename == null) {
      fields[data.name] = await data.part.readString();
    } else {
      await data.part.drain<void>();
    }
  }
  return ApplicationForm(fields, cvBytes, cvName, tooBig);
}
