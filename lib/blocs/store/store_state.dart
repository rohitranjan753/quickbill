import 'package:equatable/equatable.dart';
import '../../models/nearby_store_model.dart';

abstract class StoreState extends Equatable {
  const StoreState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class StoreInitial extends StoreState {
  const StoreInitial();
}

/// Loading nearby stores
class StoreLoading extends StoreState {
  const StoreLoading();
}

/// Nearby stores loaded successfully
class StoreLoaded extends StoreState {
  final List<NearbyStoreModel> stores;
  final List<NearbyStoreModel> filteredStores;
  final NearbyStoreModel? selectedStore;
  final String searchQuery;
  final double? userLatitude;
  final double? userLongitude;

  const StoreLoaded({
    required this.stores,
    this.filteredStores = const [],
    this.selectedStore,
    this.searchQuery = '',
    this.userLatitude,
    this.userLongitude,
  });

  /// Get filtered stores based on search query
  List<NearbyStoreModel> get displayStores {
    if (searchQuery.isEmpty) return stores;
    return filteredStores;
  }

  /// Get featured store (closest or highest rated)
  NearbyStoreModel? get featuredStore {
    if (stores.isEmpty) return null;
    return stores.first; // Already sorted by distance from backend
  }

  /// Get remaining stores (excluding featured)
  List<NearbyStoreModel> get otherStores {
    if (stores.isEmpty) return [];
    return stores.skip(1).toList();
  }

  StoreLoaded copyWith({
    List<NearbyStoreModel>? stores,
    List<NearbyStoreModel>? filteredStores,
    NearbyStoreModel? selectedStore,
    String? searchQuery,
    double? userLatitude,
    double? userLongitude,
    bool clearSelected = false,
  }) {
    return StoreLoaded(
      stores: stores ?? this.stores,
      filteredStores: filteredStores ?? this.filteredStores,
      selectedStore: clearSelected ? null : (selectedStore ?? this.selectedStore),
      searchQuery: searchQuery ?? this.searchQuery,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
    );
  }

  @override
  List<Object?> get props => [
        stores,
        filteredStores,
        selectedStore,
        searchQuery,
        userLatitude,
        userLongitude,
      ];
}

/// Error loading stores
class StoreError extends StoreState {
  final String message;

  const StoreError(this.message);

  @override
  List<Object?> get props => [message];
}

/// No stores found in the area
class StoreEmpty extends StoreState {
  final double latitude;
  final double longitude;
  final double radiusKm;

  const StoreEmpty({
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
  });

  @override
  List<Object?> get props => [latitude, longitude, radiusKm];
}
