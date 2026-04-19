import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/event_model.dart';
import '../models/message_model.dart';
import '../models/donation_model.dart';
import '../models/donation_contribution_model.dart';
import '../models/notification_model.dart';
import '../models/job_model.dart';
import '../models/news_model.dart';
import '../utils/constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUser(UserModel user) async {
    await _firestore.collection(AppConstants.usersCollection).doc(user.uid).set(user.toFirestore());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
    return doc.exists ? UserModel.fromFirestore(doc) : null;
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection(AppConstants.usersCollection).doc(uid).update(data);
  }

  Stream<List<UserModel>> getAlumniStream({String? branch, String? batch, String? search}) {
    Query query = _firestore.collection(AppConstants.usersCollection);
    if (branch != null && branch.isNotEmpty) query = query.where('branch', isEqualTo: branch);
    if (batch != null && batch.isNotEmpty) query = query.where('batch', isEqualTo: batch);
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  Future<List<UserModel>> searchAlumni({
    String? name,
    String? branch,
    String? batch,
    String? city,
  }) async {
    Query query = _firestore.collection(AppConstants.usersCollection);
    if (branch != null && branch.isNotEmpty) query = query.where('branch', isEqualTo: branch);
    if (batch != null && batch.isNotEmpty) query = query.where('batch', isEqualTo: batch);
    if (city != null && city.isNotEmpty) query = query.where('city', isEqualTo: city);

    final snapshot = await query.get();
    var users = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    if (name != null && name.isNotEmpty) {
      users = users.where((u) => u.name.toLowerCase().contains(name.toLowerCase())).toList();
    }
    return users;
  }

  Future<void> createPost(PostModel post) async {
    await _firestore.collection(AppConstants.postsCollection).doc(post.id).set(post.toFirestore());
  }

  Stream<List<PostModel>> getPostsStream() {
    return _firestore
        .collection(AppConstants.postsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }

  Future<void> likePost(String postId, String userId, bool isLiked) async {
    final docRef = _firestore.collection(AppConstants.postsCollection).doc(postId);
    if (isLiked) {
      await docRef.update({'likes': FieldValue.arrayRemove([userId])});
    } else {
      await docRef.update({'likes': FieldValue.arrayUnion([userId])});
    }
  }

  Future<void> addComment(String postId) async {
    await _firestore.collection(AppConstants.postsCollection).doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });
  }

  Future<void> createComment(String postId, String userId, String userName, String content) async {
    await _firestore.collection(AppConstants.postsCollection).doc(postId).collection('comments').add({
      'userId': userId,
      'userName': userName,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await addComment(postId);
  }

  Stream<List<EventModel>> getEventsStream() {
    return _firestore
        .collection(AppConstants.eventsCollection)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }

  Future<void> createEvent(EventModel event) async {
    await _firestore.collection(AppConstants.eventsCollection).doc(event.id).set(event.toFirestore());
  }

  /// Updates only the provided fields. Callers must avoid sending fields
  /// like `attendees` unless they explicitly intend to overwrite them.
  Future<void> updateEventDetails(String eventId, Map<String, dynamic> data) async {
    await _firestore.collection(AppConstants.eventsCollection).doc(eventId).update(data);
  }

  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection(AppConstants.eventsCollection).doc(eventId).delete();
  }

  Future<void> rsvpEvent(String eventId, String userId, bool attending) async {
    final docRef = _firestore.collection(AppConstants.eventsCollection).doc(eventId);
    if (attending) {
      await docRef.update({'attendees': FieldValue.arrayUnion([userId])});
    } else {
      await docRef.update({'attendees': FieldValue.arrayRemove([userId])});
    }
  }

  Stream<List<DonationModel>> getDonationsStream() {
    return _firestore
        .collection(AppConstants.donationsCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => DonationModel.fromFirestore(doc)).toList());
  }

  Future<void> createDonation(DonationModel donation) async {
    await _firestore.collection(AppConstants.donationsCollection).doc(donation.id).set(donation.toFirestore());
  }

  /// Updates only the provided fields. Callers must avoid sending
  /// `collectedAmount` unless they intend to modify the collected total.
  Future<void> updateDonationDetails(String donationId, Map<String, dynamic> data) async {
    await _firestore.collection(AppConstants.donationsCollection).doc(donationId).update(data);
  }

  Future<void> deleteDonation(String donationId) async {
    await _firestore.collection(AppConstants.donationsCollection).doc(donationId).delete();
  }

  Stream<List<DonationContributionModel>> getDonationContributionsStream(String donationId) {
    return _firestore
        .collection(AppConstants.donationsCollection)
        .doc(donationId)
        .collection('contributions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => DonationContributionModel.fromFirestore(doc)).toList());
  }

  Future<void> addDonation(String donationId, double amount, String userId) async {
    await _firestore.collection(AppConstants.donationsCollection).doc(donationId).update({
      'collectedAmount': FieldValue.increment(amount),
    });
    await _firestore.collection(AppConstants.donationsCollection).doc(donationId).collection('contributions').add({
      'userId': userId,
      'amount': amount,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> getOrCreateConversation(String user1, String user2) async {
    final participants = [user1, user2]..sort();
    final query = await _firestore
        .collection(AppConstants.conversationsCollection)
        .where('participants', isEqualTo: participants)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) return query.docs.first.id;

    final docRef = await _firestore.collection(AppConstants.conversationsCollection).add({
      'participants': participants,
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> sendMessage(String conversationId, MessageModel message) async {
    await _firestore
        .collection(AppConstants.conversationsCollection)
        .doc(conversationId)
        .collection('messages')
        .add(message.toFirestore());
    await _firestore.collection(AppConstants.conversationsCollection).doc(conversationId).update({
      'lastMessage': message.content,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getConversationsStream(String userId) {
    return _firestore
        .collection(AppConstants.conversationsCollection)
        .where('participants', arrayContains: userId)
        .snapshots();
  }

  Stream<List<MessageModel>> getMessagesStream(String conversationId) {
    return _firestore
        .collection(AppConstants.conversationsCollection)
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList());
  }

  Future<void> addConnection(String userId, String targetUserId) async {
    await _firestore.collection(AppConstants.connectionsCollection).add({
      'userId': userId,
      'targetUserId': targetUserId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList());
  }

  Stream<List<JobModel>> getJobsStream() {
    return _firestore
        .collection(AppConstants.jobsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => JobModel.fromFirestore(doc)).toList());
  }

  Future<void> updatePostContent(String postId, String newContent) async {
    await _firestore.collection(AppConstants.postsCollection).doc(postId).update({'content': newContent});
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection(AppConstants.postsCollection).doc(postId).delete();
  }

  // ──────────────── News & Updates ────────────────

  Stream<List<NewsModel>> getNewsStream() {
    return _firestore
        .collection(AppConstants.newsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NewsModel.fromFirestore(doc)).toList());
  }

  Future<void> createNews(NewsModel news) async {
    await _firestore
        .collection(AppConstants.newsCollection)
        .doc(news.id)
        .set(news.toFirestore());
  }

  Future<void> updateNews(String newsId, Map<String, dynamic> data) async {
    await _firestore
        .collection(AppConstants.newsCollection)
        .doc(newsId)
        .update(data);
  }

  Future<void> deleteNews(String newsId) async {
    await _firestore
        .collection(AppConstants.newsCollection)
        .doc(newsId)
        .delete();
  }
}
