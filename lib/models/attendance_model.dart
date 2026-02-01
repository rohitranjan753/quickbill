import 'package:equatable/equatable.dart';

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

  Duration? get workDuration {
    if (checkOutTime != null) {
      return checkOutTime!.difference(checkInTime);
    } else if (isActive) {
      return DateTime.now().difference(checkInTime);
    }
    return null;
  }

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
