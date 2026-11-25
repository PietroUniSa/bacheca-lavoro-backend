import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// PBKDF2-HMAC-SHA256 con salt casuale di 16 byte (constitution C6).
/// Formato salvato: `pbkdf2-sha256$<iterazioni>$<salt b64>$<hash b64>`.
class PasswordHasher {
  PasswordHasher({required this.iterations});

  final int iterations;
  static final _random = Random.secure();

  Future<String> hash(String password) async {
    final salt = List<int>.generate(16, (_) => _random.nextInt(256));
    final derived = await _derive(password, salt, iterations);
    return 'pbkdf2-sha256\$$iterations\$${base64Encode(salt)}\$'
        '${base64Encode(derived)}';
  }

  /// Vero se [password] corrisponde a [stored]. Usa le iterazioni salvate
  /// nell'hash; confronto a tempo costante. Hash malformato → false.
  Future<bool> verify(String password, String stored) async {
    final parts = stored.split(r'$');
    final storedIterations = parts.length == 4 ? int.tryParse(parts[1]) : null;
    if (parts.first != 'pbkdf2-sha256' || storedIterations == null) {
      return false;
    }
    final expected = base64Decode(parts[3]);
    final actual =
        await _derive(password, base64Decode(parts[2]), storedIterations);
    if (actual.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual[i] ^ expected[i];
    }
    return diff == 0;
  }

  static Future<List<int>> _derive(
      String password, List<int> salt, int iterations) async {
    final pbkdf2 =
        Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256);
    final key =
        await pbkdf2.deriveKeyFromPassword(password: password, nonce: salt);
    return key.extractBytes();
  }
}
