import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/verify_email_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/incidents/presentation/screens/create_incident_screen.dart';
import '../../features/incidents/presentation/screens/incident_details_screen.dart';
import '../../features/incidents/presentation/screens/my_incidents_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/staff/presentation/screens/pending_staff_screen.dart';

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable() {
    _subscription = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

String? _accountDestination(AppUser user) {
  if (user.role == 'pending_staff' &&
      user.accountStatus == 'pending') {
    return '/pending-staff';
  }

  if ((user.role == 'student' || user.role == 'staff') &&
      user.accountStatus == 'active') {
    return '/home';
  }

  return null;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final refreshListenable = _AuthRefreshListenable();

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) async {
      final path = state.uri.path;
      const publicPaths = {
        '/splash',
        '/register',
        '/login',
        '/forgot-password',
      };

      if (publicPaths.contains(path)) return null;

      AppUser? user;
      try {
        user = await repository.getCurrentUser();
      } on StateError {
        return '/login';
      } on FirebaseAuthException {
        return '/login';
      } on FirebaseException {
        return '/login';
      }

      if (user == null) return '/login';

      if (path == '/verify-email') {
        if (!user.emailVerified) return null;
        return _accountDestination(user) ?? '/login';
      }

      if (!user.emailVerified) return '/verify-email';

      final destination = _accountDestination(user);
      if (destination == null) return '/login';

      if (destination == '/pending-staff') {
        return path == '/pending-staff' ? null : destination;
      }

      if (path == '/pending-staff') return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/verify-email',
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: const VerifyEmailScreen(),
        ),
      ),
      GoRoute(
        path: '/pending-staff',
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: const PendingStaffScreen(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: const ProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/incidents',
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: MyIncidentsScreen(
            category: state.uri.queryParameters['category'],
          ),
        ),
      ),
      GoRoute(
        path: '/incidents/create',
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: CreateIncidentScreen(
            initialCategory: state.uri.queryParameters['category'],
          ),
        ),
      ),
      GoRoute(
        path: '/incidents/:incidentId/edit',
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: IncidentDetailsScreen(
            incidentId: state.pathParameters['incidentId']!,
          ),
        ),
      ),
      GoRoute(
        path: '/incidents/:incidentId',
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: IncidentDetailsScreen(
            incidentId: state.pathParameters['incidentId']!,
          ),
        ),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refreshListenable.dispose();
  });

  return router;
});

CustomTransitionPage<void> _buildPageWithTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 650),
    reverseTransitionDuration: const Duration(milliseconds: 450),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
      );

      final slideAnimation = Tween<Offset>(
        begin: const Offset(0.06, 0),
        end: Offset.zero,
      ).animate(fadeAnimation);

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(position: slideAnimation, child: child),
      );
    },
  );
}
