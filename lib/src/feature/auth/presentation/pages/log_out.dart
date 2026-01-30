import 'package:crowdlift/src/core/router/all/auth_routes.dart';
import 'package:crowdlift/src/core/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class LogoutHelper {
  static void showLogoutDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental closing
      barrierLabel: "Logout",
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      pageBuilder: (context, _, __) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Color(0xFF070527), // Consistent app theme color
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_rounded,
                    color: Colors.white, size: 24),
                const SizedBox(width: 10),
                const Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          content: const Text(
            "Are you sure you want to logout?",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.grey.shade600,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text("Cancel", style: TextStyle(fontSize: 15)),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  context.go(AuthRoutes.loginScreen);
                  showCustomSnackBar(context, "We will meet Soon");
                }
              },
              child: const Text("Logout", style: TextStyle(fontSize: 15)),
            ),
          ],
        );
      },
    );
  }
}
