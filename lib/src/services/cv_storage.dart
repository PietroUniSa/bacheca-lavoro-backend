import 'dart:io';
import 'dart:math';

/// CV su filesystem in `<dataDir>/uploads/<32 hex>.pdf` (ADR A5).
/// Il nome del file è sempre generato qui, mai preso dal client (C6).
class CvStorage {
  CvStorage(String dataDir)
      : _dir = Directory('$dataDir${Platform.pathSeparator}uploads');

  final Directory _dir;
  static final _random = Random.secure();
  static final _validName = RegExp(r'^[0-9a-f]{32}\.pdf$');

  /// Salva [bytes] e ritorna il nome generato.
  Future<String> save(List<int> bytes) async {
    await _dir.create(recursive: true);
    final name =
        '${List.generate(16, (_) => _random.nextInt(256)).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}.pdf';
    await _file(name).writeAsBytes(bytes, flush: true);
    return name;
  }

  /// Byte del CV, o null se il file non esiste.
  Future<List<int>?> read(String name) async {
    final file = _file(name);
    return await file.exists() ? file.readAsBytes() : null;
  }

  Future<void> delete(String name) async {
    final file = _file(name);
    if (await file.exists()) await file.delete();
  }

  File _file(String name) {
    if (!_validName.hasMatch(name)) {
      throw ArgumentError.value(
          name, 'name', 'nome CV non generato dal server');
    }
    return File('${_dir.path}${Platform.pathSeparator}$name');
  }
}
