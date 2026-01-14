import 'package:equatable/equatable.dart';

class StoreModel extends Equatable {
  final String id;
  final String ownerId; // User ID of the store admin
  final String name;
  final String? description;
  final String? logo;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String phone;
  final String? email;
  final String? gstNumber;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StoreModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.logo,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.phone,
    this.email,
    this.gstNumber,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      logo: json['logo'] as String?,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      pincode: json['pincode'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      gstNumber: json['gst_number'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'logo': logo,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'phone': phone,
      'email': email,
      'gst_number': gstNumber,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  StoreModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    String? logo,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? phone,
    String? email,
    String? gstNumber,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StoreModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      logo: logo ?? this.logo,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gstNumber: gstNumber ?? this.gstNumber,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ownerId,
        name,
        description,
        logo,
        address,
        city,
        state,
        pincode,
        phone,
        email,
        gstNumber,
        isActive,
        createdAt,
        updatedAt,
      ];
}
