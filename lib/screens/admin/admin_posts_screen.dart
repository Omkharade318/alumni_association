import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/post_model.dart';
import '../../services/firestore_service.dart';
import 'admin_post_edit_screen.dart';

class AdminPostsScreen extends StatelessWidget {
  const AdminPostsScreen({super.key});

  Future<void> _confirmAndDelete(BuildContext context, PostModel post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
        content: Text('This will permanently delete “${post.content.substring(0, post.content.length.clamp(0, 80))}”.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await FirestoreService().deletePost(post.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Posts'),
        backgroundColor: AppTheme.primaryRed,
      ),
      body: StreamBuilder<List<PostModel>>(
        stream: FirestoreService().getPostsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final posts = snapshot.data!;
          if (posts.isEmpty) return const Center(child: Text('No posts found'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminPostEditScreen(post: post),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit_outlined),
                            color: AppTheme.primaryRed,
                          ),
                          IconButton(
                            onPressed: () => _confirmAndDelete(context, post),
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red,
                          ),
                          const Spacer(),
                          Text('${post.likes.length} likes', style: const TextStyle(color: AppTheme.textGray)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

