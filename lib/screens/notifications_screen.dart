import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/notification_model.dart';
import '../widgets/app_app_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Please sign in')));

    return Scaffold(
      appBar: AppAppBar(title: 'Notifications', showBack: true),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryRed,
            unselectedLabelColor: AppTheme.textGray,
            tabs: const [Tab(text: 'All'), Tab(text: 'Unread')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _NotificationsList(userId: user.uid, unreadOnly: false),
                _NotificationsList(userId: user.uid, unreadOnly: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsList extends StatelessWidget {
  final String userId;
  final bool unreadOnly;

  const _NotificationsList({required this.userId, required this.unreadOnly});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NotificationModel>>(
      stream: FirestoreService().getNotificationsStream(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var notifications = snapshot.data!;
        if (unreadOnly) notifications = notifications.where((n) => !n.isRead).toList();
        if (notifications.isEmpty) return const Center(child: Text('No notifications'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (_, i) {
            final n = notifications[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: n.isRead ? AppTheme.white : AppTheme.primaryRed.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.dividerGray),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!n.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: const BoxDecoration(color: AppTheme.primaryRed, shape: BoxShape.circle),
                    ),
                  if (!n.isRead) const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(n.body, style: const TextStyle(fontSize: 14, color: AppTheme.textGray)),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, h:mm a').format(n.createdAt),
                          style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
