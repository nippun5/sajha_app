import 'package:flutter_test/flutter_test.dart';
import 'package:sajha_app/models/business_model.dart';
import 'package:sajha_app/features/profile/data/profile_demo_store.dart';
import 'package:sajha_app/features/business_reviews/data/business_review_store.dart';

void main() {
  final profile = ProfileDemoStore.instance;
  final reviews = BusinessReviewStore.instance;

  BusinessModel business({String? ownerId}) => BusinessModel(
        id: 'test-cafe',
        name: 'Demo Cafe',
        imageUrl: '',
        description: 'For unit testing',
        address: 'Example address',
        phone: '',
        website: '',
        category: 'Cafe',
        rating: 4.2,
        reviewCount: 15,
        openingHours: const {},
        ownerId: ownerId,
      );

  setUp(() {
    profile.disablePreview();
    profile.enablePreview();
  });

  tearDown(() => profile.disablePreview());

  test(
      'sample preview reviews are explicitly local, while old model is preserved',
      () {
    final b = business();
    final summary = reviews.summaryFor(b);
    expect(summary.count, 2);
    expect(summary.average, 4.5);
    expect(reviews.reviewsFor(b).every((r) => r.sample), isTrue);
    profile.disablePreview();
    expect(reviews.reviewsFor(b), isEmpty);
    expect(reviews.summaryFor(b).count, 15);
    expect(reviews.summaryFor(b).average, 4.2);
  });

  test('one review per demo author, editing changes average but not count', () {
    final b = business();
    final first = reviews.savePreviewReview(
      business: b,
      stars: 3,
      comment: 'This is a valid demo review.',
    );
    expect(reviews.summaryFor(b).count, 3);
    expect(reviews.summaryFor(b).average, closeTo(4, 0.00001));
    final updated = reviews.savePreviewReview(
      business: b,
      stars: 5,
      comment: 'Updated review with enough characters.',
    );
    expect(updated.id, first.id);
    expect(reviews.summaryFor(b).count, 3);
    expect(reviews.summaryFor(b).average, closeTo(14 / 3, 0.00001));
    reviews.deleteMyPreviewReview(b);
    expect(reviews.summaryFor(b).count, 2);
  });

  test('invalid stars and short comments are rejected', () {
    final b = business();
    expect(
        () => reviews.savePreviewReview(
              business: b,
              stars: 0,
              comment: 'Long enough comment',
            ),
        throwsArgumentError);
    expect(
        () => reviews.savePreviewReview(
              business: b,
              stars: 5,
              comment: 'short',
            ),
        throwsArgumentError);
  });

  test('demo owner cannot review their own business', () {
    final own = business(ownerId: BusinessReviewStore.demoReviewerId);
    expect(
        () => reviews.savePreviewReview(
              business: own,
              stars: 5,
              comment: 'A self-review should be rejected.',
            ),
        throwsStateError);
  });

  test('reports are single-entry, locally stored and do not erase reviews', () {
    final b = business();
    final sample = reviews.reviewsFor(b).first;
    reviews.reportPreviewReview(
      business: b,
      reviewId: sample.id,
      reason: 'Fake or misleading review',
    );
    expect(reviews.hasReported(sample.id), isTrue);
    expect(reviews.previewReports.length, 1);
    expect(reviews.summaryFor(b).count, 2);
    expect(
        () => reviews.reportPreviewReview(
              business: b,
              reviewId: sample.id,
              reason: 'Spam or advertising',
            ),
        throwsStateError);
    profile.disablePreview();
    expect(reviews.previewReports, isEmpty);
  });
}
