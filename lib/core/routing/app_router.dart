
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/incidents/presentation/screens/create_incident_screen.dart';
import '../../features/incidents/presentation/screens/edit_incident_screen.dart';
import '../../features/incidents/presentation/screens/incident_details_screen.dart';
import '../../features/incidents/presentation/screens/my_incidents_screen.dart';
import '../../features/staff/presentation/screens/pending_staff_screen.dart';

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
        child: SlideTransition(
          position: slideAnimation,
          child: child,
        ),
      );
    },
  );
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
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
        child: EditIncidentScreen(
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
