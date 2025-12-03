import 'user_model.dart';

class Product {
  final String id;
  final String title;
  final double price;
  final List<String> images;
  final String category;
  final String location;
  final double rating;
  final int reviews;
  final String description;
  final String condition;
  final User owner;
  bool isFavorite;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.images,
    required this.category,
    required this.location,
    required this.rating,
    required this.reviews,
    required this.description,
    required this.condition,
    required this.owner,
    this.isFavorite = false,
  });
}
