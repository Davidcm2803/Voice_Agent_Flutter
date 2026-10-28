import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Decide dónde vive la carpeta `Axel`: privada de la app o compartida
/// (la que sincroniza Syncthing).
abstract final class StorageLocation {
  static const String sharedAndroid = '/storage/emulated/0/Axel';

  static Future<File> _prefFile() async {
    final support = await getApplicationSupportDirectory();
    return File('${support.path}/root_path.txt');
  }

  static Future<Directory> privateDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/Axel');
  }

  static Future<Directory> current() async {
    final f = await _prefFile();
    if (await f.exists()) {
      final p = (await f.readAsString()).trim();
      if (p.isNotEmpty) return Directory(p);
    }
    return privateDir();
  }

  static Future<bool> isShared() async =>
      (await current()).path == sharedAndroid;

  /// Cambia a la carpeta compartida y copia lo que ya existe.
  /// Devuelve null si salió bien, o un mensaje de error.
  static Future<String?> useShared() async {
    if (!Platform.isAndroid) return 'Solo disponible en Android.';

    final status = await Permission.manageExternalStorage.request();
    if (!status.isGranted) {
      return 'Falta el permiso "Acceso a todos los archivos".';
    }

    try {
      final from = await current();
      final to = Directory(sharedAndroid);
      await to.create(recursive: true);
      if (from.path != to.path) {
        await _copyMissing(from, to, 'entries');
        await _copyMissing(from, to, 'attachments');
      }
      await (await _prefFile()).writeAsString(sharedAndroid, flush: true);
      return null;
    } catch (e) {
      return 'No se pudo usar la carpeta compartida: $e';
    }
  }

  static Future<void> _copyMissing(
      Directory from, Directory to, String sub) async {
    final src = Directory('${from.path}/$sub');
    if (!await src.exists()) return;
    await Directory('${to.path}/$sub').create(recursive: true);
    await for (final f in src.list()) {
      if (f is! File || f.path.endsWith('.tmp')) continue;
      final name = f.uri.pathSegments.last;
      final dest = File('${to.path}/$sub/$name');
      if (!await dest.exists()) await f.copy(dest.path);
    }
  }
}