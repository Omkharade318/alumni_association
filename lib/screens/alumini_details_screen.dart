import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/app_app_bar.dart';
import 'chat_screen.dart';
import 'edit_profile_screen.dart';

class AlumniDetailScreen extends StatelessWidget {
  final UserModel alumni;

  const AlumniDetailScreen({super.key, required this.alumni});

  String _formatProfessionalDetails() {
    final hasCompany = alumni.company != null && alumni.company!.isNotEmpty;
    final hasTitle = alumni.jobTitle != null && alumni.jobTitle!.isNotEmpty;
    if (hasCompany && hasTitle) return '${alumni.jobTitle} at ${alumni.company}';
    if (hasCompany) return alumni.company!;
    if (hasTitle) return alumni.jobTitle!;
    return 'Professional details not specified';
  }

  String _formatAcademicDetails() {
    final hasBranch = alumni.branch != null && alumni.branch!.isNotEmpty;
    final hasBatch = alumni.batch != null && alumni.batch!.isNotEmpty;
    if (hasBranch && hasBatch) return '${alumni.branch} • Batch of ${alumni.batch}';
    if (hasBranch) return alumni.branch!;
    if (hasBatch) return 'Batch of ${alumni.batch}';
    return 'Academic details not specified';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    final isOwnProfile = currentUser?.uid == alumni.uid;
    final canSeeEmail = alumni.showEmail || isOwnProfile || isAdmin;
    final canSeePhone = alumni.showPhone || isOwnProfile || isAdmin;
    final canSeeCompany = alumni.showCompany || isOwnProfile || isAdmin;
    final canSeeLocation = alumni.showLocation || isOwnProfile || isAdmin;

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Modern off-white background
      appBar: AppAppBar(
        title: 'Alumni Profile',
        showBack: true,
        actions: [
          if (isAdmin || isOwnProfile)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                child: Icon(isOwnProfile ? Icons.edit_rounded : Icons.admin_panel_settings, color: Colors.grey.shade800, size: 20),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditProfileScreen(user: alumni)),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Header Profile Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 24, bottom: 32, left: 24, right: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Hero(
                    tag: 'profile_${alumni.uid}',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: ProfileAvatar(imageUrl: alumni.profileImage, name: alumni.name, size: 120),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    alumni.name,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    canSeeCompany ? _formatProfessionalDetails() : 'Professional details private',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w500, height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  // Modern Action Buttons
                  FutureBuilder<String?>(
                    future: FirestoreService().getConnectionStatus(
                      context.read<AuthProvider>().currentUser!.uid,
                      alumni.uid,
                    ),
                    builder: (context, snapshot) {
                      final status = snapshot.data;
                      final isConnected = status == 'accepted';
                      final isPending = status == 'pending';

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!isOwnProfile)
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: _buildPrimaryStatusButton(
                                  context,
                                  status: status,
                                  isConnected: isConnected,
                                  isPending: isPending,
                                ),
                              ),
                            ),
                          if (!isOwnProfile) const SizedBox(width: 12),
                          _SecondaryActionButton(
                            icon: isConnected || isOwnProfile ? Icons.chat_bubble_rounded : Icons.lock_rounded,
                            color: isConnected || isOwnProfile ? AppTheme.primaryRed : Colors.grey.shade400,
                            onPressed: () async {
                              if (isOwnProfile) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You cannot message yourself')));
                                return;
                              }
                              if (!isConnected) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isPending ? 'Wait for connection approval' : 'You can only message connections'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              final currentUser = context.read<AuthProvider>().currentUser;
                              if (currentUser == null) return;
                              final convId = await FirestoreService().getOrCreateConversation(currentUser.uid, alumni.uid);
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      conversationId: convId,
                                      otherUser: alumni,
                                      currentUserId: currentUser.uid,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(width: 12),
                          _SecondaryActionButton(
                            icon: isConnected || isOwnProfile ? Icons.call_rounded : Icons.lock_rounded,
                            color: isConnected || isOwnProfile ? AppTheme.primaryRed : Colors.grey.shade400,
                            onPressed: () {
                              if (isOwnProfile) return;
                              if (!isConnected) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isPending ? 'Contact features unlock after connecting' : 'Connect to unlock contact features'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              // Add call logic
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Details Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Professional Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  _buildModernCard(
                    children: [
                      _InfoTile(
                        icon: Icons.work_outline_rounded,
                        title: 'Currently Working As ',
                        content: canSeeCompany ? _formatProfessionalDetails() : 'Private',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, color: Colors.black12),
                      ),
                      _InfoTile(
                        icon: Icons.school_outlined,
                        title: 'Academic Background',
                        content: _formatAcademicDetails(),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, color: Colors.black12),
                      ),
                      _InfoTile(
                        icon: Icons.location_on_outlined,
                        title: 'Based In',
                        content: canSeeLocation 
                          ? ((alumni.city != null && alumni.city!.isNotEmpty) ? alumni.city! : 'Not specified')
                          : 'Private',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Contact Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  _buildModernCard(
                    children: [
                      _InfoTile(
                        icon: Icons.email_outlined,
                        title: 'Email Address',
                        content: canSeeEmail ? alumni.email : 'Private',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, color: Colors.black12),
                      ),
                      _InfoTile(
                        icon: Icons.phone_outlined,
                        title: 'Phone Number',
                        content: canSeePhone 
                          ? ((alumni.phone != null && alumni.phone!.isNotEmpty) ? alumni.phone! : 'Not provided')
                          : 'Private',
                      ),
                    ],
                  ),
                  const SizedBox(height: 40), // Bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build consistent modern cards
  Widget _buildModernCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // Smart primary button that changes style based on connection status
  Widget _buildPrimaryStatusButton(BuildContext context, {required String? status, required bool isConnected, required bool isPending}) {
    if (status == null) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.person_add_rounded, size: 20),
        label: const Text('Connect', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: () {
          final currentUserId = context.read<AuthProvider>().currentUser?.uid;
          if (currentUserId != null) {
            FirestoreService().addConnection(currentUserId, alumni.uid);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Connection request sent to ${alumni.name}'), behavior: SnackBarBehavior.floating),
            );
            (context as Element).markNeedsBuild();
          }
        },
      );
    }

    if (isPending) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty_rounded, color: Colors.amber.shade700, size: 18),
            const SizedBox(width: 8),
            Text('Request Sent', style: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 18),
          const SizedBox(width: 8),
          Text('Connected', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}

// Modern Square Icon Button for secondary actions
class _SecondaryActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const _SecondaryActionButton({required this.icon, required this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.primaryRed;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: effectiveColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: effectiveColor.withOpacity(0.2)),
        ),
        child: Icon(icon, color: effectiveColor, size: 22),
      ),
    );
  }
}

// Modern info row with icon and text hierarchy
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _InfoTile({required this.icon, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Row(
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
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }
}