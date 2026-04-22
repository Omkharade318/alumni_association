import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/event_model.dart';

class EventsCalendarScreen extends StatelessWidget {
  const EventsCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _EventsCalendarContent();
  }
}

class _EventsCalendarContent extends StatefulWidget {
  const _EventsCalendarContent();

  @override
  State<_EventsCalendarContent> createState() => _EventsCalendarContentState();
}

class _EventsCalendarContentState extends State<_EventsCalendarContent> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(color: AppTheme.primaryRed, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const SizedBox(height: 24),
          const Text('Upcoming Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          StreamBuilder<List<EventModel>>(
            stream: FirestoreService().getEventsStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final events = snapshot.data!
                  .where((e) => e.date.isAfter(DateTime.now().subtract(const Duration(days: 1))))
                  .toList();
              if (events.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundWhite,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('No upcoming events')),
                );
              }
              return Column(
                children: events
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _EventCard(event: e),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerGray),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${event.date.day}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryRed),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('MMM d, yyyy').format(event.date)} • ${event.time} • ${event.location}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EventDetailScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final firestore = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: AppTheme.white,
        title: const Text('Event Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<EventModel?>(
        stream: firestore.getEventStream(event.id),
        initialData: event,
        builder: (context, snapshot) {
          final currentEvent = snapshot.data ?? event;
          final isAttending = user != null && currentEvent.attendees.contains(user.uid);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (currentEvent.imageUrl != null)
                  Image.network(currentEvent.imageUrl!, height: 250, fit: BoxFit.cover)
                else
                  Container(
                    height: 200,
                    color: AppTheme.primaryRed.withOpacity(0.2),
                    child: Center(
                      child: Icon(Icons.event, size: 80, color: AppTheme.primaryRed.withOpacity(0.5)),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              currentEvent.title,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${currentEvent.attendees.length} attending',
                              style: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentEvent.description,
                        style: const TextStyle(fontSize: 15, height: 1.5, color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      _InfoRow(icon: Icons.calendar_today, text: DateFormat('EEEE, MMMM d, yyyy').format(currentEvent.date)),
                      _InfoRow(icon: Icons.access_time, text: currentEvent.time),
                      _InfoRow(icon: Icons.location_on, text: currentEvent.location),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAttending ? Colors.green : AppTheme.primaryRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: user == null
                              ? null
                              : () async {
                                  final newStatus = !isAttending;
                                  await firestore.rsvpEvent(currentEvent.id, user.uid, newStatus);
                                  
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(newStatus 
                                          ? 'You are now attending this event!' 
                                          : 'You have cancelled your attendance.'),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: newStatus ? Colors.green : Colors.black87,
                                      ),
                                    );
                                  }
                                },
                          child: Text(
                            isAttending ? 'Attending' : 'Attend',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryRed),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
