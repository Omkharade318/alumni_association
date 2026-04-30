import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/time_utils.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/app_app_bar.dart';
import 'chat_screen.dart';

class MessagingScreen extends StatelessWidget {
  final bool hideAppBar;
  const MessagingScreen({super.key, this.hideAppBar = false});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in'));
    }

    Widget body = Container(
      color: Colors.grey.shade50, // Soft modern off-white background
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 22),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),
          ),

          // Divider below search
          Container(height: 1, color: Colors.grey.shade200),

          // Chat List
          Expanded(
            child: StreamBuilder<List<DocumentSnapshot>>(
              stream: FirestoreService().getConversationsStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!;

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Icon(Icons.forum_rounded, size: 56, color: Colors.grey.shade400),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No messages yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade800, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Connect with alumni to start chatting.',
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final participants = data['participants'] as List<dynamic>? ?? [];
                    final otherId = participants.firstWhere((p) => p != user.uid, orElse: () => '');

                    return StreamBuilder<UserModel?>(
                      stream: FirestoreService().getUserStream(otherId.toString()),
                      builder: (ctx, userSnap) {
                        if (!userSnap.hasData) {
                          return const SizedBox(height: 84); // Prevents UI jumping
                        }

                        final other = userSnap.data;
                        if (other == null) return const SizedBox.shrink();

                        final lastMessage = data['lastMessage'] as String? ?? 'Sent an attachment';

                        // Extract timestamp & unread counts
                        final timestamp = data['lastMessageAt'] as Timestamp?;
                        final timeString = timestamp != null
                            ? TimeUtils.formatTimestamp(timestamp.toDate())
                            : '';

                        final unreadCounts = data['unreadCounts'] as Map<String, dynamic>? ?? {};
                        final unreadCount = unreadCounts[user.uid] ?? 0;

                        return _ChatTile(
                          user: other,
                          lastMessage: lastMessage,
                          timeString: timeString,
                          unreadCount: unreadCount,
                          isOnline: i % 3 == 0, // Mock online status
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                conversationId: docs[i].id,
                                otherUser: other,
                                currentUserId: user.uid,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );

    if (hideAppBar) return body;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppAppBar(title: 'Messages', showBack: true),
      body: body,
    );
  }
}

// Custom Premium Chat Tile (Card Style)
class _ChatTile extends StatelessWidget {
  final UserModel user;
  final String lastMessage;
  final String timeString;
  final int unreadCount;
  final bool isOnline;
  final VoidCallback onTap;

  const _ChatTile({
    required this.user,
    required this.lastMessage,
    required this.timeString,
    this.unreadCount = 0,
    this.isOnline = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasUnread = unreadCount > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), // Diffused, premium shadow
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          highlightColor: Colors.grey.shade50,
          splashColor: Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with Online Status Indicator
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: ProfileAvatar(imageUrl: user.profileImage, name: user.name, size: 56),
                    ),
                    if (isOnline)
                      Positioned(
                        bottom: 0,
                        right: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green.shade500,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),

                // Message Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              user.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                                color: Colors.black87,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            timeString,
                            style: TextStyle(
                              fontSize: 12,
                              color: hasUnread ? AppTheme.primaryRed : Colors.grey.shade500,
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessage,
                              style: TextStyle(
                                fontSize: 14,
                                color: hasUnread ? Colors.black87 : Colors.grey.shade600,
                                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Modern Pill Unread Badge
                          if (hasUnread) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: const ShapeDecoration(
                                color: AppTheme.primaryRed,
                                shape: StadiumBorder(),
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
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
  }
}