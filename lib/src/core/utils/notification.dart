import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:crowdlift/main.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Firebase instances
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Local notifications plugin
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Notification listener
  Stream<QuerySnapshot>? _notificationStream;
  StreamSubscription? _notificationSubscription;

  // Track whether user is online
  bool _isUserOnline = false;

  // Flag to avoid duplicate notifications
  Set<String> _processedNotifications = {};

  // Initialize notification channels and request permissions
  Future<void> initialize() async {
    try {
      // Request permission for iOS and recent Android versions
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print(
          'User notification permission status: ${settings.authorizationStatus}');

      // Configure foreground notification presentation options
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Initialize local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@drawable/ic_launcher_foreground');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Create notification channels for Android
      await _createNotificationChannel();

      // Save FCM token to Firestore
      await _saveTokenToFirestore();

      // Print token for debugging
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');

      // Set up user online status
      _setUserOnline();

      // Start notification listener
      startNotificationListener();

      // Process any pending notifications
      await _processPendingNotifications();

      // Set up message handlers for different app states
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // This still helps with direct FCM messages (if used in the future)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Get initial message if app was opened from a notification
      RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      print('Error initializing notification service: $e');
      // Rethrow to allow handling by the caller
      rethrow;
    }
  }

  // Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'chat_messages', // id
      'Chat Messages', // title
      description: 'Notifications for new chat messages', // description
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        // Parse JSON payload
        Map<String, dynamic> payloadData = jsonDecode(response.payload!);

        String receiverId = payloadData['receiverId'];
        String receiverName = payloadData['receiverName'];

        print('Notification tapped with payload: ${response.payload}');
        print('Navigating to chat with $receiverName (ID: $receiverId)');

        // Navigate to chat screen using the global function
        navigateToChatScreen(receiverId, receiverName);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  // Handle messages when app is in foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      print('Handling foreground message: ${message.messageId}');
      print('Message data: ${message.data}');
      print('Message notification: ${message.notification?.title}');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // Display the notification
      if (notification != null) {
        await _notificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'chat_messages',
              'Chat Messages',
              channelDescription: 'Notifications for new chat messages',
              importance: Importance.high,
              priority: Priority.high,
              icon: android?.smallIcon ?? '@drawable/ic_launcher_foreground',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data['chatId'],
        );
      }
    } catch (e) {
      print('Error handling foreground message: $e');
    }
  }

  // Handle notification tap from background state
  void _handleNotificationTap(RemoteMessage message) {
    try {
      print('Notification tapped in background: ${message.messageId}');
      print('Message data: ${message.data}');
      // Navigate to the appropriate chat screen
      // This needs to be implemented with your navigation service
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }

  // Save FCM token to Firestore
  Future<void> _saveTokenToFirestore() async {
    try {
      String? token = await _firebaseMessaging.getToken();

      // Check if user is authenticated
      if (_auth.currentUser == null) {
        print('User not authenticated, cannot save token');
        return;
      }

      String userId = _auth.currentUser!.uid;

      if (token != null) {
        await _firestore.collection('crowd_user').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });

        // Set up token refresh listener
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          _saveTokenToFirestore();
        });
      }
    } catch (e) {
      print('Error saving token to Firestore: $e');
    }
  }

  // Set user as online
  Future<void> _setUserOnline() async {
    try {
      if (_auth.currentUser == null) return;
      String userId = _auth.currentUser!.uid;

      _isUserOnline = true;

      await _firestore.collection('crowd_user').doc(userId).update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      // Set user as offline when app closes or loses connection
      // This is a simple solution, more robust solutions would use presence system
      _auth.authStateChanges().listen((User? user) {
        if (user == null && _isUserOnline) {
          _setUserOffline();
        }
      });
    } catch (e) {
      print('Error setting user online status: $e');
    }
  }

  // Set user as offline
  Future<void> _setUserOffline() async {
    try {
      if (_auth.currentUser == null) return;
      String userId = _auth.currentUser!.uid;

      _isUserOnline = false;

      await _firestore.collection('crowd_user').doc(userId).update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error setting user offline status: $e');
    }
  }

  // Show a local notification
  Future<void> showLocalChatNotification({
    required String senderName,
    required String message,
    required String senderId, // Add this
  }) async {
    Map<String, dynamic> payloadMap = {
      'receiverId': senderId,
      'receiverName': senderName
    };

    String payloadJson = jsonEncode(payloadMap);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      senderName,
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'chat_messages',
          'Chat Messages',
          channelDescription: 'Notifications for new chat messages',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payloadJson,
    );
  }

  // Public methods that call the private ones
  Future<void> setUserOnline() async {
    await _setUserOnline();
  }

  Future<void> setUserOffline() async {
    await _setUserOffline();
  }

  // Send chat message notification (stores in Firestore)
  Future<void> sendChatNotification({
    required String receiverId,
    required String message,
    required String senderName,
    required String chatId,
  }) async {
    try {
      // Skip if sending to self
      if (receiverId == _auth.currentUser!.uid) {
        print('Skipping notification to self');
        return;
      }

      // Get receiver online status
      DocumentSnapshot userDoc =
          await _firestore.collection('crowd_user').doc(receiverId).get();

      if (userDoc.exists && userDoc.data() is Map<String, dynamic>) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        bool isReceiverOnline = userData['isOnline'] ?? false;

        // Store notification in Firestore regardless of online status
        String notificationId =
            DateTime.now().millisecondsSinceEpoch.toString() +
                '_${_auth.currentUser!.uid}_$receiverId';

        await _firestore.collection('notifications').doc(notificationId).set({
          'title': senderName,
          'body':
              message.length > 100 ? '${message.substring(0, 97)}...' : message,
          'type': 'chat_message',
          'chatId': chatId,
          'senderId': _auth.currentUser!.uid,
          'senderName': senderName, // Add this line
          'receiverId': receiverId,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'processed': false,
        });

        print(
            'Notification created for ${isReceiverOnline ? "online" : "offline"} user $receiverId');
      } else {
        print('Receiver user document not found');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Start listening for new notifications
  void startNotificationListener() {
    if (_auth.currentUser == null) return;
    String userId = _auth.currentUser!.uid;

    // Stop any existing subscription
    stopNotificationListener();

    print('Starting notification listener for user $userId');

    // Create a stream that listens for new notifications for this user
    _notificationStream = _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .where('processed', isEqualTo: false)
        .snapshots();

    // Subscribe to the stream
    _notificationSubscription = _notificationStream?.listen((snapshot) {
      for (var change in snapshot.docChanges) {
        // Only process new notifications
        if (change.type == DocumentChangeType.added) {
          var notification = change.doc.data() as Map<String, dynamic>;
          if (!_processedNotifications.contains(change.doc.id)) {
            _processedNotifications.add(change.doc.id);
            _handleIncomingNotification(notification, change.doc.id);
          }
        }
      }
    }, onError: (error) {
      print('Error in notification listener: $error');
      // Try to restart the listener after a delay
      Future.delayed(Duration(seconds: 10), () {
        startNotificationListener();
      });
    });
  }

  // Process pending notifications when app starts
  Future<void> _processPendingNotifications() async {
    try {
      if (_auth.currentUser == null) return;
      String userId = _auth.currentUser!.uid;

      // Get unprocessed notifications
      QuerySnapshot pendingNotifications = await _firestore
          .collection('notifications')
          .where('receiverId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .where('processed', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(10) // Limit to avoid overwhelming the user
          .get();

      print(
          'Processing ${pendingNotifications.docs.length} pending notifications');

      for (var doc in pendingNotifications.docs) {
        var notification = doc.data() as Map<String, dynamic>;
        if (!_processedNotifications.contains(doc.id)) {
          _processedNotifications.add(doc.id);
          _handleIncomingNotification(notification, doc.id);
        }
      }
    } catch (e) {
      print('Error processing pending notifications: $e');
    }
  }

  // Handle a new notification
  Future<void> _handleIncomingNotification(
      Map<String, dynamic> notification, String notificationId) async {
    try {
      // Create payload with just receiverId and receiverName
      Map<String, dynamic> payloadMap = {
        'receiverId':
            notification['senderId'], // sender becomes receiver when clicked
        'receiverName':
            notification['senderName'] // use sender name as receiver name
      };

      String payloadJson = jsonEncode(payloadMap);

      // Display a local notification
      await _notificationsPlugin.show(
        notificationId.hashCode,
        notification['title'] ?? 'New message',
        notification['body'] ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'chat_messages',
            'Chat Messages',
            channelDescription: 'Notifications for new chat messages',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: payloadJson,
      );

      // Mark as processed
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'processed': true});

      print(
          'Displayed notification: ${notification['title']} with payload: $payloadJson');
    } catch (e) {
      print('Error handling incoming notification: $e');
    }
  }

  // Stop the notification listener
  void stopNotificationListener() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    print('Stopped notification listener');
  }

  // Mark notifications as read for a specific chat
  Future<void> markNotificationsAsRead(String chatId) async {
    try {
      if (_auth.currentUser == null) return;
      String userId = _auth.currentUser!.uid;

      // Get all unread notifications for this chat
      QuerySnapshot notificationSnapshot = await _firestore
          .collection('notifications')
          .where('receiverId', isEqualTo: userId)
          .where('chatId', isEqualTo: chatId)
          .where('read', isEqualTo: false)
          .get();

      // Mark each as read
      for (var doc in notificationSnapshot.docs) {
        await doc.reference.update({'read': true});
      }

      print('Marked ${notificationSnapshot.docs.length} notifications as read');
    } catch (e) {
      print('Error marking notifications as read: $e');
      rethrow;
    }
  }

  // Get unread notification count
  // Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    try {
      if (_auth.currentUser == null) return 0;
      String userId = _auth.currentUser!.uid;

      QuerySnapshot notificationSnapshot = await _firestore
          .collection('notifications')
          .where('receiverId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      return notificationSnapshot.docs.length;
    } catch (e) {
      print('Error getting unread notification count: $e');
      return 0;
    }
  }

  // Clean up resources
  void dispose() {
    stopNotificationListener();
    _processedNotifications.clear();
    _setUserOffline();
  }

  // Reset notification badge count
  Future<void> resetBadgeCount() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      print('Error resetting badge count: $e');
    }
  }
}
