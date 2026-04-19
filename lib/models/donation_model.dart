import 'package:cloud_firestore/cloud_firestore.dart';

class DonationModel {
  final String id;
  final String category;
  final String title;
  final String description;
  final String? imageUrl;
  final double targetAmount;
  final double collectedAmount;
  final DateTime createdAt;

  DonationModel({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.targetAmount,
    this.collectedAmount = 0,
    required this.createdAt,
  });

  factory DonationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DonationModel(
      id: doc.id,
      category: data['category'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      targetAmount: (data['targetAmount'] ?? 0).toDouble(),
      collectedAmount: (data['collectedAmount'] ?? 0).toDouble(),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'category': category,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'targetAmount': targetAmount,
      'collectedAmount': collectedAmount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  double get progress => targetAmount > 0 ? collectedAmount / targetAmount : 0;
  bool get isGoalCompleted => collectedAmount >= targetAmount;
}
