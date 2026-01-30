import 'package:crowdlift/src/core/widgets/splash_screen.dart';
import 'package:crowdlift/src/feature/auth/presentation/widgets/on_board.dart';
import 'package:crowdlift/src/feature/home/presentation/pages/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
