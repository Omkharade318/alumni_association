import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Request permission first
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get token with error handling
        try {
          final token = await _messaging.getToken();
          if (token != null && kDebugMode) {
            print('FCM Token: $token');
            // TODO: Store token in Firestore for the user when they're logged in
          }
        } catch (e) {
          print('Error getting FCM token: $e');
          // Continue without FCM token - app should still work
        }
      } else {
        print('FCM permission denied: ${settings.authorizationStatus}');
      }
      
      _isInitialized = true;
    } catch (e) {
      print('Error initializing FCM: $e');
      // Don't rethrow - app should work without notifications
      _isInitialized = true;
    }
  }

  void configureHandlers() {
    if (!_isInitialized) {
      print('FCM not initialized, skipping handler configuration');
      return;
    }

    try {
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Received foreground message: ${message.messageId}');
        }
        // TODO: Show in-app notification
      });

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Message clicked: ${message.messageId}');
        }
        // TODO: Navigate to relevant screen
      });

      // Handle notification tap when app is completely closed
      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
        if (message != null && kDebugMode) {
          print('App opened from notification: ${message.messageId}');
        }
        // TODO: Handle initial notification
      });
    } catch (e) {
      print('Error configuring FCM handlers: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      return await _messaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> storeTokenForUser(String userId) async {
    try {
      final token = await getToken();
      if (token != null) {
        // TODO: Store token in Firestore
        // await FirebaseFirestore.instance
        //   .collection('users')
        //   .doc(userId)
        //   .update({'fcmToken': token});
        print('FCM token stored for user: $userId');
      }
    } catch (e) {
      print('Error storing FCM token: $e');
    }
  }

  Future<void> removeTokenForUser(String userId) async {
    try {
      // TODO: Remove token from Firestore
      // await FirebaseFirestore.instance
      //   .collection('users')
      //   .doc(userId)
      //   .update({'fcmToken': FieldValue.delete()});
      print('FCM token removed for user: $userId');
    } catch (e) {
      print('Error removing FCM token: $e');
    }
  }
}
