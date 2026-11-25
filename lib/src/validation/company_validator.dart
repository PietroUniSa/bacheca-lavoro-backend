import 'email.dart';

/// Dati di registrazione già normalizzati (trim, email minuscola).
class Registration {
  const Registration(this.name, this.email, this.password);
  final String name;
  final String email;
  final String password;
}

/// Valida il body di E1. Ritorna gli errori per campo (vuoto = valido).
/// Regole: specs/03-domain-model.md § Company.
Map<String, String> validateRegistration(Map<String, dynamic> body) {
  final errors = <String, String>{};
  final name = body['name'];
  if (name is! String || name.trim().length < 2 || name.trim().length > 100) {
    errors['name'] = 'La ragione sociale deve avere tra 2 e 100 caratteri';
  }
  final email = body['email'];
  if (email is! String || !isValidEmail(normalizeEmail(email))) {
    errors['email'] = 'Email non valida';
  }
  final password = body['password'];
  if (password is! String || password.length < 8 || password.length > 128) {
    errors['password'] = 'La password deve avere tra 8 e 128 caratteri';
  }
  return errors;
}

/// Valida il body di E2 (AC-R2-05): email e password presenti come stringhe
/// non vuote. Il formato non si controlla: credenziali errate → 401.
Map<String, String> validateLogin(Map<String, dynamic> body) => {
      for (final field in ['email', 'password'])
        if (body[field] is! String || (body[field] as String).trim().isEmpty)
          field: 'Campo obbligatorio',
    };

/// Da chiamare solo se [validateRegistration] non ha trovato errori.
Registration toRegistration(Map<String, dynamic> body) => Registration(
      (body['name'] as String).trim(),
      normalizeEmail(body['email'] as String),
      body['password'] as String,
    );
