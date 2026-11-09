import 'package:campus_care_app/core/utils/incident_validation.dart';
import 'package:campus_care_app/core/utils/image_file_validation.dart';
import 'package:campus_care_app/features/incidents/data/repositories/incident_repository_impl.dart';
import 'package:campus_care_app/features/incidents/domain/entities/incident.dart';
import 'package:campus_care_app/features/incidents/domain/entities/incident_comment.dart';
import '../../helpers/fake_repositories.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Incident entity and Firestore mapping', () {
    final date = DateTime.utc(2025, 6, 12, 14, 30);

    test('constructs and copies immutable incident values', () {
      final incident = Incident(
        id: 'report-1',
        category: 'Water Shortage',
        location: 'Main Library',
        description: 'No water available on the second floor.',
        status: 'pending',
        createdAt: date,
        photoUrl: 'https://example.test/photo.png',
      );

      expect(incident.createdAt.toUtc(), date);
      expect(incident.photoUrl, 'https://example.test/photo.png');
      expect(incident.copyWith(status: 'resolved').status, 'resolved');
      expect(incident.copyWith(status: 'resolved').id, incident.id);
    });

    test('maps Firestore timestamps and DateTime values', () async {
      final source = FakeIncidentRemoteDataSource()
        ..incidents = [
          {
            'id': 'timestamp',
            'category': 'Safety Concern',
            'location': 'East Gate',
            'description': 'The light is not working.',
            'status': 'in_progress',
            'createdAt': Timestamp.fromDate(date),
            'photoUrl': null,
          },
          {
            'id': 'datetime',
            'category': 'Other',
            'location': 'Hall',
            'description': 'The door needs repair.',
            'status': 'resolved',
            'createdAt': date,
            'photoUrl': null,
          },
        ];
      final repository = IncidentRepositoryImpl(
        remoteDataSource: source,
      );

      final incidents = await repository.getAllIncidents();
      expect(incidents, hasLength(2));
      expect(incidents.first.createdAt.toUtc(), date);
      expect(incidents.first.status, 'in_progress');
      expect(incidents.last.createdAt, date);
    });

    test('maps comment fields without exposing author identity to students',
        () async {
      final source = FakeIncidentRemoteDataSource()
        ..comments = [
          {
            'id': 'comment-1',
            'incidentId': 'report-1',
            'message': 'Thank you for reporting this.',
            'createdAt': Timestamp.fromDate(date),
            'authorName': null,
          },
        ];
      final repository = IncidentRepositoryImpl(
        remoteDataSource: source,
      );

      final comments = await repository.watchComments('report-1').first;
      expect(comments.single, isA<IncidentComment>());
      expect(comments.single.message, 'Thank you for reporting this.');
      expect(comments.single.authorName, isNull);
    });
  });

  group('incident validation', () {
    test('requires a known category and valid text fields', () {
      expect(IncidentValidation.validateCategory('Water Shortage'), isNull);
      expect(IncidentValidation.validateCategory('Made up category'), isNotNull);
      expect(IncidentValidation.validateLocation('  '), isNotNull);
      expect(IncidentValidation.validateLocation('Main Library'), isNull);
      expect(IncidentValidation.validateDescription('Too short'), isNotNull);
      expect(
        IncidentValidation.validateDescription(
          'A detailed account of the campus issue.',
        ),
        isNull,
      );
    });

    test('validates comments and allows only known status transitions', () {
      expect(IncidentValidation.validateComment('  '), isNotNull);
      expect(
        IncidentValidation.validateComment('A useful update'),
        isNull,
      );
      expect(
        IncidentValidation.validateStatus('unknown'),
        'Invalid incident status.',
      );
      expect(
        IncidentValidation.canTransitionStatus('pending', 'resolved'),
        isTrue,
      );
      expect(
        IncidentValidation.canTransitionStatus('pending', 'pending'),
        isFalse,
      );
      expect(
        IncidentValidation.canTransitionStatus('unrecognized', 'resolved'),
        isFalse,
      );
    });
  });

  group('image file validation', () {
    test('accepts supported image extensions within the two MB limit', () {
      expect(
        ImageFileValidation.validate(
          filePath: r'C:\temp\incident.JPEG',
          fileSize: 1024,
        ),
        isNull,
      );
      expect(
        ImageFileValidation.validate(
          filePath: '/tmp/photo.webp',
          fileSize: ImageFileValidation.maxFileSize,
        ),
        isNull,
      );
    });

    test('rejects unsupported, empty, and oversized files', () {
      expect(
        ImageFileValidation.validate(filePath: 'photo.gif', fileSize: 10),
        contains('JPG'),
      );
      expect(
        ImageFileValidation.validate(filePath: 'photo.jpg', fileSize: 0),
        contains('empty'),
      );
      expect(
        ImageFileValidation.validate(
          filePath: 'photo.png',
          fileSize: ImageFileValidation.maxFileSize + 1,
        ),
        contains('2 MB'),
      );
    });
  });
}