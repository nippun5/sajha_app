/// Public display model for a business in the SaJHa directory.
/// Existing required constructor arguments are intentionally unchanged.
class BusinessModel {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final String address;
  final String phone;
  final String website;
  final String category;
  final double rating;
  final int reviewCount;
  final Map<String, String> openingHours;

  /// Optional fields for location-aware discovery (safe for old mock data).
  final double? latitude;
  final double? longitude;
  final String? geoapifyPlaceId;
  final String? city;
  final String? state;
  final String? countryCode;
  final bool onlineOnly;
  final String? locationNote;

  /// Optional verified owner ID, to be set by the backend later.
  final String? ownerId;

  BusinessModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.address,
    required this.phone,
    required this.website,
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.openingHours,
    this.latitude,
    this.longitude,
    this.geoapifyPlaceId,
    this.city,
    this.state,
    this.countryCode,
    this.onlineOnly = false,
    this.locationNote,
    this.ownerId,
  });

  bool get hasCoordinates =>
      latitude != null &&
      longitude != null &&
      latitude! >= -90 &&
      latitude! <= 90 &&
      longitude! >= -180 &&
      longitude! <= 180;
}
