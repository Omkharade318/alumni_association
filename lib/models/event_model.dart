import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime date;
  final String time;
  final String location;
  final String? organizerId;
  final List<String> attendees;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.date,
    required this.time,
    required this.location,
    this.organizerId,
    this.attendees = const [],
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      date: data['date'] != null
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      time: data['time'] ?? '',
      location: data['location'] ?? '',
      organizerId: data['organizerId'],
      attendees: data['attendees'] != null ? List<String>.from(data['attendees']) : [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'date': Timestamp.fromDate(date),
      'time': time,
      'location': location,
      'organizerId': organizerId,
      'attendees': attendees,
    };
  }
}
