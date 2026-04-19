import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../models/post_model.dart';
import '../widgets/profile_avatar.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double _uploadProgress = 0.0;
  bool _isUploading = false;

  String _formatDate(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  String _formatValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Not specified';
    }
    return value.trim();
  }

  Future<void> _pickAndUploadImage(BuildContext context, AuthProvider auth) async {
    if (_isUploading) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);
    
    if (image != null && auth.currentUser != null) {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      try {
        final url = await StorageService().uploadProfileImage(
          auth.currentUser!.uid, 
          File(image.path),
          onProgress: (percent) {
            if (mounted) {
              setState(() {
                _uploadProgress = percent;
              });
            }
          },
        ).timeout(const Duration(minutes: 5));

        await auth.updateProfileImage(url);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
            _uploadProgress = 0.0;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.currentUser;
          if (user == null) return const Center(child: Text('Please sign in'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      ProfileAvatar(imageUrl: user.profileImage, name: user.name, size: 120),
                      if (_isUploading)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    value: _uploadProgress > 0 ? _uploadProgress : null,
                                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                                  ),
                                  if (_uploadProgress > 0) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '${(_uploadProgress * 100).toInt()}%',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _pickAndUploadImage(context, auth),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryRed,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: AppTheme.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    user.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                Center(
                  child: Text(
                    user.jobTitle ?? 'Alumni',
                    style: const TextStyle(fontSize: 16, color: AppTheme.textGray),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.dividerGray),
                  ),
                  child: Column(
                    children: [
                      _ProfileInfoRow(icon: Icons.email, title: 'Email', value: user.email),
                      if (user.phone != null && user.phone!.isNotEmpty) 
                        _ProfileInfoRow(icon: Icons.phone, title: 'Phone', value: user.phone!),
                      _ProfileInfoRow(icon: Icons.location_on, title: 'Location', value: user.displayLocation),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.dividerGray),
                  ),
                  child: Column(
                    children: [
                      _ProfileInfoRow(
                        icon: Icons.work, 
                        title: 'Experience', 
                        value: _formatValue(user.jobTitle) != 'Not specified' && _formatValue(user.company) != 'Not specified'
                            ? '${_formatValue(user.jobTitle)} at ${_formatValue(user.company)}'
                            : _formatValue(user.jobTitle) != 'Not specified'
                                ? _formatValue(user.jobTitle)
                                : _formatValue(user.company)
                      ),
                      _ProfileInfoRow(icon: Icons.school, title: 'Education', value: user.displayBranchBatch),
                      if (user.createdAt != null) _ProfileInfoRow(icon: Icons.calendar_today, title: 'Member Since', value: _formatDate(user.createdAt!)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                StreamBuilder<List<PostModel>>(
                  stream: FirestoreService().getPostsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
                    final myPosts = snapshot.data!.where((p) => p.userId == user.uid).take(5).toList();
                    if (myPosts.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No posts yet'));
                    return Column(
                      children: myPosts.map((p) => _ActivityItem(post: p)).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.settings, color: AppTheme.primaryRed),
                  title: const Text('General Settings'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showSignOutDialog(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryRed, side: const BorderSide(color: AppTheme.primaryRed)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryRed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textGray, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final PostModel post;
  const _ActivityItem({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Text(post.content, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}
