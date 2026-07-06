import 'package:go_router/go_router.dart';
import '../features/auth/auth_wrapper.dart';
import '../features/auth/register_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AuthWrapper()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
  ],
);
