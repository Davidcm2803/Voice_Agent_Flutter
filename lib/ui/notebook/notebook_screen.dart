import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voice_agent_flutter/notebook/data/entry_store.dart';
import 'package:voice_agent_flutter/notebook/data/notebook_search.dart';
import 'package:voice_agent_flutter/notebook/models/entry.dart';
import 'package:voice_agent_flutter/ui/notebook/entry_editor_dialog.dart';
import 'package:voice_agent_flutter/ui/theme/app_colors.dart';
import 'package:voice_agent_flutter/ui/widgets/comic_panel.dart';
import 'package:voice_agent_flutter/ui/widgets/halftone_background.dart';

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
  bool _loading = true;
  Timer? _timer;

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
    });
  }

  Future<void> _add() async {
    final r = await showDialog<EntryEditorResult>(
      context: context,
      builder: (_) => const EntryEditorDialog(),
    );
    if (r == null) return;
    await _store!.create(
      type: EntryType.snippet,
      title: r.title,
      body: r.body,
      language: r.language,
      tags: r.language.isEmpty ? const [] : [r.language],
    );
    await _reload();
  }

  Future<void> _edit(Entry e) async {
    final r = await showDialog<EntryEditorResult>(
      context: context,
      builder: (_) => EntryEditorDialog(entry: e),
    );
    if (r == null) return;
    await _store!.save(e.copyWith(
      title: r.title,
      body: r.body,
      language: r.language,
      tags: r.language.isEmpty ? const [] : [r.language],
      deviceId: _store!.deviceId,
    ));
    await _reload();
  }

  Future<void> _delete(Entry e) async {
    await _store!.softDelete(e);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = NotebookSearch.search(_all, _query);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text('CUADERNO', style: theme.textTheme.titleLarge)),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.red,
        onPressed: _store == null ? null : _add,
        child: const Icon(Icons.add, color: AppColors.paper),
      ),
      body: HalftoneBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 64, 16, 0),
            child: Column(
              children: [
                ComicPanel(
                  shadowColor: AppColors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Buscar snippets, notas...',
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: AppColors.cyan),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _reload,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 90),
                            children: results.isEmpty
                                ? [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 80),
                                      child: Center(
                                        child: Text(
                                          'Nada por aquí. Pulsa + para guardar.',
                                          style: theme.textTheme.labelSmall,
                                        ),
                                      ),
                                    ),
                                  ]
                                : [
                                    for (final e in results)
                                      _EntryCard(
                                        entry: e,
                                        onTap: () => _edit(e),
                                        onDelete: () => _delete(e),
                                      ),
                                  ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  final Entry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: onTap,
        child: ComicPanel(
          shadowColor: AppColors.red,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${(entry.language ?? entry.type.name).toUpperCase()}  ·  ${entry.title}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copiar',
                    icon: const Icon(Icons.copy,
                        size: 18, color: AppColors.cyan),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: entry.body));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copiado')));
                    },
                  ),
                  IconButton(
                    tooltip: 'Borrar',
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: AppColors.muted),
                    onPressed: onDelete,
                  ),
                ],
              ),
              Text(
                entry.body,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}