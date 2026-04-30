import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String? userImage;
  final String content;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userImage,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userImage: data['userImage'],
      content: data['content'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'content': content,
      'createdAt': createdAt,
    };
  }
}
