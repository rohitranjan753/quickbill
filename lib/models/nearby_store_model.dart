import 'package:equatable/equatable.dart';

/// Model for nearby store from backend API
class NearbyStoreModel extends Equatable {
  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final double? gpsLat;
  final double? gpsLng;
  final String? phone;
  final String? logoUrl;
  final Map<String, dynamic>? operatingHours;
  final bool isActive;
  final double averageRating;
  final int totalRatings;
  final double distanceKm;

  const NearbyStoreModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    this.gpsLat,
    this.gpsLng,
    this.phone,
    this.logoUrl,
    this.operatingHours,
    this.isActive = true,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    required this.distanceKm,
  });

  factory NearbyStoreModel.fromJson(Map<String, dynamic> json) {
    return NearbyStoreModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      pincode: json['pincode'] as String,
      gpsLat: json['gps_lat'] != null
          ? double.tryParse(json['gps_lat'].toString())
          : null,
      gpsLng: json['gps_lng'] != null
          ? double.tryParse(json['gps_lng'].toString())
          : null,
      phone: json['phone'] as String?,
      logoUrl: json['logo_url'] as String?,
      operatingHours: json['operating_hours'] as Map<String, dynamic>?,
      isActive: json['is_active'] as bool? ?? true,
      averageRating: json['average_rating'] != null
          ? double.tryParse(json['average_rating'].toString()) ?? 0.0
          : 0.0,
      totalRatings: json['total_ratings'] as int? ?? 0,
      distanceKm: json['distance_km'] != null
          ? double.tryParse(json['distance_km'].toString()) ?? 0.0
          : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'gps_lat': gpsLat,
      'gps_lng': gpsLng,
      'phone': phone,
      'logo_url': logoUrl,
      'operating_hours': operatingHours,
      'is_active': isActive,
      'average_rating': averageRating,
      'total_ratings': totalRatings,
      'distance_km': distanceKm,
    };
  }

  NearbyStoreModel copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    String? state,
    String? pincode,
    double? gpsLat,
    double? gpsLng,
    String? phone,
    String? logoUrl,
    Map<String, dynamic>? operatingHours,
    bool? isActive,
    double? averageRating,
    int? totalRatings,
    double? distanceKm,
  }) {
    return NearbyStoreModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      gpsLat: gpsLat ?? this.gpsLat,
      gpsLng: gpsLng ?? this.gpsLng,
      phone: phone ?? this.phone,
      logoUrl: logoUrl ?? this.logoUrl,
      operatingHours: operatingHours ?? this.operatingHours,
      isActive: isActive ?? this.isActive,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  /// Format distance for display (e.g., "1.2 km")
  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km';

  /// Format rating for display (e.g., "4.5")
  String get formattedRating => averageRating.toStringAsFixed(1);

  /// Check if store is currently open based on operating hours
  bool get isCurrentlyOpen {
    if (operatingHours == null) return true; // Assume open if no hours specified

    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    final todayHours = operatingHours![dayName.toLowerCase()];

    if (todayHours == null || todayHours is! Map) return false;

    final openTime = todayHours['open'] as String?;
    final closeTime = todayHours['close'] as String?;

    if (openTime == null || closeTime == null) return false;

    try {
      final currentMinutes = now.hour * 60 + now.minute;
      final openMinutes = _parseTime(openTime);
      final closeMinutes = _parseTime(closeTime);

      return currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
    } catch (e) {
      return true; // Assume open if parsing fails
    }
  }

  /// Get closing time string (e.g., "10 PM")
  String? get closingTime {
    if (operatingHours == null) return null;

    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    final todayHours = operatingHours![dayName.toLowerCase()];

    if (todayHours == null || todayHours is! Map) return null;

    return todayHours['close'] as String?;
  }

  String _getDayName(int weekday) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[weekday - 1];
  }

  int _parseTime(String time) {
    // Parse time format like "10:00 AM" or "10:00"
    final cleaned = time.trim().toUpperCase();
    final parts = cleaned.split(':');

    if (parts.length < 2) return 0;

    int hours = int.tryParse(parts[0]) ?? 0;
    final minuteParts = parts[1].split(' ');
    final minutes = int.tryParse(minuteParts[0]) ?? 0;

    if (minuteParts.length > 1 && minuteParts[1] == 'PM' && hours != 12) {
      hours += 12;
    } else if (minuteParts.length > 1 && minuteParts[1] == 'AM' && hours == 12) {
      hours = 0;
    }

    return hours * 60 + minutes;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        city,
        state,
        pincode,
        gpsLat,
        gpsLng,
        phone,
        logoUrl,
        operatingHours,
        isActive,
        averageRating,
        totalRatings,
        distanceKm,
      ];
}
