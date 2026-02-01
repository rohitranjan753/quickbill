import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quickbill/models/cart_item_model.dart';
import '../models/product_model.dart';
import '../models/receipt_model.dart';
import '../models/store_model.dart';
import '../models/user_model.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Get product by barcode
  Future<ProductModel?> getProductByBarcode(String barcode) async {
    print('Fetching product for barcode: $barcode');
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return ProductModel.fromJson({...doc.data(), 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error getting product: $e');
      return null;
    }
  }

  // Save receipt to Firestore
  Future<String> saveReceipt(ReceiptModel receipt) async {
    try {
      final docRef = await _firestore.collection('receipts').add(receipt.toJson());
      return docRef.id;
    } catch (e) {
      print('Error saving receipt: $e');
      rethrow;
    }
  }

  /// Update product stock quantity
  Future<void> updateProductStock(List<CartItemModel> cartItem) async {
    try {
      for (var element in cartItem) {
        await _firestore.collection('products').doc(element.product.id).update({
          'stock_quantity': FieldValue.increment(-element.quantity),
        });
      }
    } catch (e) {
      print('Error updating product stock: $e');
      rethrow;
    }
  }
  // Get receipt by ID
  Future<ReceiptModel?> getReceipt(String receiptId) async {
    try {
      final doc = await _firestore.collection('receipts').doc(receiptId).get();
      if (doc.exists && doc.data() != null) {
        return ReceiptModel.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error getting receipt: $e');
      return null;
    }
  }

  // Get user receipts
  Stream<List<ReceiptModel>> getUserReceipts(String userId) {
    return _firestore
        .collection('receipts')
        .where('userId', isEqualTo: userId)
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReceiptModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Get all store sales/receipts
  Stream<List<ReceiptModel>> getStoreSales(String storeId) {
    return _firestore
        .collection('receipts')
        .where('storeId', isEqualTo: storeId)
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ReceiptModel.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }

  // Get store sales with date range
  Future<List<ReceiptModel>> getStoreSalesInRange(
    String storeId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('receipts')
          .where('storeId', isEqualTo: storeId)
          .where(
            'purchaseDate',
            isGreaterThanOrEqualTo: startDate.toIso8601String(),
          )
          .where('purchaseDate', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('purchaseDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ReceiptModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting store sales in range: $e');
      return [];
    }
  }

  // Verify receipt (for guard)
  Future<void> verifyReceipt(String receiptId) async {
    try {
      await _firestore.collection('receipts').doc(receiptId).update({
        'verified': true,
      });
    } catch (e) {
      print('Error verifying receipt: $e');
      rethrow;
    }
  }

  // ===== Store Management =====

  // Create a new store
  Future<void> createStore(StoreModel store) async {
    try {
      await _firestore.collection('stores').doc(store.id).set(store.toJson());
    } catch (e) {
      print('Error creating store: $e');
      rethrow;
    }
  }

  // Get store by ID
  Future<StoreModel?> getStore(String storeId) async {
    try {
      final doc = await _firestore.collection('stores').doc(storeId).get();
      if (doc.exists && doc.data() != null) {
        return StoreModel.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error getting store: $e');
      return null;
    }
  }

  // Update store
  Future<void> updateStore(StoreModel store) async {
    try {
      await _firestore
          .collection('stores')
          .doc(store.id)
          .update(store.toJson());
    } catch (e) {
      print('Error updating store: $e');
      rethrow;
    }
  }

  // ===== Product Management =====

  // Get all products for a store
  Stream<List<ProductModel>> getStoreProducts(String storeId) {
    return _firestore
        .collection('products')
        .where('store_id', isEqualTo: storeId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ProductModel.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }

  // Add product to store
  Future<void> addProduct(ProductModel product) async {
    try {
      await _firestore
          .collection('products')
          .doc(product.id)
          .set(product.toJson());
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    }
  }

  // Update product
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _firestore
          .collection('products')
          .doc(product.id)
          .update(product.toJson());
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }

  // ===== User Role Management =====

  // Update user role
  Future<void> updateUserRole(
    String userId,
    UserRole role,
    String? storeId,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': role.name,
        'storeId': storeId,
      });
    } catch (e) {
      print('Error updating user role: $e');
      rethrow;
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Get all users for a store
  Stream<List<UserModel>> getStoreUsers(String storeId) {
    return _firestore
        .collection('users')
        .where('storeId', isEqualTo: storeId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromJson(doc.data()))
              .toList(),
        );
  }

  // Add user to store (creates pending user or updates existing)
  Future<UserModel> addUserToStore({
    required String email,
    required String storeId,
    required UserRole role,
  }) async {
    try {
      // Check if user already exists by email
      final existingUserQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingUserQuery.docs.isNotEmpty) {
        // User exists - update their role and storeId
        final doc = existingUserQuery.docs.first;
        final existingUser = UserModel.fromJson(doc.data());

        await _firestore.collection('users').doc(doc.id).update({
          'role': role.name,
          'storeId': storeId,
          'isActive': true,
        });

        return existingUser.copyWith(
          role: role,
          storeId: storeId,
          isActive: true,
        );
      } else {
        // Create new pending user with temporary UUID
        final tempUid = 'temp_${_uuid.v4()}';
        final newUser = UserModel(
          uid: tempUid,
          email: email,
          displayName: email.split('@')[0], // Use email prefix as name
          role: role,
          storeId: storeId,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          isActive: true,
          isPendingSync: true, // Mark as pending sync
        );

        await _firestore.collection('users').doc(tempUid).set(newUser.toJson());

        return newUser;
      }
    } catch (e) {
      print('Error adding user to store: $e');
      rethrow;
    }
  }

  // Update user status (active/inactive)
  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
      });
    } catch (e) {
      print('Error updating user status: $e');
      rethrow;
    }
  }

  // Update user role in store
  Future<void> updateStoreUserRole(String userId, UserRole role) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': role.name,
      });
    } catch (e) {
      print('Error updating store user role: $e');
      rethrow;
    }
  }

  // Remove user from store
  Future<void> removeUserFromStore(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final user = UserModel.fromJson(userDoc.data()!);

      if (user.isPendingSync) {
        // If user is pending, delete the document
        await _firestore.collection('users').doc(userId).delete();
      } else {
        // If user has signed in, just remove store association
        await _firestore.collection('users').doc(userId).update({
          'role': UserRole.customer.name,
          'storeId': null,
          'isActive': true,
        });
      }
    } catch (e) {
      print('Error removing user from store: $e');
      rethrow;
    }
  }

  // Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return UserModel.fromJson(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }
}
