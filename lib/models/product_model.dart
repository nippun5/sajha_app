enum ProductCondition {
  newItem,
  likeNew,
  good,
  fair,
  used,
}

extension ProductConditionLabel on ProductCondition {
  String get label {
    switch (this) {
      case ProductCondition.newItem:
        return 'New';

      case ProductCondition.likeNew:
        return 'Like New';

      case ProductCondition.good:
        return 'Good';

      case ProductCondition.fair:
        return 'Fair';

      case ProductCondition.used:
        return 'Used';
    }
  }
}

class ProductModel {
  final String id;
  final String title;
  final String description;

  final double price;

  final String category;

  final ProductCondition condition;

  final List<String> imageUrls;

  final String sellerName;
  final String sellerId;

  final String location;

  final bool isNegotiable;
  final bool isAvailable;

  final DateTime postedAt;

  final String sellerPhone;

  const ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    this.imageUrls = const [],
    required this.sellerName,
    required this.sellerId,
    required this.location,
    this.isNegotiable = false,
    this.isAvailable = true,
    required this.postedAt,
    required this.sellerPhone,
  });

  String get formattedPrice {
    return '\$${price.toStringAsFixed(0)}';
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,

      title: json['title'] as String,

      description: json['description'] as String,

      price: (json['price'] as num).toDouble(),

      category: json['category'] as String,

      condition: ProductCondition.values.firstWhere(
        (e) => e.name == json['condition'],
        orElse: () => ProductCondition.used,
      ),

      imageUrls: List<String>.from(json['image_urls'] ?? []),

      sellerName: json['seller_name'] as String,

      sellerId: json['seller_id'] as String,

      location: json['location'] as String,

      isNegotiable: json['is_negotiable'] as bool? ?? false,

      isAvailable: json['is_available'] as bool? ?? true,

      postedAt: DateTime.parse(json['posted_at'] as String),

      sellerPhone: json['seller_phone'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,

      'title': title,

      'description': description,

      'price': price,

      'category': category,

      'condition': condition.name,

      'image_urls': imageUrls,

      'seller_name': sellerName,

      'seller_id': sellerId,

      'location': location,

      'is_negotiable': isNegotiable,

      'is_available': isAvailable,

      'posted_at': postedAt.toIso8601String(),

      'seller_phone': sellerPhone,
    };
  }

  ProductModel copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? category,
    ProductCondition? condition,
    List<String>? imageUrls,
    String? sellerName,
    String? sellerId,
    String? location,
    bool? isNegotiable,
    bool? isAvailable,
    DateTime? postedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,

      title: title ?? this.title,

      description: description ?? this.description,

      price: price ?? this.price,

      category: category ?? this.category,

      condition: condition ?? this.condition,

      imageUrls: imageUrls ?? this.imageUrls,

      sellerName: sellerName ?? this.sellerName,

      sellerId: sellerId ?? this.sellerId,

      location: location ?? this.location,

      isNegotiable: isNegotiable ?? this.isNegotiable,

      isAvailable: isAvailable ?? this.isAvailable,

      postedAt: postedAt ?? this.postedAt,

     sellerPhone: sellerPhone ?? this.sellerPhone,
    );
  }
}