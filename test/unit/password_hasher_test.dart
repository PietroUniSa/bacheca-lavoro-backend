// T03 — PasswordHasher: PBKDF2 con salt casuale (constitution C6).
import 'dart:convert';

import 'package:bacheca_backend/src/services/password_hasher.dart';
import 'package:test/test.dart';

void main() {
  final hasher = PasswordHasher(iterations: 1000);

  test("AC-R1-04 l'hash non contiene la password e ha il formato atteso",
      () async {
    final h = await hasher.hash('Password123');
    expect(h, isNot(contains('Password123')));
    final parts = h.split(r'$');
    expect(parts, hasLength(4));
    expect(parts[0], 'pbkdf2-sha256');
    expect(parts[1], '1000');
    expect(base64Decode(parts[2]), hasLength(16));
    expect(base64Decode(parts[3]), hasLength(32));
  });

  test('AC-R2-01 AC-R2-02 verify: password giusta sì, sbagliata no', () async {
    final h = await hasher.hash('Password123');
    expect(await hasher.verify('Password123', h), isTrue);
    expect(await hasher.verify('Password124', h), isFalse);
    expect(await hasher.verify('Password123', 'non-un-hash'), isFalse);
    // le iterazioni si leggono dall'hash, non dalla configurazione corrente
    expect(
        await PasswordHasher(iterations: 5).verify('Password123', h), isTrue);
  });

  test('AC-R1-04 salt casuale: stessa password → hash diversi', () async {
    expect(await hasher.hash('Password123'),
        isNot(await hasher.hash('Password123')));
  });
}
