import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/event_model.dart';
import '../../services/firestore_service.dart';
import 'admin_event_detail_screen.dart';
import 'admin_event_form_screen.dart';

class AdminEventsScreen extends StatelessWidget {
  const AdminEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Modern off-white background
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manage Events',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminEventFormScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Event', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: FirestoreService().getEventsStream(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data!;

          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 24),
                  const Text('No events scheduled', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text('Tap + to create your first event.', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100), // Extra bottom padding for FAB
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Delete Event?', style: TextStyle(fontWeight: FontWeight.bold)),
                      content: Text('This will permanently delete “${event.title}”. This action cannot be undone.', style: const TextStyle(height: 1.4)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true) return;
                  await FirestoreService().deleteEvent(event.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Event deleted successfully'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
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
    final String month = DateFormat('MMM').format(event.date).toUpperCase();
    final String day = DateFormat('dd').format(event.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Visual Date Block
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(month, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryRed)),
                      const SizedBox(height: 2),
                      Text(day, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primaryRed, letterSpacing: -0.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Event Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.2),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Location & Time
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(event.time, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          const SizedBox(width: 12),
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Badges and Actions
                      Row(
                        children: [
                          // Attendees Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.people_alt_rounded, size: 14, color: Colors.green.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  '${event.attendees.length} RSVPs',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),

                          // Modern Action Buttons
                          InkWell(
                            onTap: onEdit,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.edit_rounded, size: 18, color: Colors.grey.shade700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: onDelete,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.delete_rounded, size: 18, color: Colors.red.shade600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}