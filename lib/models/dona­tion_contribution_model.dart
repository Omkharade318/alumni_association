import 'package:cloud_firestore/cloud_firestore.dart';

class DonationContributionModel {
  final String id;
  final String userId;
  final double amount;
  final DateTime createdAt;

  DonationContributionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.createdAt,
  });

  factory DonationContributionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DonationContributionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

