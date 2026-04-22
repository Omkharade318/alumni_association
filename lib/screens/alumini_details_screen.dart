import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/app_app_bar.dart';
import 'messaging_screen.dart';
import 'edit_profile_screen.dart';
// Assuming you have ChatScreen imported here

class AlumniDetailScreen extends StatelessWidget {
  final UserModel alumni;

  const AlumniDetailScreen({super.key, required this.alumni});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;
    final isAdmin = currentUser?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppAppBar(
        title: 'Alumni Profile', 
        showBack: true,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
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
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Hero(
                    tag: 'profile_${alumni.uid}', // Optional: smooth transition if coming from a list
                    child: ProfileAvatar(imageUrl: alumni.profileImage, name: alumni.name, size: 120),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    alumni.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${alumni.jobTitle ?? 'Alumni'} ${alumni.company != null ? 'at ${alumni.company}' : ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: AppTheme.textGray, fontWeight: FontWeight.w500),
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
                          if (status == null)
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.person_add, size: 20),
                                label: const Text('Connect', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryRed,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  final currentUserId = context.read<AuthProvider>().currentUser?.uid;
                                  if (currentUserId != null) {
                                    FirestoreService().addConnection(currentUserId, alumni.uid);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Connection request sent to ${alumni.name}')),
                                    );
                                    // Refresh UI
                                    (context as Element).markNeedsBuild();
                                  }
                                },
                              ),
                            )
                          else if (isPending)
                            const Expanded(
                              child: Chip(
                                label: Text('Request Sent'),
                                backgroundColor: Colors.amber,
                                labelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                avatar: Icon(Icons.hourglass_empty, color: Colors.white, size: 16),
                              ),
                            )
                          else
                            const Expanded(
                              child: Chip(
                                label: Text('Connected'),
                                backgroundColor: Colors.green,
                                labelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                avatar: Icon(Icons.check, color: Colors.white, size: 16),
                              ),
                            ),
                          const SizedBox(width: 12),
                          _SecondaryActionButton(
                            icon: isConnected ? Icons.chat_bubble_outline : Icons.lock_outline,
                            color: isConnected ? null : Colors.grey,
                            onPressed: () async {
                              if (!isConnected) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(isPending ? 'Wait for connection approval' : 'You can only message connections')),
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
                            icon: isConnected ? Icons.call_outlined : Icons.lock_outline,
                            color: isConnected ? null : Colors.grey,
                            onPressed: () {
                              if (!isConnected) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(isPending ? 'Contact features unlock after connecting' : 'Connect to unlock contact features')),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.dividerGray.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        _InfoTile(
                          icon: Icons.work_outline,
                          title: 'Currently Working In',
                          content: '${alumni.company ?? '-'} | ${alumni.jobTitle ?? '-'}',
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1, color: AppTheme.dividerGray),
                        ),
                        _InfoTile(
                          icon: Icons.school_outlined,
                          title: 'Pursued',
                          content: '${alumni.branch ?? '-'} | ${alumni.batch ?? '-'}',
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1, color: AppTheme.dividerGray),
                        ),
                        _InfoTile(
                          icon: Icons.location_on_outlined,
                          title: 'Based In',
                          content: alumni.city ?? '-',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Contact Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.dividerGray.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        _InfoTile(
                          icon: Icons.email_outlined,
                          title: 'Email Address',
                          content: alumni.email,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1, color: AppTheme.dividerGray),
                        ),
                        _InfoTile(
                          icon: Icons.phone_outlined,
                          title: 'Phone Number',
                          content: alumni.phone ?? 'Not provided',
                        ),
                      ],
                    ),
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
}

// Modern Square Icon Button for secondary actions
class _SecondaryActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const _SecondaryActionButton({required this.icon, required this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (color ?? AppTheme.primaryRed).withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (color ?? AppTheme.primaryRed).withOpacity(0.2)),
        ),
        child: Icon(icon, color: color ?? AppTheme.primaryRed, size: 24),
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
            borderRadius: BorderRadius.circular(10),
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
                style: const TextStyle(fontSize: 13, color: AppTheme.textGray, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}