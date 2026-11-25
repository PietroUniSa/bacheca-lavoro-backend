/// Regex email unica (specs/03-domain-model.md), copiata identica nell'app.
final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

/// Email normalizzata: trim + minuscolo (registrazione e login).
String normalizeEmail(String email) => email.trim().toLowerCase();

bool isValidEmail(String email) => emailPattern.hasMatch(email);
