import 'product.dart';
import 'user.dart';

class Purchase {
  final int id;
  final Product product;
  final User buyer;
  final String purchasePrice;
  final String status; // pending, completed, cancelled
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Purchase({
    required this.id,
    required this.product,
    required this.buyer,
    required this.purchasePrice,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'],
      product: Product.fromJson(json['product']),
      buyer: User.fromJson(json['buyer']),
      purchasePrice: json['purchase_price'].toString(),
      status: json['status'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'buyer': buyer.toJson(),
      'purchase_price': purchasePrice,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
}
