import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sajha_app/features/business_requests/data/business_submission.dart';
import 'package:sajha_app/features/profile/data/profile_demo_store.dart';

const _days = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday',
  'Friday', 'Saturday', 'Sunday',
];

BusinessSubmission sample({bool onlineOnly = true}) => BusinessSubmission(
  name: 'Test Community Business',
  category: 'Home services',
  phone: '+15551234567',
  website: 'https://example.com',
  description: 'A sample business submission for automated testing.',
  onlineOnly: onlineOnly,
  address: onlineOnly ? '' : 'Test address, Test City',
  latitude: onlineOnly ? null : 40.0,
  longitude: onlineOnly ? null : -75.0,
  bannerBytes: Uint8List.fromList([1, 2, 3]),
  openingHours: {for (final day in _days) day: '09:00 – 17:00'},
  openingHoursStructured: {
    for (final day in _days) day: {
      'mode': 'open', 'opens': '09:00', 'closes': '17:00',
    }
  },
);

void main() {
  final store = ProfileDemoStore.instance;

  setUp(() {
    store.disablePreview();
    store.enablePreview();
  });
  tearDown(store.disablePreview);

  test('full submission creates Pending owner request with unchanged details', () {
    final startingCount = store.businessRequests.length;
    final request = store.submitBusinessRequest(sample());
    expect(store.businessRequests.length, startingCount + 1);
    expect(request.status, BusinessRequestStatus.pending);
    expect(request.submission, isNotNull);
    expect(request.submission!.phone, '+15551234567');
    expect(request.submission!.openingHours.length, 7);
    expect(request.submission!.bannerBytes.length, 3);
    expect(request.revision, 1);
  });

  test('address and coordinates travel together in an API payload', () {
    final form = sample(onlineOnly: false);
    expect(form.validate(), isNull);
    final payload = form.toApiPayload();
    expect(payload['latitude'], 40.0);
    expect(payload['longitude'], -75.0);
    expect(payload['address'], contains('Test City'));
    expect(payload.containsKey('bannerBytes'), false);
  });

  test('physical business without coordinates is rejected', () {
    final invalid = BusinessSubmission(
      name: 'Business', category: 'Home services', phone: '+15551234567',
      description: 'Description', onlineOnly: false,
      address: '123 Test', bannerBytes: Uint8List.fromList([1]),
      openingHours: {for (final d in _days) d: 'Closed'},
      openingHoursStructured: {
        for (final d in _days) d: {'mode': 'closed'}
      },
    );
    expect(invalid.validate(), contains('location'));
  });

  test('declined sample is editable and resubmission returns to Pending', () {
    final declined = store.businessRequests.firstWhere(
        (entry) => entry.status == BusinessRequestStatus.declined);
    final result = store.resubmitDeclinedBusinessRequest(declined.id, sample());
    expect(result.id, declined.id);
    expect(result.status, BusinessRequestStatus.pending);
    expect(result.declineReason, isNull);
    expect(result.revision, 2);
    expect(result.createdAt, declined.createdAt);
    expect(store.businessRequests.first.id, declined.id);
  });

  test('pending and approved requests cannot be resubmitted by the owner', () {
    final pending = store.submitBusinessRequest(sample());
    expect(
      () => store.resubmitDeclinedBusinessRequest(pending.id, sample()),
      throwsStateError,
    );
    final approved = store.businessRequests.firstWhere(
        (entry) => entry.status == BusinessRequestStatus.approved);
    expect(
      () => store.resubmitDeclinedBusinessRequest(approved.id, sample()),
      throwsStateError,
    );
  });

  test('no submission can be saved when demo preview is disabled', () {
    store.disablePreview();
    expect(() => store.submitBusinessRequest(sample()), throwsStateError);
    expect(store.businessRequests, isEmpty);
  });
}
