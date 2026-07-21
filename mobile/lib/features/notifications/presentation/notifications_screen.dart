import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/glass_card.dart';
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
        loading: () => const AppLoadingView(),
        error: (error, _) => AppErrorView(message: 'Failed to load notifications: $error'),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const AppEmptyView(
              icon: Icons.notifications_none_outlined,
              message: 'No new alerts or warnings.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _NotificationTile(
                notification: notif,
                onTap: () => _markAsRead(ref, notif.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final NotificationEntity notification;
  final VoidCallback onTap;

  (IconData, Color) get _style => switch (notification.type) {
        'disaster' => (Icons.warning_amber, AppColors.emergencyRed),
        'crime' => (Icons.policy, AppColors.emergencyOrange),
        'traffic' => (Icons.traffic, AppColors.warningAmber),
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
