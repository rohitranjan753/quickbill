import 'package:equatable/equatable.dart';
import '../../models/product_model.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class CartItemAdded extends CartEvent {
  final ProductModel product;

  const CartItemAdded(this.product);

  @override
  List<Object?> get props => [product];
}

class CartItemRemoved extends CartEvent {
  final String barcode;

  const CartItemRemoved(this.barcode);

  @override
  List<Object?> get props => [barcode];
}

class CartItemQuantityUpdated extends CartEvent {
  final String barcode;
  final int quantity;

  const CartItemQuantityUpdated(this.barcode, this.quantity);

  @override
  List<Object?> get props => [barcode, quantity];
}

class CartCleared extends CartEvent {}
