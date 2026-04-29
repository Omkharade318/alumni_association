import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'package:share_plus/share_plus.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/full_screen_image_viewer.dart';
import '../widgets/app_app_bar.dart';
import 'alumini_details_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostDialog(context),
        backgroundColor: AppTheme.primaryRed,
        child: const Icon(Icons.add, color: Colors.white),
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
                  const Icon(Icons.post_add, size: 64, color: AppTheme.textLight),
                  const SizedBox(height: 16),
                  const Text('No posts yet', style: TextStyle(color: AppTheme.textGray)),
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
    List<File> selectedImages = [];
    bool isPosting = false; // Added to handle inline loading state

    // Fetch user outside to ensure we have them ready
    final user = context.read<AuthProvider>().currentUser;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Allows custom rounded container
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor, // Adapts to light/dark mode
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Modern Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Create Post', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Clean, borderless text input
                TextField(
                  controller: contentController,
                  maxLines: null, // Allows field to grow vertically as user types
                  minLines: 3,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'What\'s on your mind?',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                    border: InputBorder.none, // Removes the harsh outline box
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 16),

                // Polished Image Previews
                if (selectedImages.isNotEmpty) ...[
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: selectedImages.length,
                      itemBuilder: (_, i) => Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(selectedImages[i], width: 120, height: 120, fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 18,
                            child: GestureDetector(
                              onTap: () => setModalState(() => selectedImages.removeAt(i)),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Bottom Action Bar
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryRed, size: 28),
                      onPressed: isPosting ? null : () async {
                        final picker = ImagePicker();
                        final images = await picker.pickMultiImage();
                        if (images.isNotEmpty) {
                          setModalState(() {
                            selectedImages.addAll(images.map((e) => File(e.path)));
                          });
                        }
                      },
                    ),
                    const Spacer(),

                    // Modern Pill-shaped Post Button with inline loading
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: (isPosting || (contentController.text.trim().isEmpty && selectedImages.isEmpty))
                          ? null
                          : () async {
                        if (user == null) return;

                        // Trigger inline loading state
                        setModalState(() => isPosting = true);

                        try {
                          List<String> imageUrls = [];
                          if (selectedImages.isNotEmpty) {
                            for (var image in selectedImages) {
                              final url = await StorageService().uploadPostImage(user.uid, image);
                              imageUrls.add(url);
                            }
                          }

                          final post = PostModel(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            userId: user.uid,
                            userName: user.name,
                            userImage: user.profileImage,
                            userJobTitle: user.jobTitle,
                            userDegree: user.degree,
                            userBranch: user.branch,
                            userBatch: user.batch,
                            content: contentController.text.trim(),
                            imageUrls: imageUrls,
                            createdAt: DateTime.now(),
                          );

                          await FirestoreService().createPost(post);

                          if (context.mounted) {
                            Navigator.pop(ctx); // Just pop the modal, no loading dialog to dismiss!
                          }
                        } catch (e) {
                          if (context.mounted) {
                            setModalState(() => isPosting = false); // Stop loading on error
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post: $e')));
                          }
                        }
                      },
                      child: isPosting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                          : const Text('Post', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
              ],
            ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () async {
              final firestore = FirestoreService();
              final targetUser = await firestore.getUser(post.userId);
              if (targetUser != null && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AlumniDetailScreen(alumni: targetUser)),
                );
              }
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileAvatar(imageUrl: post.userImage, name: post.userName, size: 50),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Row(
                        children: [
                          if (post.userJobTitle != null)
                            Text(
                              post.userJobTitle!,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
                            ),
                          Text(
                            ' ${post.userDegree ?? "Alumni"}${post.userBranch != null ? "(${post.userBranch})" : ""} ${post.userBatch ?? ""}',
                            style: const TextStyle(fontSize: 10, color: AppTheme.textGray),
                          ),
                        ],
                      ),
                      Text(
                        _formatDate(post.createdAt),
                        style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            post.content,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          if (post.imageUrls != null && post.imageUrls!.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenImageViewer(
                      imageUrl: post.imageUrls![0],
                      tag: 'post_${post.id}',
                    ),
                  ),
                );
              },
              child: Hero(
                tag: 'post_${post.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post.imageUrls![0],
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: AppTheme.dividerGray,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (post.likes.isNotEmpty) ...[
                const Icon(Icons.thumb_up, size: 14, color: AppTheme.primaryRed),
                const SizedBox(width: 4),
                Text(
                  '${post.likes.length}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
                ),
                const SizedBox(width: 12),
              ],
              if (post.commentCount > 0)
                Text(
                  '${post.commentCount} comments',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppTheme.dividerGray),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActionButton(
                icon: isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                label: 'Like',
                color: isLiked ? AppTheme.primaryRed : AppTheme.textDark,
                onPressed: user == null
                    ? null
                    : () => firestore.likePost(post.id, user.uid, isLiked),
              ),
              _ActionButton(
                icon: Icons.chat_bubble_outline,
                label: 'Comment',
                onPressed: () => _showComments(context, post),
              ),
              _ActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                onPressed: () {
                  Share.share(
                    '${post.userName} posted on Alumni Connect: \n\n${post.content}',
                    subject: 'Check out this post from ${post.userName}',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showComments(BuildContext context, PostModel post) {
    final commentController = TextEditingController();
    final user = context.read<AuthProvider>().currentUser;
    final firestore = FirestoreService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Comments (${post.commentCount})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<List<CommentModel>>(
                stream: firestore.getCommentsStream(post.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final comments = snapshot.data!;
                  if (comments.isEmpty) {
                    return const Center(
                      child: Text('No comments yet. Be the first to comment!'),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: comments.length,
                    itemBuilder: (_, i) {
                      final comment = comments[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final firestore = FirestoreService();
                                final targetUser = await firestore.getUser(comment.userId);
                                if (targetUser != null && context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => AlumniDetailScreen(alumni: targetUser)),
                                  );
                                }
                              },
                              child: ProfileAvatar(
                                imageUrl: comment.userImage,
                                name: comment.userName,
                                size: 36,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          final firestore = FirestoreService();
                                          final targetUser = await firestore.getUser(comment.userId);
                                          if (targetUser != null && context.mounted) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => AlumniDetailScreen(alumni: targetUser)),
                                            );
                                          }
                                        },
                                        child: Text(
                                          comment.userName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatDate(comment.createdAt),
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    comment.content,
                                    style: const TextStyle(fontSize: 14),
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
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: const TextStyle(color: AppTheme.textGray),
                        filled: true,
                        fillColor: AppTheme.dividerGray.withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppTheme.primaryRed),
                    onPressed: () async {
                      if (commentController.text.trim().isEmpty || user == null) return;
                      
                      final content = commentController.text.trim();
                      commentController.clear();

                      final comment = CommentModel(
                        id: '',
                        userId: user.uid,
                        userName: user.name,
                        userImage: user.profileImage,
                        content: content,
                        createdAt: DateTime.now(),
                      );

                      await firestore.createComment(post.id, comment);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color ?? AppTheme.textDark),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color ?? AppTheme.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
