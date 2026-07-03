import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/store_api_service.dart';
import '../../models/nearby_store_model.dart';
import 'store_event.dart';
import 'store_state.dart';

class StoreBloc extends Bloc<StoreEvent, StoreState> {
  final StoreApiService _storeApiService;

  StoreBloc({StoreApiService? storeApiService})
      : _storeApiService = storeApiService ?? StoreApiService(),
        super(const StoreInitial()) {
    on<FetchNearbyStores>(_onFetchNearbyStores);
    on<RefreshNearbyStores>(_onRefreshNearbyStores);
    on<SelectStore>(_onSelectStore);
    on<ClearSelectedStore>(_onClearSelectedStore);
    on<SearchStores>(_onSearchStores);
  }

  Future<void> _onFetchNearbyStores(
    FetchNearbyStores event,
    Emitter<StoreState> emit,
  ) async {
    emit(const StoreLoading());

    try {
      final stores = await _storeApiService.getNearbyStores(
        latitude: event.latitude,
        longitude: event.longitude,
        radiusKm: event.radiusKm,
      );

      if (stores.isEmpty) {
        emit(StoreEmpty(
          latitude: event.latitude,
          longitude: event.longitude,
          radiusKm: event.radiusKm,
        ));
      } else {
        emit(StoreLoaded(
          stores: stores,
          userLatitude: event.latitude,
          userLongitude: event.longitude,
        ));
      }
    } catch (e) {
      emit(StoreError(e.toString()));
    }
  }

  Future<void> _onRefreshNearbyStores(
    RefreshNearbyStores event,
    Emitter<StoreState> emit,
  ) async {
    if (state is StoreLoaded) {
      final currentState = state as StoreLoaded;
      if (currentState.userLatitude != null && currentState.userLongitude != null) {
        add(FetchNearbyStores(
          latitude: currentState.userLatitude!,
          longitude: currentState.userLongitude!,
        ));
      }
    }
  }

  Future<void> _onSelectStore(
    SelectStore event,
    Emitter<StoreState> emit,
  ) async {
    if (state is StoreLoaded) {
      final currentState = state as StoreLoaded;

      try {
        // Find store in current list or fetch from API
        NearbyStoreModel? selectedStore = currentState.stores.firstWhere(
          (store) => store.id == event.storeId,
          orElse: () => throw Exception('Store not found'),
        );

        emit(currentState.copyWith(selectedStore: selectedStore));
      } catch (e) {
        // If not in list, try fetching from API
        try {
          final store = await _storeApiService.getStoreById(event.storeId);
          if (store != null) {
            emit(currentState.copyWith(selectedStore: store));
          } else {
            emit(StoreError('Store not found'));
            emit(currentState); // Restore previous state
          }
        } catch (apiError) {
          emit(StoreError('Failed to fetch store: $apiError'));
          emit(currentState); // Restore previous state
        }
      }
    }
  }

  void _onClearSelectedStore(
    ClearSelectedStore event,
    Emitter<StoreState> emit,
  ) {
    if (state is StoreLoaded) {
      final currentState = state as StoreLoaded;
      emit(currentState.copyWith(clearSelected: true));
    }
  }

  void _onSearchStores(
    SearchStores event,
    Emitter<StoreState> emit,
  ) {
    if (state is StoreLoaded) {
      final currentState = state as StoreLoaded;
      final query = event.query.toLowerCase();

      if (query.isEmpty) {
        emit(currentState.copyWith(
          searchQuery: '',
          filteredStores: [],
        ));
      } else {
        final filtered = currentState.stores.where((store) {
          return store.name.toLowerCase().contains(query) ||
              store.address.toLowerCase().contains(query) ||
              store.city.toLowerCase().contains(query);
        }).toList();

        emit(currentState.copyWith(
          searchQuery: query,
          filteredStores: filtered,
        ));
      }
    }
  }
}
