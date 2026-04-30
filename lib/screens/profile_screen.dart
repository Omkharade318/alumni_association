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
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Upload failed: $e'),
                behavior: SnackBarBehavior.floating,
              )
          );
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

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign out?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Modern off-white background
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.currentUser;
          if (user == null) return const Center(child: Text('Please sign in'));

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Section
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (user.profileImage != null && user.profileImage!.isNotEmpty) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: InteractiveViewer(
                                    clipBehavior: Clip.none,
                                    child: Container(
                                      width: MediaQuery.of(context).size.width,
                                      height: MediaQuery.of(context).size.width,
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Image.network(
                                        user.profileImage!,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const Center(child: CircularProgressIndicator(color: Colors.white));
                                        },
                                        errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.broken_image, color: Colors.white, size: 50),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: ProfileAvatar(imageUrl: user.profileImage, name: user.name, size: 120),
                        ),
                      ),

                      // Upload Progress Overlay
                      if (_isUploading)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
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

                      // Edit Button
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _pickAndUploadImage(context, auth),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryRed, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Center(
                  child: Text(
                    user.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    user.jobTitle ?? 'Alumni',
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 32),

                // Sections
                _buildSectionTitle('Contact Information'),
                _buildModernCard([
                  _ProfileInfoRow(icon: Icons.email_outlined, title: 'Email Address', value: user.email),
                  const _Divider(),
                  if (user.phone != null && user.phone!.isNotEmpty) ...[
                    _ProfileInfoRow(icon: Icons.phone_outlined, title: 'Phone Number', value: user.phone!),
                    const _Divider(),
                  ],
                  _ProfileInfoRow(icon: Icons.location_on_outlined, title: 'Location', value: user.displayLocation),
                ]),

                const SizedBox(height: 24),

                _buildSectionTitle('Academic Details'),
                _buildModernCard([
                  _ProfileInfoRow(icon: Icons.school_outlined, title: 'Branch', value: _formatValue(user.branch)),
                  const _Divider(),
                  _ProfileInfoRow(icon: Icons.history_edu_rounded, title: 'Batch', value: _formatValue(user.batch)),
                  const _Divider(),
                  _ProfileInfoRow(icon: Icons.workspace_premium_outlined, title: 'Degree', value: _formatValue(user.degree)),
                ]),

                const SizedBox(height: 24),

                _buildSectionTitle('Professional Profile'),
                _buildModernCard([
                  _ProfileInfoRow(icon: Icons.work_outline_rounded, title: 'Job Title', value: _formatValue(user.jobTitle)),
                  const _Divider(),
                  _ProfileInfoRow(icon: Icons.business_rounded, title: 'Company', value: _formatValue(user.company)),
                  const _Divider(),
                  if (user.createdAt != null)
                    _ProfileInfoRow(icon: Icons.calendar_today_rounded, title: 'Member Since', value: _formatDate(user.createdAt!)),
                ]),

                const SizedBox(height: 24),

                _buildSectionTitle('Recent Activity'),
                StreamBuilder<List<PostModel>>(
                  stream: FirestoreService().getPostsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                    final myPosts = snapshot.data!.where((p) => p.userId == user.uid).take(3).toList();

                    if (myPosts.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.post_add_rounded, size: 40, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('No recent activity', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      );
                    }
                    return Column(
                      children: myPosts.map((p) => _ActivityItem(post: p)).toList(),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Action Buttons
                _buildModernCard([
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.settings_outlined, color: Colors.grey.shade700, size: 22),
                    ),
                    title: const Text('Settings & Privacy', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  ),
                ]),

                const SizedBox(height: 16),

                // Sign Out Button
                InkWell(
                  onTap: () => _showSignOutDialog(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, color: Colors.red.shade600, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.red.shade600, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildModernCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 60, right: 16), // Aligns with text
      child: Divider(height: 1, color: Colors.grey.shade100),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dynamic_feed_rounded, size: 16, color: AppTheme.primaryRed.withOpacity(0.8)),
              const SizedBox(width: 8),
              Text(
                DateFormat('MMM dd, yyyy').format(post.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            post.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          ),
        ],
      ),
    );
  }
}