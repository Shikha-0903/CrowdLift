import 'package:crowdlift/Authentication/registration.dart';
import 'package:crowdlift/about_app.dart';
import 'package:crowdlift/widgets/custom_snack_bar.dart';
import 'package:crowdlift/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crowdlift/home_screen.dart';
import 'forgot_password.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();


  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      showCustomSnackBar(context, 'Please enter both email and password.');
      return;
    }

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      showCustomSnackBar(context, 'Login Successful');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'user-disabled':
          message = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many login attempts. Try again later.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password login is disabled.';
          break;
        case 'invalid-credential':
        // For both unregistered emails and wrong passwords
          message = 'The email is not registered or the password is incorrect.';
          break;
        default:
          message = e.message ?? 'An unknown error occurred';
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
        child: Form(
          key: _formKey,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: 400,
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AboutApp()),
                          );
                        },
                        icon: Icon(Icons.info),
                        color: Colors.white,
                      ),
                    ),
                    Image.asset("assets/images/login.png"),
                    const SizedBox(height: 20),
                    ReusableTextField(controller: emailController, hintText: "Email", prefixIcon: Icons.email,keyboardType: TextInputType.emailAddress,),
                    const SizedBox(height: 20),
                    ReusableTextField(controller: passwordController, hintText: "Password", prefixIcon: Icons.password,isPassword: true,),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>ForgotPassword()));
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Color(0xFF6750a4)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          login();
                        }
                      },
                      child: const Text("Login"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => RegistrationScreen()),
                        );
                      },
                      child: const Text("Don't have an account? Register here"),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFF070527),
    );
  }
}
