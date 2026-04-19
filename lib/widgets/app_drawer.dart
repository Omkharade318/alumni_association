import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/alumni_directory_screen.dart';
import '../screens/connections_screen.dart';
import '../screens/feed_screen.dart';
import '../screens/jobs_screen.dart';
import '../screens/donation_screen.dart';
import '../screens/messaging_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/admin/admin_gate_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            child: Center(
              child: Icon(Icons.school, size: 80, color: Colors.black87),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem(Icons.contact_mail_outlined, 'Alumni Directory',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlumniDirectoryScreen()))),
                _drawerItem(Icons.people_outline, 'My Connections',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConnectionsScreen()))),
                _drawerItem(Icons.edit_note, 'Feed',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedScreen()))),
                _drawerItem(Icons.work_outline, 'Job and Mentorship',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JobsScreen()))),
                _drawerItem(Icons.newspaper, 'News and Updates',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedScreen()))),
                _drawerItem(Icons.accessibility_new, 'Donate',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DonationScreen()))),
                _drawerItem(Icons.chat_bubble_outline, 'Messages',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagingScreen()))),
                _drawerItem(Icons.settings_outlined, 'Settings',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
                if (context.watch<AuthProvider>().currentUser?.isAdmin == true)
                  _drawerItem(
                    Icons.admin_panel_settings,
                    'Admin Panel',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminGateScreen()));
                    },
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B2332), // Deep Maroon
                  shape: StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => context.read<AuthProvider>().signOut(),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Sign Out', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap ?? () {},
    );
  }
}