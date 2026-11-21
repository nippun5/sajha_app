import 'package:flutter/foundation.dart';

import '../../../models/business_model.dart';
import '../../profile/data/profile_demo_store.dart';
import 'business_review.dart';

/// A local, debug-only review repository. No data is sent or retained after
/// restarting the application. Never expose write actions in release builds.
/// A trusted backend must enforce account identity, ownership, and moderation.
class BusinessReviewStore extends ChangeNotifier {
  BusinessReviewStore._() {
    ProfileDemoStore.instance.addListener(_onDemoStateChanged);
  }

  static final BusinessReviewStore instance = BusinessReviewStore._();

  static const String demoReviewerId = 'local-debug-reviewer';
  static const List<String> reportReasons = [
    'Spam or advertising',
    'Harassment or abusive language',
    'Fake or misleading review',
    'Conflict of interest',
    'Other',
  ];

  final Map<String, List<BusinessReview>> _reviewsByBusiness = {};
  final List<BusinessReviewReport> _reports = [];
  int _nextId = 1;

  bool get canWritePreview =>
      kDebugMode && ProfileDemoStore.instance.previewEnabled;

  void _onDemoStateChanged() {
    if (!canWritePreview) {
      _reviewsByBusiness.clear();
      _reports.clear();
      _nextId = 1;
    }
    notifyListeners();
  }

  /// Returns synthetic review examples in debug demo mode only.
  /// Outside demo mode, the previously supplied BusinessModel aggregate is
  /// display-only, and there is no local review text.
  void _ensureDemoSeed(BusinessModel business) {
    if (!canWritePreview || _reviewsByBusiness.containsKey(business.id)) return;
    final now = DateTime.now();
    _reviewsByBusiness[business.id] = [
      BusinessReview(
        id: 'sample-${business.id}-a',
        businessId: business.id,
        authorId: 'sample-reviewer-a',
        authorName: 'Sample reviewer A',
        stars: 5,
        comment: 'Demo review for testing the SaJHa business review layout.',
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 7)),
        sample: true,
      ),
      BusinessReview(
        id: 'sample-${business.id}-b',
        businessId: business.id,
        authorId: 'sample-reviewer-b',
        authorName: 'Sample reviewer B',
        stars: 4,
        comment:
            'Example feedback only. This is not a verified customer review.',
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
        sample: true,
      ),
    ];
  }

  List<BusinessReview> reviewsFor(BusinessModel business) {
    if (!canWritePreview) return const [];
    _ensureDemoSeed(business);
    final result = [..._reviewsByBusiness[business.id]!];
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(result);
  }

  BusinessRatingSummary summaryFor(BusinessModel business) {
    if (!canWritePreview) {
      return BusinessRatingSummary(
        average: business.rating,
        count: business.reviewCount,
      );
    }
    final reviews = reviewsFor(business);
    if (reviews.isEmpty) {
      return const BusinessRatingSummary(average: 0, count: 0);
    }
    final total = reviews.fold<int>(0, (sum, review) => sum + review.stars);
    return BusinessRatingSummary(
      average: total / reviews.length,
      count: reviews.length,
    );
  }

  BusinessReview? myReviewFor(BusinessModel business) {
    for (final review in reviewsFor(business)) {
      if (review.authorId == demoReviewerId) return review;
    }
    return null;
  }

  void _checkEditable(BusinessModel business) {
    if (!canWritePreview) {
      throw StateError('Reviews are not connected to a live backend.');
    }
    if (business.ownerId == demoReviewerId) {
      throw StateError('Business owners cannot review their own business.');
    }
  }

  BusinessReview savePreviewReview({
    required BusinessModel business,
    required int stars,
    required String comment,
  }) {
    _checkEditable(business);
    if (stars < 1 || stars > 5) {
      throw ArgumentError('Choose between 1 and 5 stars.');
    }
    final text = comment.trim();
    if (text.length < 10 || text.length > 600) {
      throw ArgumentError('Write a review between 10 and 600 characters.');
    }
    _ensureDemoSeed(business);
    final reviews = _reviewsByBusiness[business.id]!;
    final index = reviews.indexWhere((r) => r.authorId == demoReviewerId);
    final now = DateTime.now();
    late final BusinessReview result;
    if (index == -1) {
      result = BusinessReview(
        id: 'local-review-${_nextId++}',
        businessId: business.id,
        authorId: demoReviewerId,
        authorName: 'Demo Community Member',
        stars: stars,
        comment: text,
        createdAt: now,
        updatedAt: now,
      );
      reviews.add(result);
    } else {
      result = reviews[index].edit(stars: stars, comment: text, at: now);
      reviews[index] = result;
    }
    notifyListeners();
    return result;
  }

  void deleteMyPreviewReview(BusinessModel business) {
    _checkEditable(business);
    _ensureDemoSeed(business);
    _reviewsByBusiness[business.id]!.removeWhere(
      (review) => review.authorId == demoReviewerId,
    );
    notifyListeners();
  }

  /// Records a report for future moderation UI testing. Does not hide or
  /// remove the reported review, and does not alert an administrator.
  BusinessReviewReport reportPreviewReview({
    required BusinessModel business,
    required String reviewId,
    required String reason,
  }) {
    if (!canWritePreview) throw StateError('Reporting is not connected yet.');
    if (!reportReasons.contains(reason)) {
      throw ArgumentError('Choose a valid report reason.');
    }
    final matches =
        reviewsFor(business).where((review) => review.id == reviewId);
    if (matches.isEmpty) throw StateError('Review not found.');
    if (matches.single.authorId == demoReviewerId) {
      throw StateError('You cannot report your own review.');
    }
    if (_reports.any((report) =>
        report.reviewId == reviewId && report.reporterId == demoReviewerId)) {
      throw StateError('This review was already reported in the demo.');
    }
    final result = BusinessReviewReport(
      id: 'local-report-${_nextId++}',
      businessId: business.id,
      reviewId: reviewId,
      reporterId: demoReviewerId,
      reason: reason,
      createdAt: DateTime.now(),
    );
    _reports.add(result);
    notifyListeners();
    return result;
  }

  bool hasReported(String reviewId) => _reports.any((report) =>
      report.reviewId == reviewId && report.reporterId == demoReviewerId);

  List<BusinessReviewReport> get previewReports => List.unmodifiable(
      canWritePreview ? _reports : const <BusinessReviewReport>[]);
}
