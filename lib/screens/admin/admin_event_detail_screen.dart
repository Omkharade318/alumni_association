import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import 'admin_event_form_screen.dart';

class AdminEventDetailScreen extends StatelessWidget {
  final EventModel event;

  const AdminEventDetailScreen({super.key, required this.event});

  Future<List<UserModel?>> _loadAttendeeUsers(BuildContext context) async {
    final firestore = FirestoreService();
    return Future.wait(event.attendees.map((uid) => firestore.getUser(uid)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        backgroundColor: AppTheme.primaryRed,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminEventFormScreen(event: event),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete event?'),
                  content: Text('This will permanently delete “${event.title}”.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirmed != true) return;
              await FirestoreService().deleteEvent(event.id);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    event.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                event.title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(event.description),
              const SizedBox(height: 20),
              _InfoRow(icon: Icons.calendar_today, text: event.date.toLocal().toString().split(' ').first),
              const SizedBox(height: 8),
              _InfoRow(icon: Icons.access_time, text: event.time),
              const SizedBox(height: 8),
              _InfoRow(icon: Icons.location_on, text: event.location),
              const SizedBox(height: 20),
              const Text(
                'Attendees',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (event.attendees.isEmpty)
                const Text('No RSVPs yet')
              else
                FutureBuilder<List<UserModel?>>(
                  future: _loadAttendeeUsers(context),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final users = snapshot.data!;
                    return Column(
                      children: List.generate(event.attendees.length, (index) {
                        final userId = event.attendees[index];
                        final user = users[index];
                        final label = user?.name?.isNotEmpty == true ? user!.name : userId;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.dividerGray),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person_outline, color: AppTheme.primaryRed),
                              const SizedBox(width: 12),
                              Expanded(child: Text(label)),
                              Text(
                                userId,
                                style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                              ),
                            ],
                          ),
                        );
                      }),
                    );
                  },
                ),
              const SizedBox(height: 24),
              const Text(
                'Attendee updates happen via the RSVP button in the user-facing Event Detail screen.',
                style: TextStyle(color: AppTheme.textGray, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryRed),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}

