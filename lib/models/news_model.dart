import 'package:cloud_firestore/cloud_firestore.dart';

class NewsModel {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final DateTime createdAt;
  final String createdBy; // admin uid or name

  NewsModel({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.createdAt,
    required this.createdBy,
  });

  factory NewsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NewsModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }
}
