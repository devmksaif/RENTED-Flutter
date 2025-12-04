import 'category.dart';
import 'user.dart';

class Product {
  final int id;
  final String title;
  final String description;
  final String pricePerDay;
  final bool isForSale;
  final String? salePrice;
  final bool isAvailable;
  final String thumbnail;
  final List<String> images;
  final Category category;
  final User? owner;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.pricePerDay,
    required this.isForSale,
    this.salePrice,
    required this.isAvailable,
    required this.thumbnail,
    required this.images,
    required this.category,
    this.owner,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      pricePerDay: json['price_per_day'].toString(),
      isForSale: json['is_for_sale'] ?? false,
      salePrice: json['sale_price']?.toString(),
      isAvailable: json['is_available'] ?? true,
      thumbnail: json['thumbnail'],
      images: List<String>.from(json['images'] ?? []),
      category: Category.fromJson(json['category']),
      owner: json['owner'] != null ? User.fromJson(json['owner']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price_per_day': pricePerDay,
      'is_for_sale': isForSale,
      'sale_price': salePrice,
      'is_available': isAvailable,
      'thumbnail': thumbnail,
      'images': images,
      'category': category.toJson(),
      'owner': owner?.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
