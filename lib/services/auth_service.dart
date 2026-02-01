import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = 
          await _firebaseAuth.signInWithCredential(credential);

      final User? user = userCredential.user;
      
      if (user != null) {
        // Check if user was previously added by a store admin (pending sync)
        final pendingUserQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: user.email)
            .where('isPendingSync', isEqualTo: true)
            .limit(1)
            .get();

        if (pendingUserQuery.docs.isNotEmpty) {
          // User was pre-added by admin - migrate to real Firebase UID
          final pendingDoc = pendingUserQuery.docs.first;
          final pendingUser = UserModel.fromJson(pendingDoc.data());

          // Create new user with real Firebase UID but keep store association
          final migratedUser = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? pendingUser.displayName,
            photoURL: user.photoURL,
            role: pendingUser.role, // Keep role from admin
            storeId: pendingUser.storeId, // Keep store association
            createdAt: pendingUser.createdAt,
            lastLogin: DateTime.now(),
            isActive: pendingUser.isActive,
            isPendingSync: false, // No longer pending
          );

          // Save with real Firebase UID
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(migratedUser.toJson());

          // Delete the temporary pending record
          await _firestore.collection('users').doc(pendingDoc.id).delete();

          return migratedUser;
        }

        // Check if user exists in Firestore with Firebase UID
        final existingUser = await getUserFromFirestore(user.uid);

        if (existingUser != null) {
          // Update last login and profile info for existing user
          final updatedUser = existingUser.copyWith(
            lastLogin: DateTime.now(),
            photoURL: user.photoURL,
            displayName: user.displayName ?? existingUser.displayName,
          );
          await _saveUserToFirestore(updatedUser);
          return updatedUser;
        } else {
          // Create new user with default customer role
          final userModel = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? 'User',
            photoURL: user.photoURL,
            role: UserRole.customer, // Default role for new users
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
          );

          // Save new user to Firestore
          await _saveUserToFirestore(userModel);

          return userModel;
        }
      }
      
      return null;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Save user to Firestore
  Future<void> _saveUserToFirestore(UserModel user) async {
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Update last login and profile info (preserve role and storeId)
        await docRef.update({
          'lastLogin': user.lastLogin.toIso8601String(),
          'photoURL': user.photoURL,
          'displayName': user.displayName,
        });
      } else {
        // Create new user document
        await docRef.set(user.toJson());
      }
    } catch (e) {
      print('Error saving user to Firestore: $e');
      rethrow;
    }
  }

  // Get user from Firestore
  Future<UserModel?> getUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user from Firestore: $e');
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
      final updates = <String, dynamic>{'role': role.name};

      if (storeId != null) {
        updates['storeId'] = storeId;
      }

      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      print('Error updating user role: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
}
