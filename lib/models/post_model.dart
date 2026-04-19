import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String? userImage;
  final String content;
  final List<String>? imageUrls;
  final List<String> likes;
  final int commentCount;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userImage,
    required this.content,
    this.imageUrls,
    this.likes = const [],
    this.commentCount = 0,
    required this.createdAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userImage: data['userImage'],
      content: data['content'] ?? '',
      imageUrls: data['imageUrls'] != null
          ? List<String>.from(data['imageUrls'])
          : null,
      likes: data['likes'] != null ? List<String>.from(data['likes']) : [],
      commentCount: data['commentCount'] ?? 0,
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
      'imageUrls': imageUrls ?? [],
      'likes': likes,
      'commentCount': commentCount,
      'createdAt': createdAt,
    };
  }

  bool isLikedBy(String userId) => likes.contains(userId);
}
