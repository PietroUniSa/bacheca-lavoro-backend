import 'email.dart';

/// Dimensione massima del CV: 5 MB (constitution C6).
const maxCvBytes = 5 * 1024 * 1024;

/// Valida i campi testo di E9. Regole: specs/03-domain-model.md § Application.
Map<String, String> validateApplicant(Map<String, String> fields) {
  final errors = <String, String>{};
  for (final (field, label) in [
    ('firstName', 'Il nome'),
    ('lastName', 'Il cognome')
  ]) {
    final length = fields[field]?.trim().length ?? 0;
    if (length < 1 || length > 60) {
      errors[field] = '$label deve avere tra 1 e 60 caratteri';
    }
  }
  if (!isValidEmail(fields['email']?.trim() ?? '')) {
    errors['email'] = 'Email non valida';
  }
  return errors;
}

/// Vero se [bytes] è un PDF accettabile: 1 byte–5 MB e inizia con `%PDF`.
/// Il tipo si decide solo dai magic bytes, mai dal nome o dal Content-Type.
bool isValidCv(List<int>? bytes) =>
    bytes != null &&
    bytes.length >= 4 &&
    bytes.length <= maxCvBytes &&
    bytes[0] == 0x25 && // %
    bytes[1] == 0x50 && // P
    bytes[2] == 0x44 && // D
    bytes[3] == 0x46; //   F

/// Nome originale da mostrare: senza percorso, max 255 caratteri.
String originalCvName(String? clientName) {
  final base = (clientName ?? '').split(RegExp(r'[\\/]')).last.trim();
  if (base.isEmpty) return 'cv.pdf';
  return base.length > 255 ? base.substring(0, 255) : base;
}

/// Nome sicuro per l'header `Content-Disposition` (specs/04 § E12).
String safeFileName(String name) =>
    name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
