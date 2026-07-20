import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../shell/nav_items.dart';
import 'glass_card.dart';

/// Opens the `Ctrl+K`/`Cmd+K` command palette — a filter-as-you-type list
/// over the 12 dashboard modules plus quick actions, keyboard-navigable,
/// closes on Esc.
Future<void> showCommandPalette(BuildContext context, {required VoidCallback onSignOut}) {
  return showGeneralDialog(
    context: context,
    barrierLabel: 'Command Palette',
    barrierColor: Colors.black54,
    barrierDismissible: true,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: const Alignment(0, -0.4),
        child: _CommandPalette(onSignOut: onSignOut),
      );
    },
  );
}

class _CommandPaletteEntry {
  const _CommandPaletteEntry({required this.label, required this.icon, required this.onSelect});

  final String label;
  final IconData icon;
  final VoidCallback onSelect;
}

class _CommandPalette extends StatefulWidget {
  const _CommandPalette({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  State<_CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<_CommandPalette> {
  final _controller = TextEditingController();
  int _highlighted = 0;
  late List<_CommandPaletteEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = _buildEntries('');
    _controller.addListener(() {
      setState(() {
        _entries = _buildEntries(_controller.text);
        _highlighted = 0;
      });
    });
  }

  List<_CommandPaletteEntry> _buildEntries(String query) {
    final navEntries = kDashboardNavItems.map(
      (item) => _CommandPaletteEntry(
        label: item.label,
        icon: item.icon,
        onSelect: () {
          Navigator.of(context).pop();
          context.go(item.route);
        },
      ),
    );

    final actionEntries = [
      _CommandPaletteEntry(
        label: 'Sign Out',
        icon: Icons.logout,
        onSelect: () {
          Navigator.of(context).pop();
          widget.onSignOut();
        },
      ),
    ];

    final all = [...navEntries, ...actionEntries];
    if (query.trim().isEmpty) return all;
    final lower = query.toLowerCase();
    return all.where((e) => e.label.toLowerCase().contains(lower)).toList();
  }

  void _moveHighlight(int delta) {
    if (_entries.isEmpty) return;
    setState(() => _highlighted = (_highlighted + delta) % _entries.length);
    if (_highlighted < 0) setState(() => _highlighted += _entries.length);
  }

  void _activateHighlighted() {
    if (_entries.isEmpty) return;
    _entries[_highlighted].onSelect();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingGlassPanel(
      width: 560,
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _moveHighlight(1);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _moveHighlight(-1);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _activateHighlighted();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _controller,
                autofocus: true,
                style: const TextStyle(color: AppColors.darkTextPrimary),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Jump to a module or action…',
                  prefixIcon: Icon(Icons.search, color: AppColors.darkTextSecondary),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.darkDivider),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: _entries.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No matches', style: TextStyle(color: AppColors.darkTextSecondary)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        final isHighlighted = index == _highlighted;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isHighlighted ? AppColors.glassCyan10 : AppColors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: Icon(entry.icon, size: 18, color: AppColors.accentCyan),
                            title: Text(
                              entry.label,
                              style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 14),
                            ),
                            onTap: entry.onSelect,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
