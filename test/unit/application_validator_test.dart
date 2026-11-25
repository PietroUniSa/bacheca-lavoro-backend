// T06 — validatori puri della candidatura e del CV (specs/03, constitution C6).
import 'dart:io';

import 'package:bacheca_backend/src/services/cv_storage.dart';
import 'package:bacheca_backend/src/validation/application_validator.dart';
import 'package:test/test.dart';

void main() {
  const valid = {
    'firstName': 'Mario',
    'lastName': 'Rossi',
    'email': 'mario.rossi@example.com',
  };

  test('AC-R6-02 campi validi; limiti 1–60 dopo trim; email', () {
    expect(validateApplicant(valid), isEmpty);
    expect(
        validateApplicant({...valid, 'firstName': '   '}).keys, ['firstName']);
    expect(
        validateApplicant({...valid, 'lastName': 'x' * 61}).keys, ['lastName']);
    expect(validateApplicant({...valid, 'email': 'mario@'}).keys, ['email']);
    expect(validateApplicant({}).keys,
        unorderedEquals(['firstName', 'lastName', 'email']));
  });

  test('AC-R6-03 PDF riconosciuto solo dai magic bytes e dalla dimensione', () {
    expect(isValidCv('%PDF-1.4'.codeUnits), isTrue);
    expect(isValidCv(null), isFalse);
    expect(isValidCv(const []), isFalse);
    expect(isValidCv('%PD'.codeUnits), isFalse);
    expect(isValidCv('ciao'.codeUnits), isFalse);
    final max = List<int>.filled(maxCvBytes, 32)..setAll(0, '%PDF'.codeUnits);
    expect(isValidCv(max), isTrue);
    expect(isValidCv([...max, 32]), isFalse);
  });

  test('AC-R7-04 nome originale senza percorso e nome sicuro per l\'header',
      () {
    expect(originalCvName(r'C:\Users\x\cv_mario.pdf'), 'cv_mario.pdf');
    expect(originalCvName('../../etc/cv.pdf'), 'cv.pdf');
    expect(originalCvName(null), 'cv.pdf');
    expect(originalCvName('a' * 300), hasLength(255));
    expect(safeFileName('cv "Mario"\r\n.pdf'), 'cv__Mario___.pdf');
  });

  test('AC-R6-01 CvStorage: nome generato dal server, mai quello del client',
      () async {
    final dir = await Directory.systemTemp.createTemp('bacheca_cv_');
    addTearDown(() => dir.delete(recursive: true));
    final storage = CvStorage(dir.path);
    final name = await storage.save('%PDF-x'.codeUnits);
    expect(name, matches(RegExp(r'^[0-9a-f]{32}\.pdf$')));
    expect(await storage.read(name), '%PDF-x'.codeUnits);
    await storage.delete(name);
    expect(await storage.read(name), isNull);
    expect(() => storage.read('../bacheca.db'), throwsArgumentError);
  });
}
