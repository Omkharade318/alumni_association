import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/post_model.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/app_app_bar.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Feed',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showCreatePostDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<PostModel>>(
        stream: FirestoreService().getPostsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data!;
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.post_add, size: 64, color: AppTheme.textLight),
                  const SizedBox(height: 16),
                  Text('No posts yet', style: TextStyle(color: AppTheme.textGray)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _showCreatePostDialog(context),
                    child: const Text('Create first post'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (_, i) => _PostCard(post: posts[i]),
          );
        },
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context) {
    final contentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Create Post', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'What\'s on your mind?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final user = context.read<AuthProvider>().currentUser;
                  if (user == null || contentController.text.trim().isEmpty) return;
                  final post = PostModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    userId: user.uid,
                    userName: user.name,
                    userImage: user.profileImage,
                    content: contentController.text.trim(),
                    createdAt: DateTime.now(),
                  );
                  await FirestoreService().createPost(post);
                  if (context.mounted) Navigator.pop(ctx);
                },
                child: const Text('Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final PostModel post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isLiked = user != null && post.isLikedBy(user.uid);
    final firestore = FirestoreService();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileAvatar(imageUrl: post.userImage, name: post.userName, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.userName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      _formatDate(post.createdAt),
                      style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(post.content),
          if (post.imageUrls != null && post.imageUrls!.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: post.imageUrls!.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(post.imageUrls![i], width: 200, height: 200, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : AppTheme.textGray),
                onPressed: user == null
                    ? null
                    : () => firestore.likePost(post.id, user.uid, isLiked),
              ),
              Text('${post.likes.length}'),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.comment_outlined, color: AppTheme.textGray),
                onPressed: () => _showComments(context, post),
              ),
              Text('${post.commentCount}'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: AppTheme.textGray),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showComments(BuildContext context, PostModel post) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Comments (${post.commentCount})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Comments will appear here when users comment.'),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
