import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';
import '../screens/messaging_screen.dart';
import '../utils/constants.dart';
import '../screens/connections_screen.dart';
import '../services/firestore_service.dart';

// Top-level function for background messaging (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Global navigator key for navigation from background/terminated state
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // flutter_local_notifications setup
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel_v4', // Changed ID to force update
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max, // MAX for heads-up
    playSound: true,
    enableVibration: true,
  );

  // ─── Initialization ──────────────────────────────────────────────────────────

  Future<void> initialize() async {
    // 1. Request permissions (including Android 13+)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    // Explicitly request for Android 13+ if using newer flutter_local_notifications
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // 2. Create Android notification channel for heads-up banners
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 3. Initialize flutter_local_notifications
    const androidInit = AndroidInitializationSettings('ic_notification');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        // User tapped a local notification (foreground)
        final payload = response.payload;
        if (payload == 'message') {
          // Can't navigate without context here; handled via FCM data separately
        } else if (payload == 'connectionRequest') {
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => const ConnectionsScreen(initialTab: 1)),
          );
        }
      },
    );

    // 4. Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Also tell FCM to show heads-up natively if payload contains a notification block (mainly for iOS, but good practice)
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 5. Handle app opened from terminated state via notification
    final RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(seconds: 1), () => _handleMessage(initialMessage));
    }
  }

  void configureHandlers() {
    // Foreground: show a local heads-up banner
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      
      // Extract from notification block, fallback to data payload
      final title = notification?.title ?? message.data['title'] ?? 'New Notification';
      final body = notification?.body ?? message.data['body'] ?? 'You have a new message';
      final type = message.data['type'] ?? 'message';
      final relatedId = message.data['relatedId'];
      final senderId = message.data['senderId'] ?? '';
      final senderName = message.data['senderName'] ?? 'Someone';
      final userId = message.data['userId'] ?? '';

      // 1. Show local banner
      _showLocalNotification(
        title: title,
        body: body,
        payload: type,
      );

      // 2. Save to Firestore (fallback in case sender didn't/couldn't save it)
      // Only do this if we have a userId
      if (userId.isNotEmpty) {
        await createNotification(NotificationModel(
          id: '',
          userId: userId,
          senderId: senderId,
          senderName: senderName,
          title: title,
          body: body,
          type: type == 'connectionRequest' ? NotificationType.connectionRequest : NotificationType.message,
          createdAt: DateTime.now(),
          relatedId: relatedId,
        ));
      }
    });

    // Background/open: navigate to the right screen
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  // ─── Local Banner Notification ────────────────────────────────────────────────

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String payload = '',
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique id
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.max,
          visibility: NotificationVisibility.public,
          fullScreenIntent: true, // Helps with showing as a banner
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      payload: payload,
    );
  }

  // ─── Deep-link navigation ─────────────────────────────────────────────────────

  void _handleMessage(RemoteMessage message) async {
    final type = message.data['type'];
    final relatedId = message.data['relatedId'];
    final senderId = message.data['senderId'];
    final userId = message.data['userId'];

    if (type == 'message' && relatedId != null && senderId != null) {
      final sender = await FirestoreService().getUser(senderId);
      if (sender != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: relatedId,
              otherUser: sender,
              currentUserId: userId ?? '',
            ),
          ),
        );
      }
    } else if (type == 'connectionRequest') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const ConnectionsScreen(initialTab: 1)),
      );
    }
  }

  // ─── FCM Token management ─────────────────────────────────────────────────────

  Future<void> storeTokenForUser(String userId) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .update({'fcmToken': token});
      }
    } catch (e) {
      print('Error storing FCM token: $e');
    }
  }

  Future<void> removeTokenForUser(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'fcmToken': FieldValue.delete()});
    } catch (e) {
      print('Error removing FCM token: $e');
    }
  }

  // ─── Firestore notification CRUD ─────────────────────────────────────────────

  /// FIX: Removed .orderBy() to avoid requiring a composite Firestore index.
  /// Documents are sorted client-side after fetching.
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
      // Sort newest first client-side
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> createNotification(NotificationModel notification) async {
    await _firestore
        .collection(AppConstants.notificationsCollection)
        .add(notification.toFirestore());
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection(AppConstants.notificationsCollection)
        .doc(notificationId)
        .update({'isRead': true});
  }

  Stream<int> getUnreadNotificationCountStream(String userId) {
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ─── In-app notification tap navigation ──────────────────────────────────────

  void handleNotificationClick(BuildContext context, NotificationModel notification) async {
    markAsRead(notification.id);

    if (notification.type == NotificationType.message && notification.relatedId != null) {
      final sender = await FirestoreService().getUser(notification.senderId);
      if (sender != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: notification.relatedId!,
              otherUser: sender,
              currentUserId: notification.userId,
            ),
          ),
        );
      }
    } else if (notification.type == NotificationType.connectionRequest) {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ConnectionsScreen(initialTab: 1),
          ),
        );
      }
    }
  }
}
