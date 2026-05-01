import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../widgets/app_app_bar.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: const AppAppBar(title: 'Notifications', showBack: true),
        body: const Center(child: Text('Please sign in to view notifications')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Modern off-white background
      appBar: const AppAppBar(title: 'Notifications', showBack: true),
      body: _NotificationsList(userId: user.uid),
    );
  }
}

class _NotificationsList extends StatelessWidget {
  final String userId;

  const _NotificationsList({required this.userId});

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) return DateFormat('MMM dd').format(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  // Helper to dynamically style icons based on the notification type
  _NotificationStyle _getStyleForType(NotificationType type) {
    switch (type) {
      case NotificationType.event:
        return _NotificationStyle(
          icon: Icons.event_rounded,
          iconColor: Colors.blue.shade700,
          backgroundColor: Colors.blue.shade50,
        );
      case NotificationType.donation:
        return _NotificationStyle(
          icon: Icons.volunteer_activism_rounded,
          iconColor: Colors.green.shade700,
          backgroundColor: Colors.green.shade50,
        );
      case NotificationType.message:
        return _NotificationStyle(
          icon: Icons.chat_bubble_rounded,
          iconColor: Colors.purple.shade700,
          backgroundColor: Colors.purple.shade50,
        );
      case NotificationType.connectionRequest:
        return _NotificationStyle(
          icon: Icons.person_add_rounded,
          iconColor: Colors.orange.shade700,
          backgroundColor: Colors.orange.shade50,
        );
      case NotificationType.job:
        return _NotificationStyle(
          icon: Icons.work_rounded,
          iconColor: Colors.teal.shade700,
          backgroundColor: Colors.teal.shade50,
        );
      default:
        return _NotificationStyle(
          icon: Icons.notifications_rounded,
          iconColor: AppTheme.primaryRed,
          backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NotificationModel>>(
      stream: NotificationService().getNotificationsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red.shade400)));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final notifications = snapshot.data!;

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ]),
                  child: Icon(Icons.notifications_off_rounded, size: 64, color: Colors.grey.shade300),
                ),
                const SizedBox(height: 24),
                const Text('All caught up!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                Text('You have no new notifications.', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: notifications.length,
          itemBuilder: (_, i) {
            final n = notifications[i];
            final style = _getStyleForType(n.type);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => NotificationService().handleNotificationClick(context, n),
                  highlightColor: Colors.grey.shade50,
                  splashColor: Colors.grey.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dynamic Contextual Icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: style.backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(style.icon, size: 24, color: style.iconColor),
                        ),
                        const SizedBox(width: 16),

                        // Notification Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTimeAgo(n.createdAt),
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                n.body,
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.3),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Simple data class to hold the styling logic for different notification types
class _NotificationStyle {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  _NotificationStyle({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });
}