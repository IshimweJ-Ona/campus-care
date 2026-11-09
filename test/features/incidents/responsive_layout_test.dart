import 'package:campus_care_app/features/auth/domain/entities/app_user.dart';
import 'package:campus_care_app/features/incidents/domain/entities/incident.dart';
import 'package:campus_care_app/features/incidents/presentation/providers/incident_providers.dart';
import 'package:campus_care_app/features/incidents/presentation/screens/create_incident_screen.dart';
import 'package:campus_care_app/features/incidents/presentation/screens/incident_details_screen.dart';
import 'package:campus_care_app/features/incidents/presentation/screens/my_incidents_screen.dart';
import 'package:campus_care_app/features/home/presentation/screens/home_screen.dart';
import 'package:campus_care_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:campus_care_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:campus_care_app/features/auth/presentation/screens/login_screen.dart';
import 'package:campus_care_app/features/auth/presentation/screens/register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_repositories.dart';

class _FakeFirebaseUser implements User {
  @override
  List<UserInfo> get providerData => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirebaseAuth implements FirebaseAuth {
  @override
  User? get currentUser => _FakeFirebaseUser();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const activeStudent = AppUser(
    id: 'student-1',
    email: 'student@alustudent.com',
    displayName: 'Responsive Student',
    emailVerified: true,
  );
  final incident = Incident(
    id: 'layout-test',
    category: 'Other',
    location: 'Main campus',
    description: 'Layout test incident description.',
    status: 'pending',
    createdAt: DateTime(2025, 5, 1, 12),
  );

  final screenBuilders = <String, Widget Function()>{
    'login': () => const LoginScreen(),
    'registration': () => const RegisterScreen(),
    'home dashboard': () => const HomeScreen(),
    'incident report form': () => const CreateIncidentScreen(),
    'incident list': () => const MyIncidentsScreen(),
    'incident details': () =>
        const IncidentDetailsScreen(incidentId: 'layout-test'),
    'profile': () => const ProfileScreen(),
  };
  final sizes = <String, Size>{
    'small mobile portrait': const Size(320, 568),
    'standard mobile portrait': const Size(390, 844),
    'large mobile portrait': const Size(430, 932),
    'tablet portrait': const Size(800, 1280),
    'small mobile landscape': const Size(568, 320),
    'standard mobile landscape': const Size(844, 390),
    'large mobile landscape': const Size(932, 430),
    'tablet landscape': const Size(1280, 800),
  };

  for (final screen in screenBuilders.entries) {
    for (final size in sizes.entries) {
      testWidgets('${screen.key} has no layout exception at ${size.key}', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size.value;

        final auth = FakeAuthRepository(user: activeStudent);
        final incidents = FakeIncidentRepository()..incident = incident;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(auth),
              incidentRepositoryProvider.overrideWithValue(incidents),
              firebaseAuthProvider.overrideWithValue(_FakeFirebaseAuth()),
            ],
            child: MaterialApp(home: screen.value()),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }
  }
}
