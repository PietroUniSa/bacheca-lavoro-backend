// T03 — validatori puri della registrazione (specs/03-domain-model.md).
import 'package:bacheca_backend/src/validation/company_validator.dart';
import 'package:bacheca_backend/src/validation/email.dart';
import 'package:test/test.dart';

void main() {
  const valid = {
    'name': 'Acme Srl',
    'email': 'hr@acme.it',
    'password': 'Password123',
  };

  test('AC-R1-03 dati validi → nessun errore', () {
    expect(validateRegistration(valid), isEmpty);
  });

  test('AC-R1-03 limiti di lunghezza (nome dopo trim)', () {
    final errors = validateRegistration(
        {'name': '  A  ', 'email': 'hr@acme.it', 'password': 'x' * 129});
    expect(errors.keys, unorderedEquals(['name', 'password']));
    expect(validateRegistration({...valid, 'name': 'x' * 101}).keys, ['name']);
    expect(validateRegistration({...valid, 'password': '1234567'}).keys,
        ['password']);
  });

  test('AC-R1-03 campi mancanti o di tipo sbagliato', () {
    expect(validateRegistration({}).keys,
        unorderedEquals(['name', 'email', 'password']));
    expect(validateRegistration({...valid, 'name': 42}).keys, ['name']);
  });

  test('AC-R1-03 regex email condivisa', () {
    for (final ok in ['a@b.it', 'mario.rossi@example.com']) {
      expect(isValidEmail(ok), isTrue, reason: ok);
    }
    for (final ko in ['', 'a@b', 'a@b.c', 'a b@c.it', '@acme.it', 'a@@b.it']) {
      expect(isValidEmail(ko), isFalse, reason: ko);
    }
  });

  test('AC-R1-02 email normalizzata: trim e minuscolo', () {
    expect(toRegistration({...valid, 'email': ' HR@Acme.IT '}).email,
        'hr@acme.it');
    expect(toRegistration({...valid, 'name': '  Acme Srl '}).name, 'Acme Srl');
  });
}
