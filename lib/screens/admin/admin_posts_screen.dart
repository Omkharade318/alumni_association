import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/post_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/profile_avatar.dart';
import 'admin_post_edit_screen.dart';

class AdminPostsScreen extends StatelessWidget {
  const AdminPostsScreen({super.key});

  Future<void> _confirmAndDelete(BuildContext context, PostModel post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Post?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'This will permanently delete the post by ${post.userName}. This action cannot be undone.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirestoreService().deletePost(post.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Post deleted successfully'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Modern off-white background
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manage Posts',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
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
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: Icon(Icons.dynamic_feed_rounded, size: 64, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 24),
                  const Text('No posts found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text('User posts will appear here for moderation.', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return _AdminPostCard(
                post: post,
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminPostEditScreen(post: post),
                    ),
                  );
                },
                onDelete: () => _confirmAndDelete(context, post),
              );
            },
          );
        },
      ),
    );
  }
}

class _AdminPostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdminPostCard({
    required this.post,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Header
            Row(
              children: [
                ProfileAvatar(imageUrl: post.userImage, name: post.userName, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy • h:mm a').format(post.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Post Content
            Text(
              post.content,
              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),

            // Attached Image Indicator (if applicable)
            if (post.imageUrls != null && post.imageUrls!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image_outlined, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      '${post.imageUrls!.length} Attached Image(s)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Colors.black12),
            ),

            // Bottom Action Bar
            Row(
              children: [
                // Stats
                Icon(Icons.favorite_rounded, size: 16, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text('${post.likes.length}', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(width: 16),
                Icon(Icons.chat_bubble_rounded, size: 16, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text('${post.commentCount ?? 0}', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 13)),

                const Spacer(),

                // Moderation Actions
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.edit_rounded, size: 18, color: Colors.grey.shade700),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.delete_rounded, size: 18, color: Colors.red.shade600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}