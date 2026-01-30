import 'package:crowdlift/src/core/widgets/custom_snack_bar.dart';
import 'package:crowdlift/src/core/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crowdlift/src/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:crowdlift/src/feature/auth/presentation/bloc/auth_event.dart';
import 'package:crowdlift/src/feature/auth/presentation/bloc/auth_state.dart';
import 'package:crowdlift/src/core/di/service_locator.dart';

class ForgotPassword extends StatelessWidget {
  const ForgotPassword({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => serviceLocator<AuthBloc>(),
      child: const _ForgotPasswordContent(),
    );
  }
}

class _ForgotPasswordContent extends StatefulWidget {
  const _ForgotPasswordContent();

  @override
  State<_ForgotPasswordContent> createState() => _ForgotPasswordContentState();
}

class _ForgotPasswordContentState extends State<_ForgotPasswordContent> {
  final TextEditingController emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void _handleSendPasswordResetEmail() {
    if (emailController.text.isEmpty) {
      showCustomSnackBar(
          context, 'Please enter your email to reset the password.');
      return;
    }

    context.read<AuthBloc>().add(
          SendPasswordResetEmailRequested(email: emailController.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is PasswordResetEmailSent) {
          showCustomSnackBar(
              context, 'Password reset email sent. Please check your inbox.');
          Navigator.pop(context);
        } else if (state is AuthError) {
          showCustomSnackBar(context, state.message);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Scaffold(
            body: SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: 400,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 80),
                        Image.asset("assets/images/login.png"),
                        ReusableTextField(
                          controller: emailController,
                          hintText: "Email",
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed:
                              isLoading ? null : _handleSendPasswordResetEmail,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text("Send Password"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            backgroundColor: const Color(0xFF070527),
          );
        },
      ),
    );
  }
}
