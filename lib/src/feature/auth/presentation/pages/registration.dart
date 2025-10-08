import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crowdlift/src/feature/auth/presentation/pages/login_screen.dart';
import 'package:crowdlift/src/core/widgets/custom_snack_bar.dart';
import 'package:crowdlift/src/core/widgets/custom_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  String? _selectedRole;
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>(); // Form key for validation

  // Validation functions
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (RegExp(r'[0-9]').hasMatch(value)) {
      return "Name should not contain number";
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    if (!EmailValidator.validate(value)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    // Check for parentheses
    if (value.contains('(') ||
        value.contains(')') ||
        value.contains('[') ||
        value.contains(']') ||
        value.contains('{') ||
        value.contains('}')) {
      return 'Password cannot contain parentheses';
    }

    // Check for uppercase letters
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for lowercase letters
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for numbers
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    // Check if password contains at least one of the special characters
    if (!RegExp(r'[@$#%]').hasMatch(value)) {
      return "Password must contain at least one special character";
    }
    if (value.contains(" ")) {
      return "Password should not contain white space";
    }
    // Check for special characters (excluding parentheses)

    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    // Basic phone number validation (adjust based on your region's requirements)
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  Future<bool> isPhoneNumberExists(String phoneNumber) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('crowd_user') // Change to your Firestore collection name
          .where('phone', isEqualTo: phoneNumber)
          .get();

      return querySnapshot.docs.isNotEmpty; // If found, phone number exists
    } catch (e) {
      debugPrint('Error checking phone number: $e');
      return false; // Assume not found on error
    }
  }

  Future<void> registerUser() async {
    if (_formKey.currentState!.validate()) {
      // Check if a role is selected
      if (_selectedRole == null) {
        showCustomSnackBar(context, "Please select your role");
        return; // Exit the function if no role is selected
      }

      bool phoneExists = await isPhoneNumberExists(_phoneController.text);
      if (!mounted) return;
      if (phoneExists) {
        showCustomSnackBar(
            context, 'Phone number already exists. Please use another number.');
        return;
      }
      // Show the terms dialog before proceeding with registration
      bool? termsAccepted = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return TermsDialog(
            termsAccepted: false,
            onAccept: (bool value) {},
          );
        },
      );

      if (termsAccepted != null && termsAccepted) {
        try {
          // Create a user in Firebase Authentication
          UserCredential userCredential =
              await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );

          // Save user data to Firestore
          FirebaseFirestore.instance
              .collection('crowd_user')
              .doc(userCredential.user!.uid)
              .set({
            'name': _nameController.text,
            'email': _emailController.text,
            'phone': _phoneController.text,
            'role': _selectedRole,
            'uid': userCredential.user!.uid,
            'description': 'Not mentioned',
            'capacity_about': 'Not mentioned',
            'interest_expect': 'Not mentioned',
            'profile_image': 'Note mentioned',
            'aim': 'Not mentioned'
          }, SetOptions(merge: true));

          // Show success message
          if (!mounted) return;
          showCustomSnackBar(context, 'Registration successful!');

          // Navigate to login screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    LoginScreen()), // Make sure LoginScreen is implemented
          );
        } on FirebaseAuthException catch (e) {
          String errorMessage = 'Registration failed';

          // Handle specific Firebase Auth errors with more user-friendly messages
          if (e.code == 'email-already-in-use') {
            errorMessage =
                'This email is already registered. Please use another email or login.';
          } else if (e.code == 'weak-password') {
            errorMessage =
                'The password provided is too weak. Please use a stronger password.';
          } else if (e.code == 'invalid-email') {
            errorMessage = 'The email address is not valid.';
          } else if (e.message != null) {
            errorMessage = e.message!;
          }
          if (!mounted) return;

          showCustomSnackBar(context, errorMessage);
        } catch (e) {
          if (!mounted) return;
          showCustomSnackBar(context,
              'An error occurred during registration. Please try again.');
        }
      } else {
        if (!mounted) return;
        showCustomSnackBar(context, 'You must accept the terms and conditions');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: 400,
              child: Form(
                key: _formKey, // Use the form key to manage validation
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset("assets/images/login.png"),
                    const SizedBox(height: 10),
                    ReusableTextField(
                      controller: _nameController,
                      hintText: "Name",
                      prefixIcon: Icons.person,
                      validator: validateName,
                    ),
                    const SizedBox(height: 20),
                    ReusableTextField(
                      controller: _emailController,
                      hintText: "Email",
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: validateEmail,
                    ),
                    const SizedBox(height: 20),
                    ReusableTextField(
                      controller: _passwordController,
                      hintText: "Password",
                      prefixIcon: Icons.password,
                      isPassword: true,
                      validator: validatePassword,
                    ),
                    const SizedBox(height: 20),
                    ReusableTextField(
                      controller: _phoneController,
                      hintText: "Phone no.",
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: validatePhone,
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Text(
                          "Select your role",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    RadioGroup<String>(
                      groupValue: _selectedRole,
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value;
                        });
                      },
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: const Text(
                              "Seeker",
                              style: TextStyle(color: Color(0xFF6750A4)),
                            ),
                            value: "Seeker",
                          ),
                          RadioListTile<String>(
                            title: const Text(
                              "Investor",
                              style: TextStyle(color: Color(0xFF6750A4)),
                            ),
                            value: "Investor",
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed:
                          registerUser, // Call registerUser function on press
                      child: Text("Register"),
                    ),
                    SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginScreen()),
                        );
                      },
                      child: Text("Go to Login"),
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

class TermsDialog extends StatefulWidget {
  final bool termsAccepted;
  final ValueChanged<bool> onAccept;

  const TermsDialog(
      {required this.termsAccepted, required this.onAccept, super.key});

  @override
  State<TermsDialog> createState() => _TermsDialogState();
}

class _TermsDialogState extends State<TermsDialog> {
  late bool termsAccepted;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    termsAccepted = widget.termsAccepted;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20), // Rounded corners for a modern look
      ),
      titlePadding: EdgeInsets.zero, // Remove default padding for custom header
      title: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6750a4), Color(0xFF9575cd)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          children: [
            const Icon(Icons.policy, color: Colors.white, size: 26),
            const SizedBox(width: 10),
            const Text(
              'Terms & Conditions',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      content: SizedBox(
        height: 270, // Adjusted height for better spacing
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "By using this application, you agree to the following terms and conditions:\n",
                      style: TextStyle(
                        color: Color(0xFF070527),
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: Color(0xFF6750a4),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 5,
                            offset: Offset(2, 2),
                          )
                        ],
                      ),
                      child: const Text(
                        '✔ Do not share sensitive or private information without consent.\n'
                        '✔ The app is not responsible for any loss, damages, or security issues.\n'
                        '✔ Users must comply with applicable laws.\n'
                        '✔ Violation of terms may result in account termination.\n'
                        '✔ Content uploaded must adhere to community guidelines.\n',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        'Please read carefully before accepting.',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Transform.scale(
                  scale: 1.2, // Larger checkbox for better usability
                  child: Checkbox(
                    value: termsAccepted,
                    activeColor: Color(0xFF6750a4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                    onChanged: (value) {
                      setState(() {
                        termsAccepted = value ?? false;
                      });
                      widget.onAccept(termsAccepted);
                    },
                  ),
                ),
                const SizedBox(width: 5),
                const Expanded(
                  child: Text(
                    'I accept the terms and conditions.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          onPressed:
              termsAccepted ? () => Navigator.of(context).pop(true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF6750a4),
            disabledBackgroundColor: Colors.grey[400],
            shadowColor: Colors.black45,
            elevation: 5,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Accept & Continue',
              style: TextStyle(color: Colors.white, fontSize: 14)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: Colors.redAccent,
          ),
          child: const Text('Reject',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
