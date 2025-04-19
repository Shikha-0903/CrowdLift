import 'package:crowdlift/home_screen.dart';
import 'package:crowdlift/on_board.dart';
import 'package:crowdlift/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'utils/notification.dart';
import 'chat/chat_screen.dart';
// Create a global navigator key for navigation from outside of context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Define the background handler as a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase for background messages
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

// Global navigation function for notification taps - simplified for your ChatScreen
void navigateToChatScreen(String receiverId, String receiverName) {
  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (context) => ChatScreen(
        receiverId: receiverId,
        receiverName: receiverName,
      ),
    ),
  );
}

// Handle initial message when app is opened from terminated state
void handleInitialMessage(RemoteMessage? message) {
  if (message != null && message.data.isNotEmpty) {
    try {
      final data = message.data;
      final receiverId = data['receiverId'];
      final receiverName = data['receiverName'];

      // Delay navigation slightly to ensure app is fully initialized
      Future.delayed(Duration(milliseconds: 500), () {
        navigateToChatScreen(receiverId, receiverName);
      });
    } catch (e) {
      print('Error handling initial message: $e');
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['API_KEY']!,
      appId: dotenv.env['APP_ID']!,
      messagingSenderId: dotenv.env['MESSAGING_SENDER_ID']!,
      projectId: dotenv.env['PROJECT_ID']!,
    ),
  );

  // Register the background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Handle case where app was terminated and opened via notification
  FirebaseMessaging.instance.getInitialMessage().then(handleInitialMessage);

  // Handle notification clicks when app is in background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (message.data.isNotEmpty) {
      try {
        final data = message.data;
        final receiverId = data['receiverId'];
        final receiverName = data['receiverName'];

        navigateToChatScreen(receiverId, receiverName);
      } catch (e) {
        print('Error handling notification tap: $e');
      }
    }
  });

  // Initialize notification service
  await NotificationService().initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Add the navigator key here
      debugShowCheckedModeBanner: false,
      home: AuthStateHandler(),
    );
  }
}

class AuthStateHandler extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use FirebaseAuth to check the current user
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the user is logged in, redirect to HomeScreen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasData) {
          return SplashScreen(nextScreen: HomeScreen()); // User is logged in
        } else {
          return SplashScreen(nextScreen: OnboardingScreen()); // User is not logged in
        }
      },
    );
  }
}