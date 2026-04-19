import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/app_app_bar.dart';

class MessagingScreen extends StatelessWidget {
  const MessagingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Please sign in')));

    return Scaffold(
      appBar: AppAppBar(title: 'Messages', showBack: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search messages',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirestoreService().getConversationsStream(user.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('No conversations yet'));
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final participants = data['participants'] as List<dynamic>? ?? [];
                    final otherId = participants.firstWhere((p) => p != user.uid, orElse: () => '');
                    return FutureBuilder<UserModel?>(
                      future: FirestoreService().getUser(otherId.toString()),
                      builder: (ctx, userSnap) {
                        if (!userSnap.hasData) return const SizedBox.shrink();
                        final other = userSnap.data!;
                        return ListTile(
                          leading: ProfileAvatar(imageUrl: other.profileImage, name: other.name, size: 48),
                          title: Text(other.name),
                          subtitle: Text(data['lastMessage'] ?? 'No messages yet'),
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
  }
}

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final UserModel otherUser;
  final String currentUserId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUser,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final FirestoreService _firestore = FirestoreService();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    _firestore.sendMessage(
      widget.conversationId,
      MessageModel(
        id: '',
        senderId: widget.currentUserId,
        receiverId: widget.otherUser.uid,
        content: content,
        createdAt: DateTime.now(),
      ),
    );
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: AppTheme.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            ProfileAvatar(imageUrl: widget.otherUser.profileImage, name: widget.otherUser.name, size: 36),
            const SizedBox(width: 12),
            Text(widget.otherUser.name),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _firestore.getMessagesStream(widget.conversationId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final m = messages[messages.length - 1 - i];
                    final isMe = m.senderId == widget.currentUserId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.primaryRed : AppTheme.dividerGray,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          m.content,
                          style: TextStyle(color: isMe ? AppTheme.white : AppTheme.textDark),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: AppTheme.primaryRed),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
