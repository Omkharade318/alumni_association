import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/alumni_directory_screen.dart';
import '../screens/connections_screen.dart';
import '../screens/jobs_screen.dart';
import '../screens/donation_screen.dart';
import '../screens/messaging_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/admin/admin_gate_screen.dart';
import '../screens/news_screen.dart';
import '../services/firestore_service.dart';
import '../config/theme.dart';
import '../widgets/profile_avatar.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isAdmin = user?.isAdmin ?? false;

    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: Column(
        children: [
          // Modern Personalized Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 24,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryRed.withOpacity(0.9),
                  AppTheme.primaryRed,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ProfileAvatar(
                    imageUrl: user?.profileImage,
                    name: user?.name ?? 'A',
                    size: 64,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'Alumni Connect',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  user != null
                      ? '${user.branch ?? "Alumni"} • Batch of ${user.batch ?? "-"}'
                      : 'Welcome back!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Drawer Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              children: [
                _drawerItem(
                  context,
                  icon: Icons.contact_mail_outlined,
                  title: 'Alumni Directory',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlumniDirectoryScreen())),
                ),
                _drawerItem(
                  context,
                  icon: Icons.people_outline,
                  title: 'My Connections',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConnectionsScreen())),
                ),
                _drawerItem(
                  context,
                  icon: Icons.work_outline,
                  title: 'Job & Mentorship',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JobsScreen())),
                ),
                _drawerItem(
                  context,
                  icon: Icons.newspaper_outlined,
                  title: 'News & Updates',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsScreen())),
                ),

                // Donates item with Badge
                StreamBuilder<int>(
                  stream: FirestoreService().getUnreadDonationsCountStream(user?.uid ?? ''),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _drawerItem(
                      context,
                      icon: Icons.volunteer_activism_outlined,
                      title: 'Campaigns & Donate',
                      badgeCount: count,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DonationScreen())),
                    );
                  },
                ),

                _drawerItem(
                  context,
                  icon: Icons.chat_bubble_outline,
                  title: 'Messages',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagingScreen())),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Divider(color: Colors.black12, height: 1),
                ),

                _drawerItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),

                if (isAdmin)
                  _drawerItem(
                    context,
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Admin Panel',
                    textColor: AppTheme.primaryRed,
                    iconColor: AppTheme.primaryRed,
                    onTap: () {
                      Navigator.pop(context); // Close drawer before opening admin
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminGateScreen()));
                    },
                  ),
              ],
            ),
          ),

          // Modern Sign Out Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: () => context.read<AuthProvider>().signOut(),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16), // Bottom safe space
        ],
      ),
    );
  }

  // Modern Drawer Tile Widget
  Widget _drawerItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        int badgeCount = 0,
        Color? textColor,
        Color? iconColor,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: iconColor ?? Colors.black87, size: 24),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: textColor ?? Colors.black87,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (badgeCount > 0) const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
          ],
        ),
        onTap: onTap,
        hoverColor: Colors.grey.shade100,
        splashColor: Colors.grey.shade200,
      ),
    );
  }
}