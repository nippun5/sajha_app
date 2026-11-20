/// SaJHa review domain types. All records in Step 6C are local debug previews.
/// Backend IDs, author identity, and moderation status must be server-owned.
class BusinessReview {
  const BusinessReview({
    required this.id,
    required this.businessId,
    required this.authorId,
    required this.authorName,
    required this.stars,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.sample = false,
  });

  final String id;
  final String businessId;
  final String authorId;
  final String authorName;
  final int stars;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool sample;

  BusinessReview edit(
      {required int stars, required String comment, required DateTime at}) {
    return BusinessReview(
      id: id,
      businessId: businessId,
      authorId: authorId,
      authorName: authorName,
      stars: stars,
      comment: comment,
      createdAt: createdAt,
      updatedAt: at,
      sample: sample,
    );
  }
}

class BusinessRatingSummary {
  const BusinessRatingSummary({required this.average, required this.count});
  final double average;
  final int count;
  bool get hasRatings => count > 0;
}

class BusinessReviewReport {
  const BusinessReviewReport({
    required this.id,
    required this.businessId,
    required this.reviewId,
    required this.reporterId,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String businessId;
  final String reviewId;
  final String reporterId;
  final String reason;
  final DateTime createdAt;
}
