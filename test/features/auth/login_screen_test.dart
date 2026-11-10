import 'dart:async';

import 'package:campus_care_app/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('renders the login form and validates invalid email', (
    tester,
  ) async {
    await pumpConsumerScreen(tester, const LoginScreen());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'not-an-email',
    );
    await tester.ensureVisible(find.text('Login'));
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Enter a valid @alustudent.com or @alustaff.com email address.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('explains how to enable the local Staff Test account', (
    tester,
  ) async {
    await pumpConsumerScreen(tester, const LoginScreen());

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'staff.test@campuscare.dev',
    );
    await tester.ensureVisible(find.text('Login'));
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Staff Test sign-in requires Firebase emulators.'),
      findsOneWidget,
    );
  });

  testWidgets('toggles password visibility', (tester) async {
    await pumpConsumerScreen(tester, const LoginScreen());

    final passwordField = find.byType(TextFormField).at(1);
    final editablePassword = find.descendant(
      of: passwordField,
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(editablePassword).obscureText, isTrue);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();

    expect(tester.widget<EditableText>(editablePassword).obscureText, isFalse);
    expect(find.byTooltip('Hide password'), findsOneWidget);
  });

  testWidgets('shows a loading indicator and auth error', (tester) async {
    final auth = FakeAuthRepository()
      ..loginCompleter = Completer();
    await pumpConsumerScreen(tester, const LoginScreen(), auth: auth);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'student@alustudent.com',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'any-password',
    );

    await tester.ensureVisible(find.text('Login'));
    await tester.tap(find.text('Login'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    auth.loginCompleter!.completeError(StateError('Sign-in was rejected.'));
    await tester.pumpAndSettle();
    expect(find.text('Sign-in was rejected.'), findsOneWidget);
  });
}
