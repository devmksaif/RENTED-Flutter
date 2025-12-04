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
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Rental.fromJson(Map<String, dynamic> json) {
    return Rental(
      id: json['id'],
      product: Product.fromJson(json['product']),
      renter: User.fromJson(json['renter']),
      startDate: json['start_date'],
      endDate: json['end_date'],
      totalPrice: json['total_price'].toString(),
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
      'renter': renter.toJson(),
      'start_date': startDate,
      'end_date': endDate,
      'total_price': totalPrice,
      'status': status,
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
