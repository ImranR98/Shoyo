import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:shoyo/models/save_task.dart';
import 'package:shoyo/pages/filename_editor_page.dart';
import 'package:shoyo/pages/settings_page.dart';
import 'package:shoyo/services/file_saver.dart';
import 'package:shoyo/services/media_store_service.dart';
import 'package:shoyo/services/settings_controller.dart';
import 'package:shoyo/services/sharing_service.dart';
import 'package:shoyo/utils/file_naming.dart';
import 'package:shoyo/widgets/result_tile.dart';
import 'package:shoyo/widgets/settings_hint_card.dart';

enum _HomeState { idle, saving, done }

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.settings,
    this.sharing,
    this.fileSaver,
  });

  final SettingsController settings;
  final SharingService? sharing;
  final FileSaver? fileSaver;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final SharingService _sharing =
      widget.sharing ?? FlutterSharingService();
  late final FileSaver _fileSaver =
      widget.fileSaver ?? FileSaver(MediaStoreService());

  StreamSubscription<List<SharedFile>>? _subscription;
  _HomeState _state = _HomeState.idle;
  List<SaveTask> _tasks = const [];
  String? _lastSignature;
  DateTime? _lastHandledAt;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _subscription = _sharing.stream.listen(_handleSharedFiles);
    _sharing.initial().then((files) {
      if (files.isNotEmpty) _handleSharedFiles(files);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _handleSharedFiles(List<SharedFile> sharedFiles) async {
    if (_busy) return;
    _busy = true;
    try {
      await _processSharedFiles(sharedFiles);
    } finally {
      _busy = false;
    }
  }

  Future<void> _processSharedFiles(List<SharedFile> sharedFiles) async {
    var tasks = sharedFiles
        .map(SaveTask.fromSharedFile)
        .whereType<SaveTask>()
        .toList();
    if (tasks.isEmpty) return;

    final signature = tasks.map((task) => task.sourcePath).join('|');
    final now = DateTime.now();
    if (signature == _lastSignature &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!) < const Duration(seconds: 3)) {
      return;
    }
    _lastSignature = signature;
    _lastHandledAt = now;
    await _sharing.reset();

    final existing = await _fileSaver.knownTakenNames(tasks);
    if (!mounted) return;

    final settings = widget.settings;
    final conflicted = _conflictedTasks(tasks, existing);

    if (settings.promptForFilenames) {
      _prefillConflicts(tasks, existing);
      final edited = await _pushEditor(tasks, existing);
      if (!mounted) return;
      if (edited == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Save cancelled')));
        return;
      }
      tasks = edited;
    } else if (conflicted.isNotEmpty && !settings.autoRenameOnConflict) {
      _prefillConflicts(conflicted, existing);
      final edited = await _pushEditor(conflicted, existing);
      if (!mounted) return;
      if (edited == null) {
        for (final task in conflicted) {
          task.name = task.originalName;
          task.status = SaveStatus.skipped;
        }
      }
    }

    setState(() {
      _tasks = tasks;
      _state = _HomeState.saving;
    });

    final toSave = tasks
        .where((task) => task.status != SaveStatus.skipped)
        .toList();
    await _fileSaver.save(
      toSave,
      autoRename: !settings.promptForFilenames && settings.autoRenameOnConflict,
      knownTaken: existing,
      onProgress: () {
        if (mounted) setState(() {});
      },
    );
    if (!mounted) return;
    setState(() => _state = _HomeState.done);
  }

  Future<List<SaveTask>?> _pushEditor(
    List<SaveTask> tasks,
    Set<String> existing,
  ) {
    return Navigator.of(context).push<List<SaveTask>>(
      MaterialPageRoute(
        builder: (context) =>
            FilenameEditorPage(tasks: tasks, existingNames: existing),
      ),
    );
  }

  List<SaveTask> _conflictedTasks(List<SaveTask> tasks, Set<String> existing) {
    final seen = <String>{...existing};
    final conflicted = <SaveTask>[];
    for (final task in tasks) {
      final name = task.name.toLowerCase();
      if (seen.contains(name)) {
        conflicted.add(task);
      } else {
        seen.add(name);
      }
    }
    return conflicted;
  }

  void _prefillConflicts(List<SaveTask> tasks, Set<String> existing) {
    final taken = <String>{...existing};
    for (final task in tasks) {
      if (taken.contains(task.name.toLowerCase())) {
        task.name = FileNaming.uniqueName(task.name, taken);
      }
      taken.add(task.name.toLowerCase());
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsPage(settings: widget.settings),
      ),
    );
  }

  void _clearResults() {
    setState(() {
      _tasks = const [];
      _state = _HomeState.idle;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (context, _) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar.large(
                title: const Text('Shoyo'),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Badge(
                      isLabelVisible: !widget.settings.hasVisitedSettings,
                      child: IconButton(
                        tooltip: 'Settings',
                        onPressed: _openSettings,
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              ..._buildContent(context),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildContent(BuildContext context) {
    switch (_state) {
      case _HomeState.idle:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _IdleView(
              showSettingsHint: !widget.settings.hasVisitedSettings,
              onOpenSettings: _openSettings,
            ),
          ),
        ];
      case _HomeState.saving:
        return [
          SliverToBoxAdapter(child: _SavingHeader(tasks: _tasks)),
          _buildTaskList(),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ];
      case _HomeState.done:
        return [
          SliverToBoxAdapter(
            child: _ResultsHeader(tasks: _tasks, onDone: _clearResults),
          ),
          _buildTaskList(),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ];
    }
  }

  Widget _buildTaskList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.separated(
        itemCount: _tasks.length,
        itemBuilder: (context, index) => ResultTile(task: _tasks[index]),
        separatorBuilder: (context, index) => const SizedBox(height: 8),
      ),
    );
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({
    required this.showSettingsHint,
    required this.onOpenSettings,
  });

  final bool showSettingsHint;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: scheme.primaryContainer,
            child: Icon(
              Icons.ios_share,
              size: 44,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nothing saved yet',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Share files from any app to save them to your Downloads folder.',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          if (showSettingsHint) ...[
            const SizedBox(height: 32),
            SettingsHintCard(onOpenSettings: onOpenSettings),
          ],
        ],
      ),
    );
  }
}

class _SavingHeader extends StatelessWidget {
  const _SavingHeader({required this.tasks});

  final List<SaveTask> tasks;

  @override
  Widget build(BuildContext context) {
    final finished = tasks
        .where(
          (task) =>
              task.status != SaveStatus.pending &&
              task.status != SaveStatus.saving,
        )
        .length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: 16),
          Text(
            'Saving $finished of ${tasks.length}…',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.tasks, required this.onDone});

  final List<SaveTask> tasks;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final saved = tasks.where((task) => task.status == SaveStatus.saved).length;
    final failed = tasks
        .where((task) => task.status == SaveStatus.failed)
        .length;
    final allSaved = saved == tasks.length;

    final Color background;
    final Color foreground;
    final IconData icon;
    if (allSaved) {
      background = scheme.primaryContainer;
      foreground = scheme.onPrimaryContainer;
      icon = Icons.check_circle_outline;
    } else if (failed > 0) {
      background = scheme.errorContainer;
      foreground = scheme.onErrorContainer;
      icon = Icons.error_outline;
    } else {
      background = scheme.surfaceContainerHighest;
      foreground = scheme.onSurfaceVariant;
      icon = Icons.remove_circle_outline;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Card.filled(
        color: background,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
          child: Row(
            children: [
              Icon(icon, color: foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  allSaved
                      ? '${tasks.length} file${tasks.length == 1 ? '' : 's'} saved'
                      : '$saved of ${tasks.length} files saved',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: foreground),
                ),
              ),
              TextButton(onPressed: onDone, child: const Text('Done')),
            ],
          ),
        ),
      ),
    );
  }
}
