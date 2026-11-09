import 'package:campus_care_app/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('renders public student and staff registration choices', (
    tester,
  ) async {
    await pumpConsumerScreen(tester, const RegisterScreen());

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Campus Staff'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Staff Test'), findsNothing);
  });

  testWidgets('shows ALU-domain validation for a non-ALU address', (
    tester,
  ) async {
    await pumpConsumerScreen(
      tester,
      const RegisterScreen(),
      auth: FakeAuthRepository(),
    );
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Sample Student',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'student@example.com',
    );

    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Enter a valid @alustudent.com or @alustaff.com email address.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows password validation errors', (tester) async {
    await pumpConsumerScreen(tester, const RegisterScreen());
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'weak',
    );
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Password must be at least 8 characters.'), findsOneWidget);
  });
}
