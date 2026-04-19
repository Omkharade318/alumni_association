import 'package:flutter/material.dart';
import '../home_screen.dart';

import 'admin_events_screen.dart';
import 'admin_posts_screen.dart';
import 'admin_donations_screen.dart';
import 'admin_news_screen.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AdminTile(
            icon: Icons.event,
            title: 'Manage Events',
            subtitle: 'Create, edit, delete events and view RSVPs',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminEventsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _AdminTile(
            icon: Icons.post_add,
            title: 'Manage Posts',
            subtitle: 'Edit and delete posts',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminPostsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _AdminTile(
            icon: Icons.volunteer_activism,
            title: 'Manage Donations',
            subtitle: 'Create campaigns and view contributions',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminDonationsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _AdminTile(
            icon: Icons.newspaper,
            title: 'News & Updates',
            subtitle: 'Publish and manage news visible on the home screen',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminNewsScreen(),
                ),
              );
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
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 26, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

