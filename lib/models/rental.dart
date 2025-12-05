import 'product.dart';
import 'user.dart';

class Rental {
  final int id;
  final Product product;
  final User renter;
  final String startDate;
  final String endDate;
  final String totalPrice;
  final String status; // pending, approved, active, completed, cancelled
  final bool? deliveryRequired; // delivery_required from database
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Rental({
    required this.id,
    required this.product,
    required this.renter,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
    this.deliveryRequired,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Rental.fromJson(Map<String, dynamic> json) {
    // Handle simplified product object from rental endpoint
    final productJson = Map<String, dynamic>.from(json['product']);

    // Add required fields if missing (use defaults for simplified product)
    if (!productJson.containsKey('description')) {
      productJson['description'] = '';
    }
    if (!productJson.containsKey('is_for_sale')) {
      productJson['is_for_sale'] = false;
    }
    if (!productJson.containsKey('is_available')) {
      productJson['is_available'] = true;
    }
    if (!productJson.containsKey('images')) {
      productJson['images'] = [];
    }
    if (!productJson.containsKey('category')) {
      productJson['category'] = {
        'id': 0,
        'name': 'Unknown',
        'slug': 'unknown',
        'description': null,
        'is_active': true,
      };
    }
    if (!productJson.containsKey('created_at')) {
      productJson['created_at'] = DateTime.now().toIso8601String();
    }
    if (!productJson.containsKey('updated_at')) {
      productJson['updated_at'] = DateTime.now().toIso8601String();
    }
    // Handle owner object if present
    if (productJson.containsKey('owner') && productJson['owner'] != null) {
      final ownerJson = Map<String, dynamic>.from(productJson['owner']);
      if (!ownerJson.containsKey('verification_status')) {
        ownerJson['verification_status'] = 'pending';
      }
      if (!ownerJson.containsKey('created_at')) {
        ownerJson['created_at'] = DateTime.now().toIso8601String();
      }
      if (!ownerJson.containsKey('updated_at')) {
        ownerJson['updated_at'] = DateTime.now().toIso8601String();
      }
      productJson['owner'] = ownerJson;
    }

    // Handle simplified renter object from rental endpoint
    final renterJson = Map<String, dynamic>.from(json['renter']);

    // Add required fields if missing
    if (!renterJson.containsKey('verification_status')) {
      renterJson['verification_status'] = 'pending';
    }
    if (!renterJson.containsKey('created_at')) {
      renterJson['created_at'] = DateTime.now().toIso8601String();
    }
    if (!renterJson.containsKey('updated_at')) {
      renterJson['updated_at'] = DateTime.now().toIso8601String();
    }

    return Rental(
      id: json['id'],
      product: Product.fromJson(productJson),
      renter: User.fromJson(renterJson),
      startDate: json['start_date'],
      endDate: json['end_date'],
      totalPrice: json['total_price'].toString(),
      status: json['status'],
      deliveryRequired: json['delivery_required'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'renter': renter.toJson(),
      'start_date': startDate,
      'end_date': endDate,
      'total_price': totalPrice,
      'status': status,
      'delivery_required': deliveryRequired,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
}
