import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voice_agent_flutter/notebook/data/entry_store.dart';
import 'package:voice_agent_flutter/notebook/data/notebook_search.dart';
import 'package:voice_agent_flutter/notebook/models/entry.dart';
import 'package:voice_agent_flutter/ui/notebook/entry_editor_dialog.dart';
import 'package:voice_agent_flutter/ui/notebook/import_flow.dart';
import 'package:voice_agent_flutter/ui/theme/app_colors.dart';
import 'package:voice_agent_flutter/ui/widgets/comic_panel.dart';
import 'package:voice_agent_flutter/ui/widgets/halftone_background.dart';

enum _Filter { all, code, notes, photos }

class NotebookScreen extends StatefulWidget {
  const NotebookScreen({super.key});

  @override
  State<NotebookScreen> createState() => _NotebookScreenState();
}

class _NotebookScreenState extends State<NotebookScreen>
    with WidgetsBindingObserver {
  EntryStore? _store;
  List<Entry> _all = [];
  String _query = '';
  _Filter _filter = _Filter.all;
  int _tab = 0;
  bool _loading = true;
  Timer? _timer;
  final Set<String> _selected = {};

  bool get _selecting => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  Future<void> _init() async {
    _store = await EntryStore.open();
    if (!mounted) return;
    await _reload();
    // Syncthing puede traer cambios desde otros dispositivos.
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _reload());
  }

  Future<void> _reload() async {
    final store = _store;
    if (store == null) return;
    final all = await store.loadAll();
    if (!mounted) return;
    setState(() {
      _all = all;
      _loading = false;
      _selected.removeWhere((id) => !all.any((e) => e.id == id));
    });
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------- Acciones

  Future<void> _add(EntryType type) async {
    final r = await showDialog<EntryEditorResult>(
      context: context,
      builder: (_) => EntryEditorDialog(type: type),
    );
    if (r == null) return;
    try {
      await _store!.create(
        type: type,
        title: r.title,
        body: r.body,
        language: r.language.isEmpty ? null : r.language,
        tags: r.tags,
      );
      await _reload();
      _toast('Fuente guardada');
    } catch (e) {
      _toast('No se pudo guardar: $e');
    }
  }

  Future<void> _edit(Entry e) async {
    final r = await showDialog<EntryEditorResult>(
      context: context,
      builder: (_) => EntryEditorDialog(entry: e),
    );
    if (r == null) return;
    try {
      await _store!.save(e.copyWith(
        title: r.title,
        body: r.body,
        language: r.language.isEmpty ? null : r.language,
        tags: r.tags,
        deviceId: _store!.deviceId,
      ));
      await _reload();
      _toast('Cambios guardados');
    } catch (err) {
      _toast('No se pudo guardar: $err');
    }
  }

  Future<bool> _confirm(String text) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('BORRAR'),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _delete(Entry e) async {
    if (!await _confirm('¿Borrar "${e.title}"?')) return;
    await _store!.softDelete(e);
    await _reload();
    _toast('Borrado');
  }

  Future<void> _deleteSelected() async {
    final items = _all.where((e) => _selected.contains(e.id)).toList();
    if (items.isEmpty) return;
    if (!await _confirm('¿Borrar ${items.length} fuente(s)?')) return;
    for (final e in items) {
      await _store!.softDelete(e);
    }
    setState(_selected.clear);
    await _reload();
    _toast('Borradas ${items.length}');
  }

  void _copy(Entry e) {
    Clipboard.setData(ClipboardData(text: e.body));
    _toast('Copiado');
  }

  void _toggleSelect(Entry e) {
    setState(() {
      if (!_selected.remove(e.id)) _selected.add(e.id);
    });
  }

  Future<void> _importDocument() async {
    final store = _store;
    if (store == null) return;
    final msg = await ImportFlow.document(context, store);
    if (!mounted) return;
    await _reload();
    if (msg != null) _toast(msg);
  }

  Future<void> _importPhoto() async {
    final store = _store;
    if (store == null) return;
    final msg = await ImportFlow.photo(context, store);
    if (!mounted) return;
    await _reload();
    if (msg != null) _toast(msg);
  }

  bool _studyReady(String name) =>
      name == 'Resumen' || name == 'Preguntas de estudio';

  /// Elige una fuente y devuelve el pedido al chat (que responde con el RAG).
  Future<void> _studioAction(String name) async {
    if (!_studyReady(name)) {
      _toast('$name: próximamente');
      return;
    }
    final sources = _all
        .where((e) => e.body.trim().isNotEmpty && e.type != EntryType.photo)
        .toList();
    if (sources.isEmpty) {
      _toast('Agregá una fuente primero');
      return;
    }
    final chosen = await showModalBottomSheet<Entry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.panel,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('ELEGÍ UNA FUENTE',
                    style: TextStyle(
                        fontWeight: FontWeight.w900, letterSpacing: 2)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final e in sources)
                      ListTile(
                        leading: Icon(_icon(e.type), color: AppColors.cyan),
                        title: Text(e.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${e.body.length} caracteres'),
                        onTap: () => Navigator.of(ctx).pop(e),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    final prompt = name == 'Resumen'
        ? 'Hazme un resumen de «${chosen.title}» del cuaderno.'
        : 'Hazme 5 preguntas de estudio con su respuesta sobre «${chosen.title}» del cuaderno.';
    Navigator.of(context).pop(prompt);
  }

  void _showAddMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panel,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('AGREGAR FUENTE',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, letterSpacing: 2)),
            ),
            ListTile(
              leading: const Icon(Icons.code, color: AppColors.cyan),
              title: const Text('Snippet de código'),
              subtitle: const Text('Docker, PowerShell, bash...'),
              onTap: () {
                Navigator.of(ctx).pop();
                _add(EntryType.snippet);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sticky_note_2_outlined,
                  color: AppColors.cyan),
              title: const Text('Nota'),
              subtitle: const Text('Texto libre'),
              onTap: () {
                Navigator.of(ctx).pop();
                _add(EntryType.note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined,
                  color: AppColors.cyan),
              title: const Text('Documento'),
              subtitle: const Text('Word, PDF o texto'),
              onTap: () {
                Navigator.of(ctx).pop();
                _importDocument();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined, color: AppColors.cyan),
              title: const Text('Foto'),
              subtitle: const Text('Con descripción para que Axel la encuentre'),
              onTap: () {
                Navigator.of(ctx).pop();
                _importPhoto();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openDetail(Entry e) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.panel,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_label(e), style: theme.textTheme.labelSmall),
                const SizedBox(height: 4),
                Text(e.title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('Actualizado ${_date(e.updatedAt)}',
                    style: theme.textTheme.labelSmall),
                if (e.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _TagRow(tags: e.tags),
                ],
                const SizedBox(height: 12),
                if (e.type == EntryType.photo && e.attachment != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File('${_store!.attachments.path}/${e.attachment}'),
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => const SizedBox(
                        height: 60,
                        child: Center(child: Text('(no encuentro la imagen)')),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Flexible(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        e.body.isEmpty
                            ? '(vacío)'
                            : e.body.length > 20000
                                ? '${e.body.substring(0, 20000)}\n\n... (${e.body.length} caracteres en total; COPIAR copia todo)'
                                : e.body,
                        style: TextStyle(
                          fontFamily:
                              e.type == EntryType.snippet ? 'monospace' : null,
                          fontSize: 14,
                          height: 1.4,
                          color: AppColors.paper,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () => _copy(e),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('COPIAR'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _edit(e);
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('EDITAR'),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Borrar',
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.red),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _delete(e);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Utilidades

  static String _label(Entry e) => switch (e.type) {
        EntryType.snippet => (e.language ?? 'snippet').toUpperCase(),
        EntryType.note => 'NOTA',
        EntryType.photo => 'FOTO',
      };

  static IconData _icon(EntryType t) => switch (t) {
        EntryType.snippet => Icons.code,
        EntryType.note => Icons.sticky_note_2_outlined,
        EntryType.photo => Icons.photo_outlined,
      };

  static String _date(DateTime d) {
    final l = d.toLocal();
    return '${l.day}/${l.month}/${l.year}';
  }

  List<Entry> _visible() {
    final found = NotebookSearch.search(_all, _query, limit: 1000);
    return found.where((e) {
      switch (_filter) {
        case _Filter.all:
          return true;
        case _Filter.code:
          return e.type == EntryType.snippet;
        case _Filter.notes:
          return e.type == EntryType.note;
        case _Filter.photos:
          return e.type == EntryType.photo;
      }
    }).toList();
  }

  // ---------- Pestañas

  Widget _sourcesTab() {
    final theme = Theme.of(context);
    final results = _visible();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        children: [
          ComicPanel(
            shadowColor: AppColors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Buscar en tus fuentes...',
                border: InputBorder.none,
                icon: Icon(Icons.search, color: AppColors.cyan),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final f in _Filter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(switch (f) {
                        _Filter.all => 'Todo',
                        _Filter.code => 'Código',
                        _Filter.notes => 'Notas',
                        _Filter.photos => 'Fotos',
                      }),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${results.length} FUENTE(S)',
              style: theme.textTheme.labelSmall,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _reload,
                    child: results.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 80),
                                child: Column(
                                  children: [
                                    const Icon(Icons.auto_stories,
                                        size: 48, color: AppColors.muted),
                                    const SizedBox(height: 12),
                                    Text(
                                      _all.isEmpty
                                          ? 'Tu cuaderno está vacío.\nAgregá tu primera fuente con +'
                                          : 'No hay resultados.',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 96),
                            itemCount: results.length,
                            itemBuilder: (_, i) {
                              final e = results[i];
                              return _SourceCard(
                                entry: e,
                                label: _label(e),
                                icon: _icon(e.type),
                                date: _date(e.updatedAt),
                                selected: _selected.contains(e.id),
                                onTap: () => _selecting
                                    ? _toggleSelect(e)
                                    : _openDetail(e),
                                onLongPress: () => _toggleSelect(e),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _studioTab() {
    final theme = Theme.of(context);
    const tools = [
      (Icons.summarize_outlined, 'Resumen', 'Un repaso corto de tus fuentes'),
      (Icons.quiz_outlined, 'Preguntas de estudio',
          'Para repasar tus notas'),
      (Icons.list_alt, 'Índice de snippets', 'Todo tu código por tema'),
      (Icons.hub_outlined, 'Mapa de etiquetas', 'Cómo se conectan tus fuentes'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final t in tools)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: GestureDetector(
              onTap: () => _studioAction(t.$2),
              child: ComicPanel(
                shadowColor: AppColors.red,
                child: Row(
                  children: [
                    Icon(t.$1, color: AppColors.cyan, size: 30),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.$2.toUpperCase(),
                              style: theme.textTheme.labelSmall),
                          const SizedBox(height: 2),
                          Text(t.$3, style: theme.textTheme.bodyLarge),
                        ],
                      ),
                    ),
                    Text(_studyReady(t.$2) ? 'LISTO' : 'PRONTO', style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selecting) setState(_selected.clear);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          leading: _selecting
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(_selected.clear),
                )
              : null,
          title: Text(
            _selecting ? '${_selected.length} SELECCIONADA(S)' : 'CUADERNO',
            style: theme.textTheme.titleLarge,
          ),
          actions: [
            if (_selecting)
              IconButton(
                tooltip: 'Borrar seleccionadas',
                icon: const Icon(Icons.delete_outline, color: AppColors.red),
                onPressed: _deleteSelected,
              ),
          ],
        ),
        floatingActionButton: _tab == 0 && !_selecting
            ? FloatingActionButton.extended(
                backgroundColor: AppColors.red,
                foregroundColor: AppColors.paper,
                onPressed: _store == null ? null : _showAddMenu,
                icon: const Icon(Icons.add),
                label: const Text('AGREGAR'),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          backgroundColor: AppColors.night,
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() {
            _tab = i;
            _selected.clear();
          }),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.library_books_outlined),
                selectedIcon: Icon(Icons.library_books),
                label: 'Fuentes'),
            NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome),
                label: 'Studio'),
          ],
        ),
        body: HalftoneBackground(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 56),
              child: IndexedStack(
                index: _tab,
                children: [_sourcesTab(), _studioTab()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final t in tags)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cyan, width: 1),
            ),
            child: Text(
              t,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.paper,
              ),
            ),
          ),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.entry,
    required this.label,
    required this.icon,
    required this.date,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final Entry entry;
  final String label;
  final IconData icon;
  final String date;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCode = entry.type == EntryType.snippet;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: ComicPanel(
          color: selected ? AppColors.blue : AppColors.panel,
          shadowColor: selected ? AppColors.cyan : AppColors.red,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected ? Icons.check_circle : icon,
                color: AppColors.cyan,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$label  ·  $date', style: theme.textTheme.labelSmall),
                    const SizedBox(height: 2),
                    Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (entry.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        entry.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: isCode ? 'monospace' : null,
                          fontSize: 13,
                          color: AppColors.paper.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                    if (entry.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _TagRow(tags: entry.tags.take(4).toList()),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}