import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthService {

  // Helper to convert backend role string to UserRole enum
  UserRole _getUserRole(String? role) {
    if (role == null) return UserRole.customer;

    switch (role) {
      case 'owner':
      case 'manager':
      case 'storeAdmin':
        return UserRole.storeAdmin;
      case 'guard':
        return UserRole.guard;
      case 'customer':
      default:
        return UserRole.customer;
    }
  }

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      const webClientId =
          '552286454501-i1s2fejcj044dot7u6foq9hr6eo9psat.apps.googleusercontent.com';
      // Trigger the authentication flow
      // final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      try {
        final response = await http.post(
          Uri.parse('http://10.0.2.2:3000/api/auth/google'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'id_token': googleAuth.idToken,
            'access_token': googleAuth.accessToken,
            'full_name': googleUser.displayName,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            final userData = data['data']['user'];
            final sessionData = data['data']['session'];

            // Create UserModel from backend response
            return UserModel(
              uid: userData['id'],
              email: userData['email'] ?? '',
              displayName: userData['profile']?['full_name'] ?? googleUser.displayName ?? 'User',
              photoURL: userData['profile']?['avatar_url'] ?? googleUser.photoUrl,
              role: _getUserRole(userData['role']),
              storeId: userData['store_id'],
              createdAt: DateTime.now(),
              lastLogin: DateTime.now(),
              isActive: true,
            );
          } else {
            throw Exception(data['message'] ?? 'Google sign-in failed');
          }
        } else {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'Failed to authenticate with backend');
        }
      } catch (e) {
        debugPrint('Backend authentication error: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Save user to Firestore
  Future<void> _saveUserToFirestore(UserModel user) async {
    try {
      // final docRef = _firestore.collection('users').doc(user.uid);
      // final docSnapshot = await docRef.get();

      // if (docSnapshot.exists) {
      //   // Update last login and profile info (preserve role and storeId)
      //   await docRef.update({
      //     'lastLogin': user.lastLogin.toIso8601String(),
      //     'photoURL': user.photoURL,
      //     'displayName': user.displayName,
      //   });
      // } else {
      //   // Create new user document
      //   await docRef.set(user.toJson());
      // }
    } catch (e) {
      debugPrint('Error saving user to Firestore: $e');
      rethrow;
    }
  }

  // Get user from Firestore
  Future<UserModel?> getUserFromFirestore(String uid) async {
    try {
      // final doc = await _firestore.collection('users').doc(uid).get();
      // if (doc.exists && doc.data() != null) {
      //   return UserModel.fromJson(doc.data()!);
      // }
      return null;
    } catch (e) {
      debugPrint('Error getting user from Firestore: $e');
      return null;
    }
  }

  // Update user role (for admin purposes or self-registration)
  Future<void> updateUserRole({
    required String uid,
    required UserRole role,
    String? storeId,
  }) async {
    try {
      // final updates = <String, dynamic>{'role': role.name};

      // if (storeId != null) {
      //   updates['storeId'] = storeId;
      // }

      // await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      debugPrint('Error updating user role: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // // await _googleSignIn.signOut();
      // await _firebaseAuth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }
}
