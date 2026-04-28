import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/time_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium Search & Filter Row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search chats...',
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 22),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),

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
                            color: Colors.grey.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.forum_outlined, size: 64, color: Colors.grey.shade300),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No messages yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start a conversation with an alumni.',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final participants = data['participants'] as List<dynamic>? ?? [];
                    final otherId = participants.firstWhere((p) => p != user.uid, orElse: () => '');

                    return FutureBuilder<UserModel?>(
                      future: FirestoreService().getUser(otherId.toString()),
                      builder: (ctx, userSnap) {
                        if (!userSnap.hasData) {
                          return const SizedBox(height: 84); // Prevents UI jumping
                        }

                        final other = userSnap.data!;
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
                          // Optional: Mock online status based on some data, or hardcode true to see the UI
                          isOnline: i % 3 == 0,
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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), // Adds space around the card
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Rounded modern corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // Soft, modern shadow
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent, // Allows the container's white background to show through
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16), // Keeps the ripple effect inside the rounded corners
          highlightColor: Colors.grey.shade50,
          splashColor: Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.all(16), // Inner padding for the card contents
            child: Row(
              children: [
                // Avatar with Online Status Indicator
                Stack(
                  children: [
                    ProfileAvatar(imageUrl: user.profileImage, name: user.name, size: 56),
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
                                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
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
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
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
                                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Unread Badge
                          if (hasUnread) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryRed,
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.all(Radius.circular(10)),
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