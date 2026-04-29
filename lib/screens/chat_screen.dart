import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/time_utils.dart';
import '../config/theme.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../widgets/profile_avatar.dart';
import 'alumini_details_screen.dart';

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
  bool _isTyping = false; // Used to animate/toggle the send button

  @override
  void initState() {
    super.initState();
    _markAsRead();

    // Listen to text changes to toggle the send button state
    _messageController.addListener(() {
      setState(() {
        _isTyping = _messageController.text.trim().isNotEmpty;
      });
    });
  }

  void _markAsRead() {
    _firestore.markMessagesAsRead(widget.conversationId, widget.currentUserId);
  }

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
        id: '', // Will be set by Firestore
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
      backgroundColor: Colors.grey.shade50, // Softer background for contrast
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AlumniDetailScreen(alumni: widget.otherUser)),
          ),
          child: Row(
            children: [
              ProfileAvatar(imageUrl: widget.otherUser.profileImage, name: widget.otherUser.name, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.otherUser.name,
                      style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.otherUser.jobTitle ?? 'Alumni', // Subtitle context
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.normal),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {}, // Add options like "View Profile" or "Block"
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat Messages List
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _firestore.getMessagesStream(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  _markAsRead(); // Mark read when new messages stream in
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Say hi to ${widget.otherUser.name.split(' ').first}! 👋',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  reverse: true, // Auto-scrolls to the bottom
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final m = messages[i];
                    final isMe = m.senderId == widget.currentUserId;
                    final timeString = DateFormat('h:mm a').format(m.createdAt);

                    // Date Header Logic
                    bool showDateHeader = false;
                    if (i == messages.length - 1) {
                      showDateHeader = true;
                    } else {
                      final prevMessage = messages[i + 1];
                      if (m.createdAt.day != prevMessage.createdAt.day ||
                          m.createdAt.month != prevMessage.createdAt.month ||
                          m.createdAt.year != prevMessage.createdAt.year) {
                        showDateHeader = true;
                      }
                    }

                    return Column(
                      children: [
                        if (showDateHeader) _buildDateHeader(m.createdAt),
                        _buildMessageBubble(m.content, isMe, timeString),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Modern Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attachment Button
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: Colors.grey.shade500, size: 28),
                    onPressed: () {}, // TODO: Handle image/file attachments
                  ),
                  const SizedBox(width: 4),

                  // Text Input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: 5,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send Button
                  Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: _isTyping ? AppTheme.primaryRed : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _isTyping ? _sendMessage : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to build the date header (e.g., Today, Yesterday, or Date)
  Widget _buildDateHeader(DateTime dateTime) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        TimeUtils.formatChatDate(dateTime),
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Helper widget to build the chat bubbles with tails
  Widget _buildMessageBubble(String content, bool isMe, String timeString) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75, // Prevents full-width bubbles
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryRed : Colors.white,
          border: isMe ? null : Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            // The "tail" effect:
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeString,
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey.shade500,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}