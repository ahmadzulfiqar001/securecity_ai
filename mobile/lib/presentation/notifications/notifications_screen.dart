import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/notification_model.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final List<NotificationModel> _notifications = [
    NotificationModel(
      id: '1',
      title: 'Extreme Rainfall & Flood Alert',
      body: 'Gulshan-e-Iqbal block 13 experiencing high flood risks. Shift to higher ground if needed.',
      type: 'disaster',
      timestamp: '5 mins ago',
      isRead: false,
      payload: {},
    ),
    NotificationModel(
      id: '2',
      title: 'Armed Robbery Warning',
      body: 'Incident of street crime reported near Nipa Flyover. Stay alert and avoid the area.',
      type: 'crime',
      timestamp: '20 mins ago',
      isRead: false,
      payload: {},
    ),
    NotificationModel(
      id: '3',
      title: 'Road Blockage Update',
      body: 'M.A. Jinnah road closed due to construction. Use alternative routes to avoid delays.',
      type: 'traffic',
      timestamp: '1 hour ago',
      isRead: true,
      payload: {},
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  void _markAsRead(int index) {
    setState(() {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'City Safety Alerts',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: AppColors.accentCyan),
            tooltip: 'Mark all as read',
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? const Center(
              child: Text(
                'No new alerts or warnings.',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notif = _notifications[index];
                
                Color typeColor = AppColors.accentCyan;
                IconData typeIcon = Icons.notifications;
                
                if (notif.type == 'disaster') {
                  typeColor = AppColors.emergencyRed;
                  typeIcon = Icons.warning_amber;
                } else if (notif.type == 'crime') {
                  typeColor = Colors.orange;
                  typeIcon = Icons.policy;
                } else if (notif.type == 'traffic') {
                  typeColor = Colors.amber;
                  typeIcon = Icons.traffic;
                }

                return GestureDetector(
                  onTap: () => _markAsRead(index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: notif.isRead
                          ? AppColors.darkCard.withOpacity(0.5)
                          : AppColors.darkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: notif.isRead
                            ? Colors.white.withOpacity(0.02)
                            : typeColor.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Indicator dot for unread
                        if (!notif.isRead)
                          Container(
                            margin: const EdgeInsets.only(top: 6, right: 12),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: typeColor,
                            ),
                          ),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: typeColor.withOpacity(0.1),
                          child: Icon(typeIcon, color: typeColor, size: 20),
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
                                      notif.title,
                                      style: TextStyle(
                                        color: notif.isRead ? Colors.white70 : Colors.white,
                                        fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    notif.timestamp,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.3),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notif.body,
                                style: TextStyle(
                                  color: notif.isRead ? Colors.white38 : Colors.white60,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
