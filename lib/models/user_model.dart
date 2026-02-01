import 'package:equatable/equatable.dart';

enum UserRole { customer, storeAdmin, guard }

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final UserRole role;
  final String? storeId; // Only for storeAdmin and guard roles
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isActive; // Whether the user is active
  final bool
  isPendingSync; // True if user was added by admin but hasn't signed in yet

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.role = UserRole.customer,
    this.storeId,
    required this.createdAt,
    required this.lastLogin,
    this.isActive = true,
    this.isPendingSync = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      photoURL: json['photoURL'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.customer,
      ),
      storeId: json['storeId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLogin: DateTime.parse(json['lastLogin'] as String),
      isActive: json['isActive'] as bool? ?? true,
      isPendingSync: json['isPendingSync'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role.name,
      'storeId': storeId,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'isActive': isActive,
      'isPendingSync': isPendingSync,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    UserRole? role,
    String? storeId,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isActive,
    bool? isPendingSync,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      role: role ?? this.role,
      storeId: storeId ?? this.storeId,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    email,
    displayName,
    photoURL,
    role,
    storeId,
    createdAt,
    lastLogin,
    isActive,
    isPendingSync,
  ];
}
