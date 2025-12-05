import 'category.dart';
import 'user.dart';

class Product {
  final int id;
  final String title;
  final String description;
  final String pricePerDay;
  final String? pricePerWeek; // price_per_week (nullable)
  final String? pricePerMonth; // price_per_month (nullable)
  final bool isForSale;
  final String? salePrice;
  final bool isAvailable;
  final String? verificationStatus; // pending, approved, rejected
  final String? rejectionReason; // Admin rejection reason (nullable)
  final DateTime? verifiedAt; // Verification timestamp (nullable)
  final String thumbnail;
  final List<String> images;
  final Category category;
  final User? owner;
  // Location fields
  final String? locationAddress;
  final String? locationCity;
  final String? locationState;
  final String? locationCountry;
  final String? locationZip;
  final double? locationLatitude;
  final double? locationLongitude;
  // Delivery fields
  final bool? deliveryAvailable;
  final String? deliveryFee;
  final double? deliveryRadiusKm;
  final bool? pickupAvailable;
  // Product condition
  final String? productCondition; // new, like_new, good, fair, worn
  // Rental constraints
  final String? securityDeposit;
  final int? minRentalDays;
  final int? maxRentalDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.pricePerDay,
    this.pricePerWeek,
    this.pricePerMonth,
    required this.isForSale,
    this.salePrice,
    required this.isAvailable,
    this.verificationStatus,
    this.rejectionReason,
    this.verifiedAt,
    required this.thumbnail,
    required this.images,
    required this.category,
    this.owner,
    this.locationAddress,
    this.locationCity,
    this.locationState,
    this.locationCountry,
    this.locationZip,
    this.locationLatitude,
    this.locationLongitude,
    this.deliveryAvailable,
    this.deliveryFee,
    this.deliveryRadiusKm,
    this.pickupAvailable,
    this.productCondition,
    this.securityDeposit,
    this.minRentalDays,
    this.maxRentalDays,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle missing category (use default for product creation response)
    final categoryJson =
        json['category'] ??
        {
          'id': 0,
          'name': 'Unknown',
          'slug': 'unknown',
          'description': null,
          'is_active': true,
        };

    return Product(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      pricePerDay: json['price_per_day'].toString(),
      pricePerWeek: json['price_per_week']?.toString(),
      pricePerMonth: json['price_per_month']?.toString(),
      isForSale: json['is_for_sale'] ?? false,
      salePrice: json['sale_price']?.toString(),
      isAvailable: json['is_available'] ?? true,
      verificationStatus: json['verification_status'],
      rejectionReason: json['rejection_reason'],
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'])
          : null,
      thumbnail: json['thumbnail_url'] ?? json['thumbnail'] ?? '',
      images: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : (json['images'] != null ? List<String>.from(json['images']) : []),
      category: Category.fromJson(categoryJson),
      owner: json['owner'] != null ? User.fromJson(json['owner']) : null,
      locationAddress: json['location_address'],
      locationCity: json['location_city'],
      locationState: json['location_state'],
      locationCountry: json['location_country'],
      locationZip: json['location_zip'],
      locationLatitude: json['location_latitude'] != null
          ? double.tryParse(json['location_latitude'].toString())
          : null,
      locationLongitude: json['location_longitude'] != null
          ? double.tryParse(json['location_longitude'].toString())
          : null,
      deliveryAvailable: json['delivery_available'],
      deliveryFee: json['delivery_fee']?.toString(),
      deliveryRadiusKm: json['delivery_radius_km'] != null
          ? double.tryParse(json['delivery_radius_km'].toString())
          : null,
      pickupAvailable: json['pickup_available'],
      productCondition: json['product_condition'],
      securityDeposit: json['security_deposit']?.toString(),
      minRentalDays: json['min_rental_days'],
      maxRentalDays: json['max_rental_days'],
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
      'price_per_week': pricePerWeek,
      'price_per_month': pricePerMonth,
      'is_for_sale': isForSale,
      'sale_price': salePrice,
      'is_available': isAvailable,
      'verification_status': verificationStatus,
      'rejection_reason': rejectionReason,
      'verified_at': verifiedAt?.toIso8601String(),
      'thumbnail': thumbnail,
      'images': images,
      'category': category.toJson(),
      'owner': owner?.toJson(),
      'location_address': locationAddress,
      'location_city': locationCity,
      'location_state': locationState,
      'location_country': locationCountry,
      'location_zip': locationZip,
      'location_latitude': locationLatitude,
      'location_longitude': locationLongitude,
      'delivery_available': deliveryAvailable,
      'delivery_fee': deliveryFee,
      'delivery_radius_km': deliveryRadiusKm,
      'pickup_available': pickupAvailable,
      'product_condition': productCondition,
      'security_deposit': securityDeposit,
      'min_rental_days': minRentalDays,
      'max_rental_days': maxRentalDays,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isVerified => verificationStatus == 'approved';
  bool get isPendingVerification => verificationStatus == 'pending';
  bool get isRejected => verificationStatus == 'rejected';
}
