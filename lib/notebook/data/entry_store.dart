import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:voice_agent_flutter/notebook/data/storage_location.dart';
import 'package:voice_agent_flutter/notebook/models/entry.dart';

/// Guarda cada elemento como `entries/<id>.json`.
/// Los archivos son la fuente de verdad; cualquier índice es reconstruible.
class EntryStore {
  EntryStore._(this.root, this.deviceId);

  final Directory root;
  final String deviceId;

  Directory get _entries => Directory('${root.path}/entries');
  Directory get attachments => Directory('${root.path}/attachments');

  static Future<EntryStore> open() async {
    var base = await StorageLocation.current();
    try {
      await Directory('${base.path}/entries').create(recursive: true);
      await Directory('${base.path}/attachments').create(recursive: true);
    } catch (_) {
      // Sin permiso o carpeta inaccesible: volver a la carpeta privada.
      base = await StorageLocation.privateDir();
      await Directory('${base.path}/entries').create(recursive: true);
      await Directory('${base.path}/attachments').create(recursive: true);
    }

    // Syncthing no debe sincronizar archivos temporales.
    final ignore = File('${base.path}/.stignore');
    if (!await ignore.exists()) await ignore.writeAsString('*.tmp\n');

    // El id del dispositivo es local (no se sincroniza).
    final support = await getApplicationSupportDirectory();
    final idFile = File('${support.path}/device_id.txt');
    String deviceId;
    if (await idFile.exists()) {
      deviceId = (await idFile.readAsString()).trim();
    } else {
      deviceId = Entry.newId();
      await idFile.writeAsString(deviceId);
    }
    return EntryStore._(base, deviceId);
  }

  Future<List<Entry>> loadAll({bool includeDeleted = false}) async {
    // Puede haber varias versiones del mismo id (copias de conflicto de
    // Syncthing). Gana la de updatedAt más reciente.
    final byId = <String, Entry>{};
    await for (final f in _entries.list()) {
      if (f is! File || !f.path.endsWith('.json')) continue;
      try {
        final json =
            jsonDecode(await f.readAsString()) as Map<String, Object?>;
        final e = Entry.fromJson(json);
        final prev = byId[e.id];
        if (prev == null || e.updatedAt.isAfter(prev.updatedAt)) {
          byId[e.id] = e;
        }
      } catch (_) {
        // Archivo a medias (sincronizando): se ignora, no tumba la app.
      }
    }
    final result = byId.values
        .where((e) => includeDeleted || !e.deleted)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  Future<Entry> create({
    required EntryType type,
    required String title,
    String body = '',
    String? language,
    List<String> tags = const [],
  }) async {
    final now = DateTime.now().toUtc();
    final entry = Entry(
      id: Entry.newId(),
      type: type,
      title: title,
      body: body,
      language: language,
      tags: tags,
      createdAt: now,
      updatedAt: now,
      deviceId: deviceId,
    );
    await save(entry);
    return entry;
  }

  /// Escritura atómica: archivo temporal y luego renombrar.
  Future<void> save(Entry entry) async {
    final target = File('${_entries.path}/${entry.id}.json');
    final tmp = File('${target.path}.tmp');
    await tmp.writeAsString(
      const JsonEncoder.withIndent('  ').convert(entry.toJson()),
      flush: true,
    );
    await tmp.rename(target.path);
  }

  Future<void> softDelete(Entry entry) =>
      save(entry.copyWith(deleted: true, deviceId: deviceId));
}