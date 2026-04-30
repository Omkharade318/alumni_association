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
    return const Scaffold(
      backgroundColor: Color(0xFFF9FAFB), // Modern soft background
      body: _EventsCalendarContent(),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern Calendar Card
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2035),
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
                  color: AppTheme.primaryRed.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold),
                outsideDaysVisible: false,
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                leftChevronIcon: Icon(Icons.chevron_left_rounded, color: Colors.black87),
                rightChevronIcon: Icon(Icons.chevron_right_rounded, color: Colors.black87),
              ),
            ),
          ),
          const SizedBox(height: 32),

          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              'Upcoming Events',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
          ),
          const SizedBox(height: 16),

          StreamBuilder<List<EventModel>>(
            stream: FirestoreService().getEventsStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final events = snapshot.data!
                  .where((e) => e.date.isAfter(DateTime.now().subtract(const Duration(days: 1))))
                  .toList();

              if (events.isEmpty) {
                return Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                        child: Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 16),
                      const Text('No upcoming events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Check back later for new schedules.', style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length,
                itemBuilder: (context, i) => _EventCard(event: events[i]),
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
    final String month = DateFormat('MMM').format(event.date).toUpperCase();
    final String day = DateFormat('dd').format(event.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Visual Date Block
                Container(
                  width: 64,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(month, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryRed)),
                      const SizedBox(height: 2),
                      Text(day, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primaryRed, letterSpacing: -0.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Event Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(event.time, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
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

class EventDetailScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final firestore = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.white,
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
          'Event Details',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
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
                // Edge-to-Edge Header Image
                if (currentEvent.imageUrl != null)
                  Image.network(currentEvent.imageUrl!, height: 260, fit: BoxFit.cover)
                else
                  Container(
                    height: 240,
                    color: AppTheme.primaryRed.withOpacity(0.05),
                    child: Center(
                      child: Icon(Icons.event_rounded, size: 80, color: AppTheme.primaryRed.withOpacity(0.4)),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Attendees Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              currentEvent.title,
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.5),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.people_alt_rounded, size: 18, color: Colors.green.shade700),
                                const SizedBox(height: 4),
                                Text(
                                  '${currentEvent.attendees.length}',
                                  style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Description
                      Text(
                        currentEvent.description,
                        style: TextStyle(fontSize: 15, height: 1.6, color: Colors.grey.shade800),
                      ),
                      const SizedBox(height: 32),

                      const Text('When & Where', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      // Modern Info Rows
                      _buildInfoTile(
                        icon: Icons.calendar_today_rounded,
                        title: 'Date',
                        subtitle: DateFormat('EEEE, MMMM d, yyyy').format(currentEvent.date),
                      ),
                      _buildInfoTile(
                        icon: Icons.access_time_rounded,
                        title: 'Time',
                        subtitle: currentEvent.time,
                      ),
                      _buildInfoTile(
                        icon: Icons.location_on_rounded,
                        title: 'Location',
                        subtitle: currentEvent.location,
                      ),

                      const SizedBox(height: 40),

                      // RSVP Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAttending ? Colors.green.shade600 : AppTheme.primaryRed,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                  content: Text(
                                    newStatus
                                        ? 'You are now attending this event!'
                                        : 'You have cancelled your RSVP.',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  backgroundColor: newStatus ? Colors.green.shade700 : Colors.black87,
                                ),
                              );
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(isAttending ? Icons.check_circle_outline_rounded : Icons.event_available_rounded),
                              const SizedBox(width: 8),
                              Text(
                                isAttending ? 'Attending' : 'RSVP Now',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
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

  // Helper widget for polished info rows
  Widget _buildInfoTile({required IconData icon, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
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
                Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}