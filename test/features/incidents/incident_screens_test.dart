import 'package:campus_care_app/features/auth/domain/entities/app_user.dart';
import 'package:campus_care_app/features/incidents/domain/entities/incident.dart';
import 'package:campus_care_app/features/incidents/domain/entities/incident_comment.dart';
import 'package:campus_care_app/features/incidents/domain/entities/incident_reporter.dart';
import 'package:campus_care_app/features/incidents/presentation/screens/incident_details_screen.dart';
import 'package:campus_care_app/features/incidents/presentation/screens/my_incidents_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_app.dart';

Incident _sampleIncident({String status = 'pending'}) => Incident(
  id: 'incident-1',
  category: 'Water Shortage',
  location: 'Main Library',
  description: 'No water is available on the second floor.',
  status: status,
  createdAt: DateTime(2025, 6, 12, 14, 30),
);

void main() {
  testWidgets('incident list renders the empty state and category filter', (
    tester,
  ) async {
    await pumpConsumerScreen(
      tester,
      const MyIncidentsScreen(category: 'Sanitation'),
      incidents: FakeIncidentRepository(),
    );

    expect(find.text('Sanitation Reports'), findsOneWidget);
    expect(find.text('No Sanitation reports yet'), findsOneWidget);
  });

  testWidgets('incident cards show report details and apply category filters', (
    tester,
  ) async {
    final otherCategory = Incident(
      id: 'incident-2',
      category: 'Sanitation',
      location: 'Student Centre',
      description: 'The washroom requires cleaning.',
      status: 'resolved',
      createdAt: DateTime(2025, 6, 13),
    );
    final repository = FakeIncidentRepository()
      ..incidents = [_sampleIncident(), otherCategory];

    await pumpConsumerScreen(
      tester,
      const MyIncidentsScreen(category: 'Water Shortage'),
      incidents: repository,
      incidentOwnershipLookup: (incidentId) async => incidentId == 'incident-1',
    );

    expect(find.text('No water is available on the second floor.'), findsOneWidget);
    expect(find.text('Main Library'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('My report'), findsOneWidget);
    expect(find.text('The washroom requires cleaning.'), findsNothing);
  });

  testWidgets('student details hide reporter identity and staff controls', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      user: const AppUser(
        id: 'student-1',
        email: 'student@alustudent.com',
        emailVerified: true,
      ),
    );
    final incidentRepository = FakeIncidentRepository()
      ..incident = _sampleIncident()
      ..reporter = const IncidentReporter(
        name: 'Private Reporter',
        email: 'reporter@alustudent.com',
      )
      ..comments = [
        IncidentComment(
          id: 'comment-1',
          incidentId: 'incident-1',
          message: 'A public comment',
          createdAt: DateTime(2025, 6, 12),
        ),
      ];

    await pumpConsumerScreen(
      tester,
      const IncidentDetailsScreen(incidentId: 'incident-1'),
      auth: auth,
      incidents: incidentRepository,
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('A public comment'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('A public comment'), findsOneWidget);
    expect(find.text('No water is available on the second floor.'), findsOneWidget);
    expect(find.text('Campus member'), findsWidgets);
    expect(find.text('Private Reporter'), findsNothing);
    expect(find.text('Update status'), findsNothing);
  });

  testWidgets('staff see reporter details and can change status', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      user: const AppUser(
        id: 'staff-1',
        email: 'staff@alustaff.com',
        role: 'staff',
        accountStatus: 'active',
        emailVerified: true,
      ),
    );
    final incidentRepository = FakeIncidentRepository()
      ..incident = _sampleIncident()
      ..reporter = const IncidentReporter(
        name: 'Test Reporter',
        email: 'reporter@alustudent.com',
      );

    await pumpConsumerScreen(
      tester,
      const IncidentDetailsScreen(incidentId: 'incident-1'),
      auth: auth,
      incidents: incidentRepository,
    );

    expect(find.text('Test Reporter'), findsOneWidget);
    expect(find.text('reporter@alustudent.com'), findsOneWidget);
    expect(find.text('Update status'), findsOneWidget);

    await tester.ensureVisible(
      find.byType(DropdownButtonFormField<String>),
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resolved').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Update Status'));
    await tester.tap(find.text('Update Status'));
    await tester.pumpAndSettle();

    expect(incidentRepository.updatedStatus, 'resolved');
    expect(
      find.text('Incident status updated successfully.'),
      findsOneWidget,
    );
  });

  testWidgets('comments validate empty input and post trimmed text', (
    tester,
  ) async {
    final incidentRepository = FakeIncidentRepository()
      ..incident = _sampleIncident();
    await pumpConsumerScreen(
      tester,
      const IncidentDetailsScreen(incidentId: 'incident-1'),
      incidents: incidentRepository,
    );

    await tester.ensureVisible(find.byIcon(Icons.send));
    await tester.tapAt(const Offset(761, 540));
    await tester.pumpAndSettle();
    expect(find.text('Please write a comment first.'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      '  Please check the water supply.  ',
    );
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(761, 540));
    await tester.pumpAndSettle();
    expect(incidentRepository.postedComment, 'Please check the water supply.');
    expect(find.text('Comment posted successfully!'), findsOneWidget);
  });
}
