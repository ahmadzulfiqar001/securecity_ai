import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/motion.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/cards/glass_card.dart';
import '../domain/entities/notification_entity.dart';
import 'providers/notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAllAsRead(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;
    await ref.read(notificationsRepositoryProvider).markAllAsRead(uid);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    }
  }

  Future<void> _markAsRead(WidgetRef ref, String notificationId) async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;
    await ref.read(notificationsRepositoryProvider).markAsRead(uid, notificationId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final enabledCategories = ref.read(storageServiceProvider).getEnabledNotificationCategories();

    return Scaffold(
      appBar: AppBar(
        title: const Text('City Safety Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: AppColors.accentCyan),
            tooltip: 'Mark all as read',
            onPressed: () => _markAllAsRead(context, ref),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const SkeletonListLoader(),
        error: (error, _) => ErrorState(
          message: "Couldn't load your notifications right now.",
          onRetry: () => ref.invalidate(notificationsStreamProvider),
        ),
        data: (notifications) {
          // Categories the user turned off in Settings > Notification
          // Categories are hidden here rather than un-fetched - there's no
          // server-side delivery to filter (see NotificationsRepository),
          // so this is a client-side feed filter, not a push subscription.
          final visible = notifications
              .where((n) => !AppConstants.notificationCategoryKeys.contains(n.type) || enabledCategories.contains(n.type))
              .toList();

          if (visible.isEmpty) {
            return EmptyState(
              icon: Icons.notifications_none_outlined,
              message: notifications.isEmpty
                  ? 'No new alerts or warnings.'
                  : 'Nothing to show - all your enabled categories are caught up. Check Settings > Notification Categories.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: visible.length,
            itemBuilder: (context, index) {
              final notif = visible[index];
              return _NotificationTile(
                notification: notif,
                onTap: () => _markAsRead(ref, notif.id),
              );
            },
          ).animate().fadeIn(duration: motionDuration(context, AppDurations.pageTransition)).slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final NotificationEntity notification;
  final VoidCallback onTap;

  // Kept in sync with AlertItem's mapping (features/home) - both features
  // share the same category taxonomy, see AppConstants.notificationCategoryKeys.
  (IconData, Color) get _style => switch (notification.type) {
        'flood' => (Icons.tsunami, AppColors.infoBlue),
        'crime' => (Icons.local_police, AppColors.emergencyOrange),
        'traffic' => (Icons.traffic, AppColors.warningAmber),
        'weather' => (Icons.cloud_outlined, AppColors.accentCyan),
        'emergency' => (Icons.sos_outlined, AppColors.emergencyRed),
        _ => (Icons.notifications, AppColors.accentCyan),
      };

  String get _relativeTime {
    final diff = DateTime.now().difference(notification.createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min${diff.inMinutes == 1 ? '' : 's'} ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _style;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: '${notification.isRead ? 'Read' : 'Unread'} notification: ${notification.title}',
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!notification.isRead)
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 12),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                ),
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(_relativeTime, style: textTheme.labelSmall),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(notification.body, style: textTheme.bodySmall),
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
