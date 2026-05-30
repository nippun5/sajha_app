class RoomModel {
  final String id;
  final String title;
  final double weeklyRent;
  final String? imageUrl;
  final String suburb;
  final String state;
  final String postcode;
  final int bedrooms;
  final int bathrooms;
  final bool furnished;
  final String description;
  final DateTime availableFrom;
  final DateTime postedAt;
  final String landlordName;
  final List<String> amenities;
  final bool billsIncluded;
  final String ownerName;
  final String ownerPhone;
  final String preferredGender;



  const RoomModel({
    required this.id,
    required this.title,
    required this.weeklyRent,
    this.imageUrl,
    required this.suburb,
    required this.state,
    required this.postcode,
    required this.bedrooms,
    required this.bathrooms,
    required this.furnished,
    required this.description,
    required this.availableFrom,
    required this.postedAt,
    required this.landlordName,
    this.amenities = const [],
    this.billsIncluded = false,
    required this.ownerName,
    required this.ownerPhone,
    required this.preferredGender,

  });

  String get locationDisplay => '$suburb, $state $postcode';

  factory RoomModel.fromJson(Map<String, dynamic> json) => RoomModel(
        id: json['id'] as String,
        title: json['title'] as String,
        weeklyRent: (json['weekly_rent'] as num).toDouble(),
        imageUrl: json['image_url'] as String?,
        suburb: json['suburb'] as String,
        state: json['state'] as String,
        postcode: json['postcode'] as String,
        bedrooms: json['bedrooms'] as int,
        bathrooms: json['bathrooms'] as int,
        furnished: json['furnished'] as bool,
        description: json['description'] as String,
        availableFrom: DateTime.parse(json['available_from'] as String),
        postedAt: DateTime.parse(json['posted_at'] as String),
        landlordName: json['landlord_name'] as String,
        amenities: List<String>.from(json['amenities'] ?? []),
        billsIncluded: json['bills_included'] as bool? ?? false, 
        ownerName: 'owner_name', 
        ownerPhone: 'owner_phone', 
        preferredGender: 'preferred_gender',
      );
}