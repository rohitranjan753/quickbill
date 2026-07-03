import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/nearby_store_model.dart';
import '../config/api_config.dart';

/// Service for interacting with the backend stores API
class StoreApiService {
  static String get _baseUrl => ApiConfig.baseUrl;

  /// Fetch nearby stores from backend API
  Future<List<NearbyStoreModel>> getNearbyStores({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/stores/nearby').replace(
        queryParameters: {
          'lat': latitude.toString(),
          'lng': longitude.toString(),
          'radius': radiusKm.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Backend returns: { success: true, data: { stores: [...], count: N }, message: "..." }
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final data = jsonResponse['data'];
          final stores = data['stores'] as List<dynamic>? ?? [];

          return stores
              .map((storeJson) => NearbyStoreModel.fromJson(storeJson as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to fetch nearby stores');
        }
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Invalid request parameters');
      } else if (response.statusCode == 404) {
        return []; // No stores found
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to fetch nearby stores: $e');
    }
  }

  /// Get store details by ID
  Future<NearbyStoreModel?> getStoreById(String storeId) async {
    try {
      final uri = Uri.parse('$_baseUrl/stores/$storeId');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          // Convert store data to NearbyStoreModel with 0 distance
          final storeData = jsonResponse['data'] as Map<String, dynamic>;
          return NearbyStoreModel.fromJson({
            ...storeData,
            'distance_km': 0.0, // Not applicable for direct fetch
          });
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to fetch store');
        }
      } else if (response.statusCode == 404) {
        return null; // Store not found
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to fetch store: $e');
    }
  }
}
