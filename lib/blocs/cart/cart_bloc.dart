import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/cart_item_model.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<CartItemAdded>(_onCartItemAdded);
    on<CartItemRemoved>(_onCartItemRemoved);
    on<CartItemQuantityUpdated>(_onCartItemQuantityUpdated);
    on<CartCleared>(_onCartCleared);
  }

  void _onCartItemAdded(CartItemAdded event, Emitter<CartState> emit) {
    final items = List<CartItemModel>.from(state.items);
    final existingIndex = items.indexWhere(
      (item) => item.product.barcode == event.product.barcode,
    );

    if (existingIndex != -1) {
      items[existingIndex] = items[existingIndex].copyWith(
        quantity: items[existingIndex].quantity + 1,
      );
    } else {
      items.add(CartItemModel(product: event.product, quantity: 1));
    }

    final total = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    emit(state.copyWith(items: items, totalAmount: total));
  }

  void _onCartItemRemoved(CartItemRemoved event, Emitter<CartState> emit) {
    final items = state.items
        .where((item) => item.product.barcode != event.barcode)
        .toList();
    final total = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    emit(state.copyWith(items: items, totalAmount: total));
  }

  void _onCartItemQuantityUpdated(
    CartItemQuantityUpdated event,
    Emitter<CartState> emit,
  ) {
    final items = List<CartItemModel>.from(state.items);
    final index = items.indexWhere(
      (item) => item.product.barcode == event.barcode,
    );

    if (index != -1) {
      if (event.quantity > 0) {
        items[index] = items[index].copyWith(quantity: event.quantity);
      } else {
        items.removeAt(index);
      }
    }

    final total = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    emit(state.copyWith(items: items, totalAmount: total));
  }

  void _onCartCleared(CartCleared event, Emitter<CartState> emit) {
    emit(const CartState());
  }
}
