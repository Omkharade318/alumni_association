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
import 'alumini_details_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Modern off-white background
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostDialog(context),
        backgroundColor: AppTheme.primaryRed,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.edit_square, color: Colors.white),
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
                    child: Icon(Icons.post_add_rounded, size: 64, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 24),
                  const Text('No posts yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text('Be the first to share an update!', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => _showCreatePostDialog(context),
                    child: const Text('Create Post', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }
          return MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Extra bottom padding for FAB
              itemCount: posts.length,
              itemBuilder: (_, i) => _PostCard(post: posts[i]),
            ),
          );
        },
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context) {
    final contentController = TextEditingController();
    List<File> selectedImages = [];
    bool isPosting = false;

    final user = context.read<AuthProvider>().currentUser;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Create Post', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  maxLines: null,
                  minLines: 3,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(fontSize: 16, height: 1.4),
                  decoration: const InputDecoration(
                    hintText: 'What do you want to talk about?',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 16),
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
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.image_outlined, color: AppTheme.primaryRed, size: 28),
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
                          if (context.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          if (context.mounted) {
                            setModalState(() => isPosting = false);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post: $e')));
                          }
                        }
                      },
                      child: isPosting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          GestureDetector(
            onTap: () async {
              final targetUser = await firestore.getUser(post.userId);
              if (targetUser != null && context.mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AlumniDetailScreen(alumni: targetUser)));
              }
            },
            child: StreamBuilder<UserModel?>(
              stream: firestore.getUserStream(post.userId),
              builder: (context, userSnapshot) {
                final liveUser = userSnapshot.data;
                final displayName = liveUser?.name ?? post.userName;
                final displayImage = liveUser?.profileImage ?? post.userImage;

                final String subtitleDetails = [
                  liveUser?.jobTitle ?? post.userJobTitle,
                  liveUser?.degree ?? post.userDegree ?? "Alumni",
                  liveUser?.branch ?? post.userBranch,
                  liveUser?.batch ?? post.userBatch,
                ].where((e) => e != null && e.isNotEmpty).join(' • ');

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfileAvatar(imageUrl: displayImage, name: displayName, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  displayName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                _formatDate(post.createdAt),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitleDetails,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Post Content
          Text(
            post.content,
            style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
          ),

          // Image Attachments
          if (post.imageUrls != null && post.imageUrls!.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenImageViewer(imageUrl: post.imageUrls![0], tag: 'post_${post.id}'),
                  ),
                );
              },
              child: Hero(
                tag: 'post_${post.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    post.imageUrls![0],
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: Colors.grey.shade100,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Engagement Stats
          if (post.likes.isNotEmpty || post.commentCount > 0) ...[
            Row(
              children: [
                if (post.likes.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppTheme.primaryRed, shape: BoxShape.circle),
                    child: const Icon(Icons.thumb_up_rounded, size: 10, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  Text('${post.likes.length}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
                const Spacer(),
                if (post.commentCount > 0)
                  Text('${post.commentCount} comments', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 12),
          ],

          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 4),

          // Modern Action Bar (Horizontal layout)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ActionButton(
                icon: isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                label: 'Like',
                color: isLiked ? AppTheme.primaryRed : Colors.grey.shade700,
                onPressed: user == null ? null : () => firestore.likePost(post.id, user.uid, isLiked),
              ),
              _ActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Comment',
                color: Colors.grey.shade700,
                onPressed: () => _showComments(context, post),
              ),
              _ActionButton(
                icon: Icons.share_rounded,
                label: 'Share',
                color: Colors.grey.shade700,
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
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Comments (${post.commentCount})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                      child: Icon(Icons.close_rounded, size: 20, color: Colors.grey.shade700),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.black12),
            Expanded(
              child: StreamBuilder<List<CommentModel>>(
                stream: firestore.getCommentsStream(post.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final comments = snapshot.data!;
                  if (comments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('No comments yet.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Start the conversation!', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: comments.length,
                    itemBuilder: (_, i) {
                      final comment = comments[i];
                      final isCommentAuthor = user?.uid == comment.userId;
                      final isPostAuthor = user?.uid == post.userId;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final targetUser = await firestore.getUser(comment.userId);
                                if (targetUser != null && context.mounted) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => AlumniDetailScreen(alumni: targetUser)));
                                }
                              },
                              child: ProfileAvatar(imageUrl: comment.userImage, name: comment.userName, size: 40),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Bubble Style Comment
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              comment.userName,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                            ),
                                            if (isCommentAuthor || isPostAuthor)
                                              _buildCommentOptions(context, post, comment, isCommentAuthor),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          comment.content,
                                          style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Text(
                                      _formatDate(comment.createdAt),
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                                    ),
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
            SafeArea(
              child: Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom > 0 ? MediaQuery.of(ctx).viewInsets.bottom + 12 : 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 10),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: commentController,
                          maxLines: 4,
                          minLines: 1,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            hintText: 'Write a comment...',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: const BoxDecoration(color: AppTheme.primaryRed, shape: BoxShape.circle),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        onPressed: () async {
                          if (commentController.text.trim().isEmpty || user == null) return;

                          final content = commentController.text.trim();
                          commentController.clear();
                          FocusScope.of(context).unfocus();

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
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentOptions(BuildContext context, PostModel post, CommentModel comment, bool canEdit) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: const Icon(Icons.more_horiz, size: 18, color: Colors.grey),
      onSelected: (value) {
        if (value == 'edit') {
          _showEditCommentDialog(context, post, comment);
        } else if (value == 'delete') {
          _showDeleteCommentDialog(context, post, comment);
        }
      },
      itemBuilder: (ctx) => [
        if (canEdit)
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    );
  }

  void _showEditCommentDialog(BuildContext context, PostModel post, CommentModel comment) {
    final controller = TextEditingController(text: comment.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: controller,
          maxLines: null,
          decoration: const InputDecoration(hintText: 'Enter comment...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty) {
                await FirestoreService().updateComment(post.id, comment.id, newContent);
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCommentDialog(BuildContext context, PostModel post, CommentModel comment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirestoreService().deleteComment(post.id, comment.id);
              if (context.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays > 7) {
      return '${d.day}/${d.month}/${d.year}';
    }
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}

// Modern horizontal action button
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}