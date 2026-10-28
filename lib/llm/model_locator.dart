import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Busca el archivo .litertlm en /storage/emulated/0/Axel_models.
abstract final class ModelLocator {
  static const String dirPath = '/storage/emulated/0/Axel_models';

  static const String help =
      'No encontré el modelo. Copia un archivo .litertlm a $dirPath '
      '(por ejemplo con adb push) y vuelve a intentar.';

  /// Devuelve la ruta del modelo, o null si no hay ninguno.
  static Future<String?> findModel() async {
    if (!Platform.isAndroid) return null;

    if (!await Permission.manageExternalStorage.isGranted) {
      final s = await Permission.manageExternalStorage.request();
      if (!s.isGranted) {
        throw StateError(
            'Falta el permiso "Acceso a todos los archivos" para Axel.');
      }
    }

    final dir = Directory(dirPath);
    if (!await dir.exists()) return null;

    final files = <File>[];
    await for (final f in dir.list()) {
      if (f is File && f.path.endsWith('.litertlm')) files.add(f);
    }
    if (files.isEmpty) return null;

    files.sort((a, b) => a.path.compareTo(b.path));
    final e4b = files.where((f) => f.path.contains('E4B'));
    return (e4b.isNotEmpty ? e4b.first : files.first).path;
  }
}