/// Dati di un nuovo annuncio già normalizzati (trim; location vuota → null).
class JobInput {
  const JobInput(this.title, this.description, this.location);
  final String title;
  final String description;
  final String? location;
}

/// Valida il body di E7. Regole: specs/03-domain-model.md § JobPost.
/// Campi sconosciuti (es. `companyId`) sono ignorati (AC-R4-05).
Map<String, String> validateJob(Map<String, dynamic> body) {
  final errors = <String, String>{};
  if (!_lengthBetween(body['title'], 3, 120)) {
    errors['title'] = 'Il titolo deve avere tra 3 e 120 caratteri';
  }
  if (!_lengthBetween(body['description'], 10, 5000)) {
    errors['description'] = 'La descrizione deve avere tra 10 e 5000 caratteri';
  }
  final location = body['location'];
  if (location != null && !_lengthBetween(location, 0, 100)) {
    errors['location'] = 'La sede può avere al massimo 100 caratteri';
  }
  return errors;
}

/// Da chiamare solo se [validateJob] non ha trovato errori.
JobInput toJobInput(Map<String, dynamic> body) {
  final location = (body['location'] as String?)?.trim();
  return JobInput(
    (body['title'] as String).trim(),
    (body['description'] as String).trim(),
    location == null || location.isEmpty ? null : location,
  );
}

bool _lengthBetween(Object? value, int min, int max) {
  if (value is! String) return false;
  final length = value.trim().length;
  return length >= min && length <= max;
}
