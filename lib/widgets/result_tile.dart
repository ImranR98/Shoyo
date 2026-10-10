import 'package:flutter/material.dart';
import 'package:shoyo/models/save_task.dart';
import 'package:shoyo/widgets/file_icon.dart';

class ResultTile extends StatelessWidget {
  const ResultTile({super.key, required this.task});

  final SaveTask task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      tileColor: scheme.surfaceContainerLow,
      leading: Icon(fileIconFor(task), color: scheme.onSurfaceVariant),
      title: Text(
        task.savedName ?? task.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: _subtitle(context),
      trailing: _trailing(scheme, textTheme),
    );
  }

  Widget? _subtitle(BuildContext context) {
    if (task.status == SaveStatus.skipped) {
      return const Text('Not saved');
    }
    if (task.error != null) {
      return Text(
        task.error!,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }
    if (task.savedName != null && task.savedName != task.originalName) {
      return Text(
        'Originally "${task.originalName}"',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return null;
  }

  Widget? _trailing(ColorScheme scheme, TextTheme textTheme) {
    return switch (task.status) {
      SaveStatus.pending => Icon(
        Icons.schedule_outlined,
        color: scheme.onSurfaceVariant,
      ),
      SaveStatus.saving => const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
      SaveStatus.saved => Icon(Icons.check_circle, color: scheme.primary),
      SaveStatus.skipped => Icon(
        Icons.remove_circle_outline,
        color: scheme.onSurfaceVariant,
      ),
      SaveStatus.failed => Icon(Icons.error_outline, color: scheme.error),
    };
  }
}
