import 'package:campus_care_app/features/auth/domain/entities/app_user.dart';
import 'package:campus_care_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:campus_care_app/features/incidents/presentation/providers/incident_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_repositories.dart';

Future<void> pumpConsumerScreen(
  WidgetTester tester,
  Widget screen, {
  FakeAuthRepository? auth,
  FakeIncidentRepository? incidents,
  Future<bool> Function(String incidentId)? incidentOwnershipLookup,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          auth ?? FakeAuthRepository(user: const AppUser(
            id: 'student-1',
            email: 'student@alustudent.com',
            displayName: 'Test Student',
            emailVerified: true,
          )),
        ),
        if (incidents != null)
          incidentRepositoryProvider.overrideWithValue(incidents),
        if (incidentOwnershipLookup != null)
          reportedIncidentLookupProvider.overrideWithValue(
            incidentOwnershipLookup,
          ),
      ],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
}
