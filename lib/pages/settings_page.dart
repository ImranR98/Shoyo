import 'package:flutter/material.dart';
import 'package:shoyo/app.dart';
import 'package:shoyo/services/settings_controller.dart';
import 'package:shoyo/theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.settings});

  final SettingsController settings;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.settings.markSettingsVisited();
    });
  }

  Future<void> _pickThemeStyle() async {
    final selected = await showDialog<AppThemeStyle>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('App colours'),
        children: [
          for (final style in AppThemeStyle.values)
            ListTile(
              leading: Icon(_themeIcon(style)),
              title: Text(style.label),
              trailing: style == widget.settings.themeStyle
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () => Navigator.of(context).pop(style),
            ),
        ],
      ),
    );
    if (selected != null) {
      await widget.settings.setThemeStyle(selected);
    }
  }

  IconData _themeIcon(AppThemeStyle style) => switch (style) {
    AppThemeStyle.classic => Icons.palette_outlined,
    AppThemeStyle.expressive => Icons.auto_awesome_outlined,
    AppThemeStyle.system => Icons.wallpaper_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (context, _) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              const SliverAppBar.large(title: Text('Settings')),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList.list(
                  children: [
                    const _SectionHeader('Appearance'),
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading: const Icon(Icons.color_lens_outlined),
                        title: const Text('App colours'),
                        subtitle: Text(widget.settings.themeStyle.label),
                        onTap: _pickThemeStyle,
                      ),
                    ),
                    const _SectionHeader('File names'),
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: widget.settings.promptForFilenames,
                            onChanged: (value) =>
                                widget.settings.setPromptForFilenames(value),
                            secondary: const Icon(Icons.edit_outlined),
                            title: const Text('Review file names'),
                            subtitle: const Text(
                              'Show an editor for every share so you can '
                              'rename files before they are saved.',
                            ),
                          ),
                          const Divider(indent: 56, endIndent: 16),
                          SwitchListTile(
                            value: widget.settings.autoRenameOnConflict,
                            onChanged: (value) =>
                                widget.settings.setAutoRenameOnConflict(value),
                            secondary: const Icon(Icons.auto_fix_high_outlined),
                            title: const Text('Auto-rename name conflicts'),
                            subtitle: const Text(
                              'Add a number when a file with the same name '
                              'already exists in Downloads, like '
                              '"photo (1).jpg". When off, you are asked to '
                              'rename conflicting files yourself.',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const _SectionHeader('About'),
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: const ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('Shoyo'),
                        subtitle: Text('Version $kAppVersion'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
