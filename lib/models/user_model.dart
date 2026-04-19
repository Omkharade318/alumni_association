import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final bool isAdmin;
  final String? phone;
  final String? branch;
  final String? batch;
  final String? company;
  final String? jobTitle;
  final String? city;
  final String? profileImage;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.isAdmin = false,
    this.phone,
    this.branch,
    this.batch,
    this.company,
    this.jobTitle,
    this.city,
    this.profileImage,
    this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      isAdmin: data['isAdmin'] ?? (data['email'] == 'admin@alumni.com' || data['email'] == 'admin@gmail.com'),
      phone: data['phone'],
      branch: data['branch'],
      batch: data['batch'],
      company: data['company'],
      jobTitle: data['jobTitle'],
      city: data['city'],
      profileImage: data['profileImage'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'isAdmin': isAdmin,
      'phone': phone,
      'branch': branch,
      'batch': batch,
      'company': company,
      'jobTitle': jobTitle,
      'city': city,
      'profileImage': profileImage,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  String get displayLocation {
    final parts = <String>[];
    if (company != null && company!.isNotEmpty) parts.add(company!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    return parts.isEmpty ? 'Not specified' : parts.join(' | ');
  }

  String get displayBranchBatch {
    final parts = <String>[];
    if (branch != null && branch!.isNotEmpty) parts.add(branch!);
    if (batch != null && batch!.isNotEmpty) parts.add('$batch Batch');
    return parts.isEmpty ? 'Not specified' : parts.join(' | ');
  }

  String get displayContact {
    final parts = <String>[];
    parts.add(email);
    if (phone != null && phone!.isNotEmpty) parts.add(phone!);
    return parts.join(' • ');
  }
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    bool? isAdmin,
    String? phone,
    String? branch,
    String? batch,
    String? company,
    String? jobTitle,
    String? city,
    String? profileImage,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      isAdmin: isAdmin ?? this.isAdmin,
      phone: phone ?? this.phone,
      branch: branch ?? this.branch,
      batch: batch ?? this.batch,
      company: company ?? this.company,
      jobTitle: jobTitle ?? this.jobTitle,
      city: city ?? this.city,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
