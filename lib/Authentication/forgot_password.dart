import 'package:crowdlift/widgets/custom_snack_bar.dart';
import 'package:crowdlift/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController emailController = TextEditingController();

  Future<void> sendPasswordResetEmail() async {
    if (emailController.text.isEmpty) {
      showCustomSnackBar(context, 'Please enter your email to reset the password.');
      return;
    }

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: emailController.text.trim());
      showCustomSnackBar(context, 'Password reset email sent. Please check your inbox.');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child:
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: 400,
              child: Column(

                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 80,),
                  Image(image: AssetImage("assets/images/login.png")),
                  ReusableTextField(
                    controller: emailController,
                    hintText: "Email",
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email, // Mandatory Prefix Icon
                  ),
                  SizedBox(height: 20,),
                  ElevatedButton(
                    onPressed: sendPasswordResetEmail,
                    child: Text("Send password"),
                  ),
                ],
              ),
            ),
          ),
        )
      ),
      backgroundColor: const Color(0xFF070527),
    );
  }
}
