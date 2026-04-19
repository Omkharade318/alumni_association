import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import 'admin_event_detail_screen.dart';
import 'admin_event_form_screen.dart';

class AdminEventsScreen extends StatelessWidget {
  const AdminEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Events'),
        backgroundColor: AppTheme.primaryRed,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryRed,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminEventFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: FirestoreService().getEventsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data!;
          if (events.isEmpty) {
            return const Center(child: Text('No events found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _EventRow(
                event: event,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminEventDetailScreen(event: event),
                    ),
                  );
                },
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminEventFormScreen(event: event),
                    ),
                  );
                },
                onDelete: () async {
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
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Event deleted')),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventRow({
    required this.event,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('${event.attendees.length} RSVPs'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${event.date.toLocal().toString().split(' ').first} • ${event.time} • ${event.location}',
                style: const TextStyle(color: AppTheme.textGray),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    color: AppTheme.primaryRed,
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

