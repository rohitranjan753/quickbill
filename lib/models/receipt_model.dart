import 'package:equatable/equatable.dart';
import 'cart_item_model.dart';

class ReceiptModel extends Equatable {
  final String id;
  final String userId;
  final List<CartItemModel> items;
  final double totalAmount;
  final DateTime purchaseDate;
  final String paymentMethod;
  final bool verified;

  const ReceiptModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.purchaseDate,
    required this.paymentMethod,
    this.verified = false,
  });

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    return ReceiptModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      items: (json['items'] as List)
          .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      paymentMethod: json['paymentMethod'] as String,
      verified: json['verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'purchaseDate': purchaseDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      'verified': verified,
    };
  }

  @override
  List<Object?> get props => [id, userId, items, totalAmount, purchaseDate, paymentMethod, verified];
}
