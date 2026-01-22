import 'package:crowdlift/src/feature/home/presentation/pages/home_screen.dart';
import 'package:crowdlift/src/feature/auth/presentation/widgets/on_board.dart';
import 'package:crowdlift/src/feature/auth/presentation/widgets/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'src/core/utils/notification.dart';
import 'src/feature/chat/presentation/pages/chat_screen.dart';

// Create a global navigator key for navigation from outside of context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Define the background handler as a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase for background messages - only if not already initialized
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  debugPrint("Handling a background message: ${message.messageId}");
}

// Global navigation function for notification taps
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
      Future.delayed(const Duration(milliseconds: 500), () {
        navigateToChatScreen(receiverId, receiverName);
      });
    } catch (e) {
      debugPrint('Error handling initial message: $e');
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Error loading .env file: $e');
  }

  // Initialize Firebase with proper error handling
  try {
    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: dotenv.env['API_KEY']!,
          appId: dotenv.env['APP_ID']!,
          messagingSenderId: dotenv.env['MESSAGING_SENDER_ID']!,
          projectId: dotenv.env['PROJECT_ID']!,
        ),
      );
      debugPrint('Firebase initialized successfully');
    } else {
      debugPrint('Firebase already initialized, using existing instance');
    }
  } catch (e) {
    // Catch duplicate app error gracefully
    if (e.toString().contains('duplicate-app')) {
      debugPrint(' Firebase already initialized (caught duplicate-app error)');
    } else {
      debugPrint(' Firebase initialization failed: $e');
      rethrow;
    }
  }

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
        debugPrint('Error handling notification tap: $e');
      }
    }
  });

  // Initialize notification service with error handling
  try {
    await NotificationService().initialize();
    debugPrint('Notification service initialized');
  } catch (e) {
    debugPrint(' Error initializing notifications: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: const AuthStateHandler(),
    );
  }
}

class AuthStateHandler extends StatelessWidget {
  const AuthStateHandler({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasData) {
          return SplashScreen(nextScreen: HomeScreen());
        } else {
          return SplashScreen(nextScreen: OnboardingScreen());
        }
      },
    );
  }
}
