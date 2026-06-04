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
  });
}