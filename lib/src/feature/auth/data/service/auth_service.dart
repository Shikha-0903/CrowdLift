import 'package:crowdlift/src/core/widgets/custom_snack_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class AuthService {
  Future<void> sendPasswordResetEmail(
      BuildContext context, TextEditingController email) async {
    if (email.text.isEmpty) {
      showCustomSnackBar(
          context, 'Please enter your email to reset the password.');
      return;
    }

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: email.text.trim());
      if (!context.mounted) return;
      showCustomSnackBar(
          context, 'Password reset email sent. Please check your inbox.');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred while sending the reset email.';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      }
      showCustomSnackBar(context, message);
    } catch (e) {
      showCustomSnackBar(context, 'An unexpected error occurred: $e');
    }
  }
}
