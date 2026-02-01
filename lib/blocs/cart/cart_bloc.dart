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
    final currentQuantity = existingIndex != -1
        ? items[existingIndex].quantity
        : 0;
    final availableStock = event.product.stockQuantity;

    if (double.parse(currentQuantity.toString()) + 1 > (availableStock ?? 0)) {
      emit(state.copyWith(items: null, totalAmount: null));
      emit(
        CartError(
          message:
              'Only $availableStock units available for ${event.product.name}',
          items: state.items,
          totalAmount: state.totalAmount,
        ),
      );
      // emit(CartInitial());
      return;
    }
    if (existingIndex != -1) {
      items[existingIndex] = items[existingIndex].copyWith(
        quantity: items[existingIndex].quantity + 1,
      );
    } else {
      items.add(CartItemModel(product: event.product, quantity: 1));
    }

    final total = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    emit(
      CartSuccess(
        message: "Item ${event.product.name} added",
        items: items,
        totalAmount: total,
      ),
    );
    // emit(CartInitial());
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
