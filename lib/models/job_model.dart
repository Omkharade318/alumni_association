import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String id;
  final String title;
  final String company;
  final String? companyLogo;
  final String location;
  final String? description;
  final String? postedBy;
  final DateTime createdAt;

  JobModel({
    required this.id,
    required this.title,
    required this.company,
    this.companyLogo,
    required this.location,
    this.description,
    this.postedBy,
    required this.createdAt,
  });

  factory JobModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JobModel(
      id: doc.id,
      title: data['title'] ?? '',
      company: data['company'] ?? '',
      companyLogo: data['companyLogo'],
      location: data['location'] ?? '',
      description: data['description'],
      postedBy: data['postedBy'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
