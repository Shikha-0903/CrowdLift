import 'package:crowdlift/src/core/widgets/about_app.dart';
import 'package:crowdlift/src/feature/auth/presentation/pages/auth_gate.dart';
import 'package:crowdlift/src/feature/auth/presentation/pages/forgot_password.dart';
import 'package:crowdlift/src/feature/auth/presentation/pages/login_screen.dart';
import 'package:crowdlift/src/feature/auth/presentation/pages/registration.dart';
import 'package:go_router/go_router.dart';

class AuthRoutes {
  static const String authGate = "/auth-gate";
  static const String loginScreen = "/login-screen";
  static const String registrationPage = "/registration-page";
  static const String forgotPasswordPage = "/forgot-password-page";
  static const String aboutAppPage = "/about-app-page";
  static final List<GoRoute> routes = [
    GoRoute(path: loginScreen, builder: (_, __) => LoginScreen()),
    GoRoute(path: registrationPage, builder: (_, __) => RegistrationScreen()),
    GoRoute(path: forgotPasswordPage, builder: (_, __) => ForgotPassword()),
    GoRoute(path: aboutAppPage, builder: (_, __) => AboutApp()),
    GoRoute(path: authGate, builder: (_, __) => AuthStateHandler()),
  ];
}
