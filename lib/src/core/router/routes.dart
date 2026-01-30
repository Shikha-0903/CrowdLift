import 'package:crowdlift/src/core/router/all/auth_routes.dart';
import 'package:crowdlift/src/core/router/all/home_routes.dart';
import 'package:go_router/go_router.dart';

final GoRouter router = GoRouter(initialLocation: AuthRoutes.authGate, routes: [
  ...AuthRoutes.routes,
  ...HomeRoutes.routes,
]);
