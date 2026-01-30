import 'package:crowdlift/src/core/router/all/auth_routes.dart';
import 'package:crowdlift/src/core/router/all/home_routes.dart';
import 'package:crowdlift/src/core/widgets/custom_snack_bar.dart';
import 'package:crowdlift/src/core/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crowdlift/src/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:crowdlift/src/feature/auth/presentation/bloc/auth_event.dart';
import 'package:crowdlift/src/feature/auth/presentation/bloc/auth_state.dart';
import 'package:crowdlift/src/core/di/service_locator.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => serviceLocator<AuthBloc>(),
      child: const _LoginScreenContent(),
    );
  }
}

class _LoginScreenContent extends StatefulWidget {
  const _LoginScreenContent();

  @override
  State<_LoginScreenContent> createState() => _LoginScreenContentState();
}

class _LoginScreenContentState extends State<_LoginScreenContent> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      showCustomSnackBar(context, 'Please enter both email and password.');
      return;
    }

    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            SignInRequested(
              email: emailController.text,
              password: passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is SignInSuccess) {
          showCustomSnackBar(context, 'Login Successful');
          context.pushReplacement(HomeRoutes.homePage);
        } else if (state is AuthError) {
          showCustomSnackBar(context, state.message);
        }
      },
      child: Scaffold(
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: 400,
                      child: Column(
                        children: [
                          const SizedBox(height: 30),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () {
                                context.push(AuthRoutes.aboutAppPage);
                              },
                              icon: const Icon(Icons.info),
                              color: Colors.white,
                            ),
                          ),
                          Image.asset("assets/images/login.png"),
                          const SizedBox(height: 20),
                          ReusableTextField(
                            controller: emailController,
                            hintText: "Email",
                            prefixIcon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),
                          ReusableTextField(
                            controller: passwordController,
                            hintText: "Password",
                            prefixIcon: Icons.password,
                            isPassword: true,
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                context.push(AuthRoutes.forgotPasswordPage);
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(color: Color(0xFF6750a4)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: isLoading ? null : _handleLogin,
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
                                : const Text("Login"),
                          ),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    context.push(AuthRoutes.registrationPage);
                                  },
                            child: const Text(
                                "Don't have an account? Register here"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        backgroundColor: const Color(0xFF070527),
      ),
    );
  }
}
