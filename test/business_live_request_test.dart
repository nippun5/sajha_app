import 'package:flutter_test/flutter_test.dart';
import 'package:sajha_app/features/business_requests/live/live_business_api.dart';

void main() {
  test('live business request maps owner status and revision', () {
    final request = LiveBusinessRequest.fromJson({
      'id': 'test-business-1',
      'businessName': 'Community Cafe',
      'category': 'Restaurant & cafe',
      'status': 'declined',
      'visibility': 'active',
      'revision': 2,
      'submittedAt': '2026-11-21T16:30:00Z',
      'onlineOnly': true,
      'declineReason': 'Please provide a complete description.',
    });
    expect(request.status, 'declined');
    expect(request.revision, 2);
    expect(request.location, 'Online only');
    expect(request.declineReason, contains('description'));
  });
}
