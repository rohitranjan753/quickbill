import 'package:equatable/equatable.dart';

/// Model representing a guard's attendance record at a store.
///
/// Handles:
/// - Tracking guard check-in and check-out times
/// - Calculating work duration for active and completed shifts
/// - Maintaining active shift status
///
/// Used by:
/// - FirestoreService for attendance management
/// - Guard role screens for shift tracking
/// - Store admin screens for attendance monitoring
///
/// State:
/// - isActive flag indicates if guard is currently checked in
/// - checkOutTime is null for ongoing shifts
class AttendanceModel extends Equatable {
  final String id;
  final String guardId;
  final String storeId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final bool isActive; // true if guard is currently checked in

  const AttendanceModel({
    required this.id,
    required this.guardId,
    required this.storeId,
    required this.checkInTime,
    this.checkOutTime,
    this.isActive = true,
  });

  /// Calculates the total work duration for this attendance record.
  ///
  /// Description:
  /// Computes the duration between check-in and check-out times.
  /// For active shifts, calculates duration from check-in to current time.
  ///
  /// Returns:
  /// Duration? - The work duration, or null if shift is inactive without checkout.
  ///
  /// Notes:
  /// - For completed shifts: returns checkOutTime - checkInTime
  /// - For active shifts: returns current time - checkInTime
  /// - For inactive shifts without checkout: returns null
  /// - Used for displaying shift duration in real-time
  Duration? get workDuration {
    if (checkOutTime != null) {
      return checkOutTime!.difference(checkInTime);
    } else if (isActive) {
      return DateTime.now().difference(checkInTime);
    }
    return null;
  }

  /// Deserializes an AttendanceModel from Firestore JSON data.
  ///
  /// Description:
  /// Converts Firestore document data into an AttendanceModel instance.
  /// Handles ISO8601 string parsing for timestamps.
  ///
  /// Parameters:
  /// json (Map<String, dynamic>) - Firestore document data containing attendance fields.
  ///
  /// Returns:
  /// AttendanceModel - A new instance populated with the JSON data.
  ///
  /// Notes:
  /// - Timestamps are stored as ISO8601 strings in Firestore
  /// - checkOutTime is optional and may be null for active shifts
  /// - isActive defaults to true if not present in JSON
  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      guardId: json['guardId'] as String,
      storeId: json['storeId'] as String,
      checkInTime: DateTime.parse(json['checkInTime'] as String),
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Serializes this AttendanceModel to JSON for Firestore storage.
  ///
  /// Description:
  /// Converts all attendance fields to a Firestore-compatible map.
  /// Timestamps are converted to ISO8601 strings for consistent storage.
  ///
  /// Returns:
  /// Map<String, dynamic> - JSON representation ready for Firestore write operations.
  ///
  /// Notes:
  /// - DateTime values are converted to ISO8601 strings
  /// - checkOutTime may be null for active shifts
  /// - Compatible with fromJson for round-trip serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guardId': guardId,
      'storeId': storeId,
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Creates a modified copy of this AttendanceModel with updated fields.
  ///
  /// Description:
  /// Returns a new AttendanceModel instance with specified fields overridden.
  /// Maintains immutability by creating a new instance instead of modifying.
  ///
  /// Parameters:
  /// id (String?) - Optional new attendance record ID
  /// guardId (String?) - Optional new guard ID
  /// storeId (String?) - Optional new store ID
  /// checkInTime (DateTime?) - Optional new check-in timestamp
  /// checkOutTime (DateTime?) - Optional new check-out timestamp
  /// isActive (bool?) - Optional new active status
  ///
  /// Returns:
  /// AttendanceModel - A new instance with specified fields updated.
  ///
  /// Notes:
  /// - Commonly used to set checkOutTime when guard checks out
  /// - Also used to toggle isActive flag when ending shifts
  /// - Null parameters preserve original values
  AttendanceModel copyWith({
    String? id,
    String? guardId,
    String? storeId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    bool? isActive,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      guardId: guardId ?? this.guardId,
      storeId: storeId ?? this.storeId,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        guardId,
        storeId,
        checkInTime,
        checkOutTime,
        isActive,
      ];
}
