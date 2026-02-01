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

class CartInitial extends CartState {
  const CartInitial({
    super.items = const [],
    super.totalAmount = 0.0,
  });
}
class CartError extends CartState {
  final String message;

  const CartError({
    required this.message,
    required super.items,
    required super.totalAmount,
  });
}

class CartSuccess extends CartState {
  final String message;

  const CartSuccess({
    required this.message,
    required super.items,
    required super.totalAmount,
  });
}
