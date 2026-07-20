import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../auth/access_restricted_screen.dart';
import '../widgets/app_state_view.dart';
import '../widgets/command_palette.dart';
import '../widgets/sidebar_nav_item.dart';
import 'nav_items.dart';

/// Persistent shell (sidebar + top bar) wrapping every protected route via
/// `ShellRoute`. Also owns the role gate: while `currentRoleProvider` is
/// loading, shows a spinner; if the signed-in user isn't an authority role,
/// shows [AccessRestrictedScreen] instead of the shell.
class DashboardShell extends ConsumerWidget {
  const DashboardShell({super.key, required this.currentLocation, required this.child});

  final String currentLocation;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(currentRoleProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: roleAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, _) => AppErrorView(message: 'Failed to verify your role: $error'),
        data: (role) {
          if (role == null || !AppConstants.authorityRoles.contains(role)) {
            return const AccessRestrictedScreen();
          }
          return _ShellLayout(role: role, currentLocation: currentLocation, child: child);
        },
      ),
    );
  }
}

class _ShellLayout extends ConsumerStatefulWidget {
  const _ShellLayout({required this.role, required this.currentLocation, required this.child});

  final String role;
  final String currentLocation;
  final Widget child;

  @override
  ConsumerState<_ShellLayout> createState() => _ShellLayoutState();
}

class _ShellLayoutState extends ConsumerState<_ShellLayout> {
  bool _collapsed = false;

  void _openCommandPalette() {
    showCommandPalette(
      context,
      onSignOut: () => ref.read(firebaseAuthProvider).signOut(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < AppConstants.responsiveBreakpoint;
    final collapsed = _collapsed || isNarrow;
    final currentLocation = widget.currentLocation;

    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK): _openCommandPalette,
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK): _openCommandPalette,
      },
      child: Focus(
        autofocus: true,
        child: Row(
          children: [
            AnimatedContainer(
              duration: AppDurations.fast,
              width: collapsed ? AppConstants.sidebarCollapsedWidth : AppConstants.sidebarWidth,
              decoration: const BoxDecoration(
                color: AppColors.darkSurface,
                border: Border(right: BorderSide(color: AppColors.darkBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment:
                          collapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                      children: [
                        if (!collapsed)
                          const Expanded(
                            child: Text(
                              AppConstants.appName,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                color: AppColors.darkTextPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        if (!isNarrow)
                          IconButton(
                            icon: Icon(
                              collapsed ? Icons.chevron_right : Icons.chevron_left,
                              color: AppColors.darkTextSecondary,
                            ),
                            onPressed: () => setState(() => _collapsed = !_collapsed),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        for (var i = 0; i < kDashboardNavItems.length; i++)
                          SidebarNavItem(
                            item: kDashboardNavItems[i],
                            collapsed: collapsed,
                            selected: currentLocation == kDashboardNavItems[i].route,
                            onTap: () => context.go(kDashboardNavItems[i].route),
                          )
                              .animate(delay: (i * 30).ms)
                              .fadeIn(duration: AppDurations.fast)
                              .slideX(begin: -0.1, end: 0, duration: AppDurations.fast),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(role: widget.role, onOpenCommandPalette: _openCommandPalette),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.role, required this.onOpenCommandPalette});

  final String role;
  final VoidCallback onOpenCommandPalette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).value;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.darkBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onOpenCommandPalette,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.glassWhite10,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                constraints: const BoxConstraints(maxWidth: 360),
                child: Row(
                  children: const [
                    Icon(Icons.search, size: 18, color: AppColors.darkTextSecondary),
                    SizedBox(width: 10),
                    Text('Search…', style: TextStyle(color: AppColors.darkTextSecondary)),
                    Spacer(),
                    _KeyHint(label: 'Ctrl'),
                    SizedBox(width: 4),
                    _KeyHint(label: 'K'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.glassCyan10,
            child: Text(
              (user?.email?.isNotEmpty ?? false) ? user!.email![0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user?.email ?? 'Authority',
                style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 13),
              ),
              Text(role, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeyHint extends StatelessWidget {
  const _KeyHint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.darkCardElevated,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 10)),
    );
  }
}
