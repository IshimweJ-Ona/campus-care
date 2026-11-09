import 'dart:async';
import 'dart:io';

import 'package:campus_care_app/features/incidents/presentation/screens/create_incident_screen.dart';
import 'package:campus_care_app/features/incidents/presentation/providers/incident_providers.dart';
import 'package:campus_care_app/shared/services/cloudinary_service.dart';
import 'package:campus_care_app/shared/services/image_picker_service.dart';
import 'package:campus_care_app/shared/services/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_app.dart';

class _FakeCloudinaryService extends CloudinaryService {
  @override
  Future<String> uploadImage(
    File imageFile, {
    required CloudinaryImageType imageType,
  }) async =>
      'https://res.cloudinary.com/vbzq5ssu/image/upload/test.png';
}

class _FakeImagePickerService extends ImagePickerService {
  @override
  Future<File?> pickFromGallery() async => null;
}

void main() {
  testWidgets('renders category, image picker and required fields', (
    tester,
  ) async {
    await pumpConsumerScreen(tester, const CreateIncidentScreen());

    expect(find.text('Create Incident'), findsOneWidget);
    expect(find.text('Incident category'), findsOneWidget);
    expect(find.text('Add a photo of the issue'), findsOneWidget);
    expect(find.text('Submit Incident'), findsOneWidget);

    await tester.ensureVisible(find.text('Submit Incident'));
    await tester.tap(find.text('Submit Incident'));
    await tester.pumpAndSettle();
    expect(find.text('Please select an incident category'), findsOneWidget);
    expect(find.text('Please enter the incident location'), findsOneWidget);
    expect(find.text('Please describe the incident'), findsOneWidget);
  });

  testWidgets('opens and dismisses the image selection options', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          imagePickerServiceProvider.overrideWithValue(
            _FakeImagePickerService(),
          ),
        ],
        child: const MaterialApp(home: CreateIncidentScreen()),
      ),
    );

    await tester.ensureVisible(find.text('Add a photo of the issue'));
    await tester.tap(find.text('Add a photo of the issue'));
    await tester.pumpAndSettle();
    expect(find.text('Choose from gallery'), findsOneWidget);
    expect(find.text('Take a photo'), findsOneWidget);
    await tester.tapAt(const Offset(400, 200));
    await tester.pumpAndSettle();
    expect(find.text('Choose from gallery'), findsNothing);
  });

  testWidgets('selects a category and submits a valid report', (tester) async {
    final incidents = FakeIncidentRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          incidentRepositoryProvider.overrideWithValue(incidents),
          cloudinaryServiceProvider.overrideWithValue(_FakeCloudinaryService()),
          imagePickerServiceProvider.overrideWithValue(
            _FakeImagePickerService(),
          ),
        ],
        child: const MaterialApp(home: CreateIncidentScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Other').first);
    await tester.tap(find.text('Other').first);
    await tester.ensureVisible(find.byType(TextFormField).at(0));
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Main Library',
    );
    await tester.ensureVisible(find.byType(TextFormField).at(1));
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'A broken water dispenser needs repair.',
    );
    await tester.ensureVisible(find.text('Submit Incident'));
    await tester.tap(find.text('Submit Incident'));
    await tester.pumpAndSettle();

    expect(incidents.createCalls, 1);
    expect(incidents.createdCategory, 'Other');
    expect(incidents.createdLocation, 'Main Library');
    expect(find.text('Incident reported successfully!'), findsOneWidget);
  });

  testWidgets('shows progress and a failure message while submitting', (
    tester,
  ) async {
    final incidents = FakeIncidentRepository()
      ..createCompleter = Completer<String>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          incidentRepositoryProvider.overrideWithValue(incidents),
        ],
        child: const MaterialApp(home: CreateIncidentScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Other').first);
    await tester.tap(find.text('Other').first);
    await tester.ensureVisible(find.byType(TextFormField).at(0));
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Main Library',
    );
    await tester.ensureVisible(find.byType(TextFormField).at(1));
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'A broken water dispenser needs repair.',
    );
    await tester.ensureVisible(find.text('Submit Incident'));
    await tester.tap(find.text('Submit Incident'));
    await tester.pump();
    expect(find.text('Submitting report...'), findsOneWidget);

    incidents.createCompleter!.completeError(StateError('Emulator offline.'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Emulator offline.'),
      findsOneWidget,
    );
  });
}
