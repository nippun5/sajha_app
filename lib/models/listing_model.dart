class ListingModel {
  final String id;
  final String title;
  final String price;
  final String imageUrl;
  final String description;
  final String location;
  final String category;
  final String condition;
  final List<String> images;

  ListingModel({
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.location,
    required this.category,
    required this.condition,
    required this.images,
  });
}