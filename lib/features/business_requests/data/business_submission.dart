import 'dart:typed_data';

/// An API-ready snapshot of the business owner's submission.
/// This is NOT a published BusinessModel; approval belongs to the server/admin.
/// Banner bytes are preview-only. In production upload them as multipart media
/// and store a secure object reference rather than embedding bytes in JSON.
class BusinessSubmission {
  BusinessSubmission({
    required this.name,
    required this.category,
    required this.phone,
    required this.description,
    required this.onlineOnly,
    required this.address,
    required Uint8List bannerBytes,
    required Map<String, String> openingHours,
    required Map<String, Map<String, dynamic>> openingHoursStructured,
    this.website = '',
    this.latitude,
    this.longitude,
    this.placeId,
    this.city,
    this.state,
    this.countryCode,
  })  : openingHours = Map<String, String>.unmodifiable(openingHours),
        openingHoursStructured = Map<String, Map<String, dynamic>>.unmodifiable(
          openingHoursStructured.map((key, value) =>
              MapEntry(key, Map<String, dynamic>.unmodifiable(value))),
        ),
        // Prevent the picker/form from mutating a saved preview image.
        bannerBytes = Uint8List.fromList(bannerBytes);

  final String name;
  final String category;
  final String phone;
  final String website;
  final String description;
  final bool onlineOnly;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? placeId;
  final String? city;
  final String? state;
  final String? countryCode;
  final Uint8List bannerBytes;
  final Map<String, String> openingHours;
  final Map<String, Map<String, dynamic>> openingHoursStructured;

  String get locationLabel => onlineOnly ? 'Online only' : address;

  /// Intended structure for future POST /api/business-requests.
  /// The image is intentionally omitted; upload as a separate media part.
  Map<String, dynamic> toApiPayload() => {
        'name': name,
        'category': category,
        'phone': phone,
        'website': website,
        'description': description,
        'onlineOnly': onlineOnly,
        'address': onlineOnly ? '' : address,
        'latitude': onlineOnly ? null : latitude,
        'longitude': onlineOnly ? null : longitude,
        'placeId': onlineOnly ? null : placeId,
        'city': onlineOnly ? null : city,
        'state': onlineOnly ? null : state,
        'countryCode': onlineOnly ? null : countryCode,
        'openingHours': Map<String, String>.from(openingHours),
        'openingHoursStructured': openingHoursStructured.map(
            (key, value) => MapEntry(key, Map<String, dynamic>.from(value))),
      };

  String? validate() {
    if (name.trim().isEmpty || name.trim().length > 100) {
      return 'Enter a business name (up to 100 characters).';
    }
    if (category.trim().isEmpty || category.trim().length > 60) {
      return 'Choose a business category.';
    }
    final normalized = phone.replaceAll(RegExp(r'[\s().-]'), '');
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(normalized)) {
      return 'Enter a valid contact phone number.';
    }
    if (description.trim().isEmpty || description.length > 3000) {
      return 'Enter a business description (up to 3000 characters).';
    }
    if (bannerBytes.isEmpty || bannerBytes.lengthInBytes > 10 * 1024 * 1024) {
      return 'Select a business banner under 10 MB.';
    }
    if (!onlineOnly) {
      if (address.trim().isEmpty || address.length > 250) {
        return 'Confirm a physical business address.';
      }
      if (latitude == null ||
          longitude == null ||
          latitude! < -90 ||
          latitude! > 90 ||
          longitude! < -180 ||
          longitude! > 180) {
        return 'Confirm the business location on the map.';
      }
    }
    if (openingHours.length != 7 || openingHoursStructured.length != 7) {
      return 'Set opening hours for every day.';
    }
    return null;
  }
}
