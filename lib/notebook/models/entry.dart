import 'dart:math';

enum EntryType { snippet, note, photo }

/// Un elemento del cuaderno. Se identifica por [id], nunca por título.
class Entry {
  Entry({
    required this.id,
    required this.type,
    required this.title,
    this.body = '',
    this.language,
    this.tags = const [],
    this.attachment,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    this.deleted = false,
  });

  final String id;
  final EntryType type;
  final String title;
  final String body;

  /// Para snippets: powershell, docker, bash...
  final String? language;
  final List<String> tags;

  /// Nombre de archivo de la foto dentro de la carpeta de adjuntos.
  final String? attachment;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Dispositivo que hizo el último cambio.
  final String deviceId;

  /// Borrado lógico: permite sincronizar borrados sin perder datos.
  final bool deleted;

  /// UUID v4 sin dependencias externas.
  static String newId() {
    final r = Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
    return '${h(0)}${h(1)}${h(2)}${h(3)}-${h(4)}${h(5)}-${h(6)}${h(7)}-'
        '${h(8)}${h(9)}-${h(10)}${h(11)}${h(12)}${h(13)}${h(14)}${h(15)}';
  }

  Entry copyWith({
    String? title,
    String? body,
    String? language,
    List<String>? tags,
    String? attachment,
    DateTime? updatedAt,
    String? deviceId,
    bool? deleted,
  }) =>
      Entry(
        id: id,
        type: type,
        title: title ?? this.title,
        body: body ?? this.body,
        language: language ?? this.language,
        tags: tags ?? this.tags,
        attachment: attachment ?? this.attachment,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now().toUtc(),
        deviceId: deviceId ?? this.deviceId,
        deleted: deleted ?? this.deleted,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'language': language,
        'tags': tags,
        'attachment': attachment,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'deviceId': deviceId,
        'deleted': deleted,
      };

  factory Entry.fromJson(Map<String, Object?> j) => Entry(
        id: j['id'] as String,
        type: EntryType.values.byName(j['type'] as String),
        title: j['title'] as String,
        body: (j['body'] as String?) ?? '',
        language: j['language'] as String?,
        tags: ((j['tags'] as List?) ?? const []).cast<String>(),
        attachment: j['attachment'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        deviceId: j['deviceId'] as String,
        deleted: (j['deleted'] as bool?) ?? false,
      );
}