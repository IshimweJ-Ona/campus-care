import 'dart:async';

import 'package:campus_care_app/features/auth/domain/entities/app_user.dart';
import 'package:campus_care_app/features/home/presentation/screens/home_screen.dart';
import 'package:campus_care_app/features/incidents/domain/entities/incident.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  final reports = [
    Incident(
      id: 'report-1',
      category: 'Water Shortage',
      location: 'Library',
      description: 'Water service is unavailable.',
      status: 'pending',
      createdAt: DateTime.utc(2025, 1, 1),
    ),
    Incident(
      id: 'report-2',
      category: 'Safety Concern',
      location: 'East Gate',
      description: 'A light is out near the gate.',
      status: 'resolved',
      createdAt: DateTime.utc(2025, 1, 2),
    ),
  ];

  testWidgets('approved staff see the dashboard and incident statistics', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      user: const AppUser(
        id: 'staff-1',
        email: 'staff@alustaff.com',
        displayName: 'Campus Staff',
        role: 'staff',
        accountStatus: 'active',
        emailVerified: true,
      ),
    );
    final incidentRepository = FakeIncidentRepository()..incidents = reports;

    await pumpConsumerScreen(
      tester,
      const HomeScreen(),
      auth: auth,
      incidents: incidentRepository,
    );

    await tester.scrollUntilVisible(
      find.text('Incident Statistics'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Incident Statistics'), findsOneWidget);
    expect(find.text('View Campus Reports'), findsOneWidget);
    expect(find.text('Pending Review'), findsOneWidget);
  });

  testWidgets('students see reporting but not staff statistics', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      user: const AppUser(
        id: 'student-1',
        email: 'student@alustudent.com',
        displayName: 'Campus Student',
        emailVerified: true,
      ),
    );
    await pumpConsumerScreen(
      tester,
      const HomeScreen(),
      auth: auth,
      incidents: FakeIncidentRepository(),
    );

    expect(find.text('Report an Incident'), findsOneWidget);
    expect(find.text('Incident Statistics'), findsNothing);
    expect(find.text('View Campus Reports'), findsNothing);
  });

  testWidgets('students get notifications for other users reports only', (
    tester,
  ) async {
    final controller = StreamController<List<Incident>>();
    controller.add([]);
    addTearDown(controller.close);
    final incidentRepository = FakeIncidentRepository()
      ..incidentsStream = controller.stream;
    final auth = FakeAuthRepository(
      user: const AppUser(
        id: 'student-1',
        email: 'student@alustudent.com',
        displayName: 'Campus Student',
        emailVerified: true,
      ),
    );

    await pumpConsumerScreen(
      tester,
      const HomeScreen(),
      auth: auth,
      incidents: incidentRepository,
      incidentOwnershipLookup: (incidentId) async => incidentId == 'my-report',
    );

    controller.add([
      Incident(
        id: 'my-report',
        category: 'My report',
        location: 'North Hall',
        description: 'Submitted by this student.',
        status: 'pending',
        createdAt: DateTime.utc(2025, 1, 3),
      ),
      Incident(
        id: 'other-report',
        category: 'Other report',
        location: 'South Hall',
        description: 'Submitted by someone else.',
        status: 'pending',
        createdAt: DateTime.utc(2025, 1, 4),
      ),
    ]);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Other report'), findsOneWidget);
    expect(find.text('My report'), findsNothing);
  });

  testWidgets('staff get notifications for newly reported incidents', (
    tester,
  ) async {
    final controller = StreamController<List<Incident>>();
    controller.add([]);
    addTearDown(controller.close);
    final incidentRepository = FakeIncidentRepository()
      ..incidentsStream = controller.stream;
    final auth = FakeAuthRepository(
      user: const AppUser(
        id: 'staff-1',
        email: 'staff@alustaff.com',
        displayName: 'Campus Staff',
        role: 'staff',
        accountStatus: 'active',
        emailVerified: true,
      ),
    );

    await pumpConsumerScreen(
      tester,
      const HomeScreen(),
      auth: auth,
      incidents: incidentRepository,
      incidentOwnershipLookup: (incidentId) async {
        throw StateError('Staff should not check student report ownership.');
      },
    );

    controller.add([reports.first]);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();

    expect(find.text('Water Shortage'), findsOneWidget);
  });

  testWidgets('pending staff do not see approved staff features', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      user: const AppUser(
        id: 'pending-staff',
        email: 'pending@alustaff.com',
        role: 'pending_staff',
        accountStatus: 'pending',
        emailVerified: true,
      ),
    );
    await pumpConsumerScreen(
      tester,
      const HomeScreen(),
      auth: auth,
      incidents: FakeIncidentRepository(),
    );

    expect(find.text('Incident Statistics'), findsNothing);
    expect(find.text('Back to Login'), findsOneWidget);
  });
}
