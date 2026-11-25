// T05 — validatore puro degli annunci (specs/03-domain-model.md § JobPost).
import 'package:bacheca_backend/src/validation/job_validator.dart';
import 'package:test/test.dart';

void main() {
  const valid = {
    'title': 'Sviluppatore Flutter Junior',
    'description': 'Cerchiamo uno sviluppatore Flutter junior.',
  };

  test('AC-R4-03 dati validi, location opzionale', () {
    expect(validateJob(valid), isEmpty);
    expect(validateJob({...valid, 'location': 'Napoli'}), isEmpty);
    expect(validateJob({...valid, 'location': null}), isEmpty);
  });

  test('AC-R4-03 limiti di lunghezza dopo trim', () {
    expect(validateJob({...valid, 'title': '  ab  '}).keys, ['title']);
    expect(validateJob({...valid, 'title': 'x' * 121}).keys, ['title']);
    expect(validateJob({...valid, 'description': ' 123456789 '}).keys,
        ['description']);
    expect(validateJob({...valid, 'description': 'x' * 5001}).keys,
        ['description']);
    expect(validateJob({...valid, 'location': 'x' * 101}).keys, ['location']);
    expect(validateJob({...valid, 'location': 42}).keys, ['location']);
  });

  test('AC-R4-03 campi mancanti', () {
    expect(validateJob({}).keys, unorderedEquals(['title', 'description']));
  });

  test('AC-R4-05 campi sconosciuti ignorati; trim e location vuota → null', () {
    final body = {
      ...valid,
      'title': '  Titolo  ',
      'location': '   ',
      'companyId': 999,
    };
    expect(validateJob(body), isEmpty);
    final input = toJobInput(body);
    expect(input.title, 'Titolo');
    expect(input.location, isNull);
  });
}
