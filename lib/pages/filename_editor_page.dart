import 'package:flutter/material.dart';
import 'package:shoyo/models/save_task.dart';
import 'package:shoyo/utils/file_naming.dart';

class FilenameEditorPage extends StatefulWidget {
  const FilenameEditorPage({
    super.key,
    required this.tasks,
    required this.existingNames,
  });

  final List<SaveTask> tasks;

  /// Lowercase names that already exist in Downloads.
  final Set<String> existingNames;

  @override
  State<FilenameEditorPage> createState() => _FilenameEditorPageState();
}

class _FilenameEditorPageState extends State<FilenameEditorPage> {
  late final List<TextEditingController> _controllers = widget.tasks
      .map((task) => TextEditingController(text: task.name))
      .toList();
  late final Set<int> _conflictedAtOpen = _findConflictedAtOpen();

  Set<int> _findConflictedAtOpen() {
    final seen = <String>{...widget.existingNames};
    final conflicted = <int>{};
    for (var i = 0; i < widget.tasks.length; i++) {
      final original = widget.tasks[i].originalName.toLowerCase();
      if (seen.contains(original)) conflicted.add(i);
      seen.add(original);
    }
    return conflicted;
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _currentName(int index) => _controllers[index].text.trim();

  bool _isConflict(int index) {
    final name = _currentName(index).toLowerCase();
    if (name.isEmpty) return false;
    if (widget.existingNames.contains(name)) return true;
    for (var i = 0; i < _controllers.length; i++) {
      if (i != index && _currentName(i).toLowerCase() == name) {
        return true;
      }
    }
    return false;
  }

  bool get _hasBlockingIssue {
    for (var i = 0; i < _controllers.length; i++) {
      if (_errorFor(i) != null || _isConflict(i)) return true;
    }
    return false;
  }

  String _suggestionFor(int index) {
    final taken = <String>{...widget.existingNames};
    for (var i = 0; i < _controllers.length; i++) {
      if (i == index) continue;
      final name = _currentName(i);
      if (name.isNotEmpty) taken.add(name.toLowerCase());
    }
    return FileNaming.uniqueName(_currentName(index), taken);
  }

  String? _errorFor(int index) => FileNaming.validate(_controllers[index].text);

  String? _helperFor(int index) {
    if (_errorFor(index) != null) return null;
    if (_conflictedAtOpen.contains(index)) {
      return 'Original "${widget.tasks[index].originalName}" already exists';
    }
    if (_isConflict(index)) return 'This name is already taken';
    final originalName = widget.tasks[index].originalName;
    if (_currentName(index) != originalName) {
      return 'Original: $originalName';
    }
    return null;
  }

  void _submit() {
    for (var i = 0; i < _controllers.length; i++) {
      final error = _errorFor(i);
      if (error != null) {
        setState(() {});
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
        return;
      }
    }
    for (var i = 0; i < _controllers.length; i++) {
      widget.tasks[i].name = _currentName(i);
    }
    Navigator.of(context).pop(widget.tasks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: const Text('Review file names')),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList.separated(
              itemCount: widget.tasks.length,
              itemBuilder: (context, index) => _buildField(context, index),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.icon(
          onPressed: _hasBlockingIssue ? null : _submit,
          icon: const Icon(Icons.download_done_outlined),
          label: Text(
            'Save ${widget.tasks.length} '
            'file${widget.tasks.length == 1 ? '' : 's'}',
          ),
        ),
      ),
    );
  }

  Widget _buildField(BuildContext context, int index) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _controllers[index],
              maxLines: 1,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'File name',
                helperText: _helperFor(index),
                helperMaxLines: 2,
                errorText: _errorFor(index),
                errorMaxLines: 2,
                suffixIcon: _isConflict(index)
                    ? IconButton(
                        tooltip: 'Use a suggested name',
                        icon: const Icon(Icons.auto_fix_high_outlined),
                        onPressed: () => setState(
                          () =>
                              _controllers[index].text = _suggestionFor(index),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
