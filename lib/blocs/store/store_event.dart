import 'package:equatable/equatable.dart';

abstract class StoreEvent extends Equatable {
  const StoreEvent();

  @override
  List<Object?> get props => [];
}

/// Event to fetch nearby stores based on user location
class FetchNearbyStores extends StoreEvent {
  final double latitude;
  final double longitude;
  final double radiusKm;

  const FetchNearbyStores({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 10.0,
  });

  @override
  List<Object?> get props => [latitude, longitude, radiusKm];
}

/// Event to select a store
class SelectStore extends StoreEvent {
  final String storeId;

  const SelectStore(this.storeId);

  @override
  List<Object?> get props => [storeId];
}

/// Event to clear selected store
class ClearSelectedStore extends StoreEvent {
  const ClearSelectedStore();
}

/// Event to search stores by name
class SearchStores extends StoreEvent {
  final String query;

  const SearchStores(this.query);

  @override
  List<Object?> get props => [query];
}

/// Event to refresh nearby stores
class RefreshNearbyStores extends StoreEvent {
  const RefreshNearbyStores();
}
