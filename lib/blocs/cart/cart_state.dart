import 'package:equatable/equatable.dart';
import '../../models/cart_item_model.dart';

class CartState extends Equatable {
  final List<CartItemModel> items;
  final double totalAmount;

  const CartState({
    this.items = const [],
    this.totalAmount = 0.0,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({
    List<CartItemModel>? items,
    double? totalAmount,
  }) {
    return CartState(
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

  @override
  List<Object?> get props => [items, totalAmount];
}
