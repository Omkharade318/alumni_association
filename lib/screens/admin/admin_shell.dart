import 'package:flutter/material.dart';
import 'admin_events_screen.dart';
import 'admin_posts_screen.dart';
import 'admin_donations_screen.dart';
import 'admin_news_screen.dart';
import 'admin_jobs_screen.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Modern off-white background
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Dashboard Header
          Padding(
            padding: const EdgeInsets.only(bottom: 24, left: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage platform content and activities',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Color-coded Admin Navigation Tiles
          _AdminTile(
            icon: Icons.event_note_rounded,
            title: 'Manage Events',
            subtitle: 'Create, edit, delete events and view RSVPs',
            color: Colors.blue.shade600,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminEventsScreen()));
            },
          ),
          _AdminTile(
            icon: Icons.dynamic_feed_rounded,
            title: 'Manage Posts',
            subtitle: 'Moderate community posts and discussions',
            color: Colors.purple.shade600,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPostsScreen()));
            },
          ),
          _AdminTile(
            icon: Icons.volunteer_activism_rounded,
            title: 'Manage Donations',
            subtitle: 'Create campaigns and track contributions',
            color: Colors.green.shade600,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDonationsScreen()));
            },
          ),
          _AdminTile(
            icon: Icons.campaign_rounded,
            title: 'News & Updates',
            subtitle: 'Publish platform-wide announcements',
            color: Colors.orange.shade600,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminNewsScreen()));
            },
          ),
          _AdminTile(
            icon: Icons.work_outline_rounded,
            title: 'Manage Jobs',
            subtitle: 'Post job opportunities and mentorships',
            color: Colors.teal.shade600,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminJobsScreen()));
            },
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          highlightColor: color.withOpacity(0.05),
          splashColor: color.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                const SizedBox(width: 16),

                // Text Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Trailing Arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}