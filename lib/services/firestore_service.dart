import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:quickbill/models/cart_item_model.dart';
import '../models/product_model.dart';
import '../models/receipt_model.dart';
import '../models/store_model.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Constructor - Enable offline persistence
  FirestoreService() {
    _enableOfflinePersistence();
  }

  // Enable offline persistence for Firestore
  void _enableOfflinePersistence() {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Get product by barcode for a specific store
  Future<ProductModel?> getProductByBarcodeAndStore(
    String barcode,
    String storeId,
  ) async {
    debugPrint('Fetching product for barcode: $barcode in store: $storeId');
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('barcode', isEqualTo: barcode)
          .where('store_id', isEqualTo: storeId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return ProductModel.fromJson({...doc.data(), 'id': doc.id});
      }
      return null;
    } catch (e) {
      debugPrint('Error getting product: $e');
      return null;
    }
  }

  // Get product by barcode (legacy - for backward compatibility)
  Future<ProductModel?> getProductByBarcode(String barcode) async {
    debugPrint('Fetching product for barcode: $barcode');
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
      debugPrint('Error getting product: $e');
      return null;
    }
  }

  // Save receipt to Firestore
  Future<String> saveReceipt(ReceiptModel receipt) async {
    try {
      final docRef = await _firestore.collection('receipts').add(receipt.toJson());
      return docRef.id;
    } catch (e) {
      debugPrint('Error saving receipt: $e');
      rethrow;
    }
  }

  /// Update product stock
  Future<void> updateProductStock(List<CartItemModel> cartItem) async {
    try {
      final batch = _firestore.batch();
      
      for (var element in cartItem) {
        final docRef = _firestore
            .collection('products')
            .doc(element.product.id);
        batch.update(docRef, {
          'stock_quantity': FieldValue.increment(-element.quantity),
        });
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error updating product stock: $e');
      rethrow;
    }
  }

  /// Validate stock availability before checkout
  Future<void> validateAndReserveStock(List<CartItemModel> cartItems) async {
    try {
      for (var item in cartItems) {
        final productDoc = await _firestore
            .collection('products')
            .doc(item.product.id)
            .get();

        if (!productDoc.exists) {
          throw Exception('Product ${item.product.name} no longer exists');
        }

        final data = productDoc.data()!;
        final currentStock = data['stock_quantity'];

        // Only validate if stock tracking is enabled (not null)
        if (currentStock != null) {
          final stockValue = (currentStock as num).toDouble();

          if (stockValue < item.quantity) {
            throw Exception(
              'Insufficient stock for ${item.product.name}. '
              'Available: ${stockValue.toInt()}, Required: ${item.quantity}',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error validating stock: $e');
      rethrow;
    }
  }

  /// Process checkout with atomic transaction (stock update + receipt save)
  Future<String> processCheckout(
    ReceiptModel receipt,
    List<CartItemModel> cartItems,
  ) async {
    try {
      // Use a batch write for atomic operation
      final batch = _firestore.batch();

      // 1. Update stock for all products
      for (var item in cartItems) {
        final productRef = _firestore
            .collection('products')
            .doc(item.product.id);
        batch.update(productRef, {
          'stock_quantity': FieldValue.increment(-item.quantity),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      // 2. Create receipt
      final receiptRef = _firestore.collection('receipts').doc(receipt.id);
      batch.set(receiptRef, receipt.toJson());

      // 3. Commit all changes atomically
      await batch.commit();

      return receipt.id;
    } catch (e) {
      debugPrint('Error processing checkout: $e');
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
      debugPrint('Error getting receipt: $e');
      return null;
    }
  }

  // Get receipt stream for real-time updates
  Stream<ReceiptModel?> getReceiptStream(String receiptId) {
    return _firestore.collection('receipts').doc(receiptId).snapshots().map((
      doc,
    ) {
      if (doc.exists && doc.data() != null) {
        return ReceiptModel.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    });
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

  // Get all store sales/receipts with pagination support
  Stream<List<ReceiptModel>> getStoreSales(String storeId, {int limit = 100}) {
    return _firestore
        .collection('receipts')
        .where('storeId', isEqualTo: storeId)
        .orderBy('purchaseDate', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ReceiptModel.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }

  // Get store sales with pagination for large datasets
  Future<List<ReceiptModel>> getStoreSalesPaginated(
    String storeId, {
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('receipts')
          .where('storeId', isEqualTo: storeId)
          .orderBy('purchaseDate', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map(
            (doc) => ReceiptModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting paginated store sales: $e');
      return [];
    }
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
      debugPrint('Error getting store sales in range: $e');
      return [];
    }
  }

  // Verify receipt (for guard)
  Future<void> verifyReceipt(String receiptId) async {
    try {
      // Check if receipt exists first
      final receiptDoc = await _firestore
          .collection('receipts')
          .doc(receiptId)
          .get();

      if (!receiptDoc.exists) {
        throw Exception('Receipt not found. It may have been deleted.');
      }

      final receiptData = receiptDoc.data();
      if (receiptData?['verified'] == true) {
        throw Exception('Receipt has already been verified.');
      }

      await _firestore.collection('receipts').doc(receiptId).update({
        'verified': true,
        'verifiedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error verifying receipt: $e');
      rethrow;
    }
  }

  // ===== Store Management =====

  // Create a new store
  Future<void> createStore(StoreModel store) async {
    try {
      await _firestore.collection('stores').doc(store.id).set(store.toJson());
    } catch (e) {
      debugPrint('Error creating store: $e');
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
      debugPrint('Error getting store: $e');
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
      debugPrint('Error updating store: $e');
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
      debugPrint('Error adding product: $e');
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
      debugPrint('Error updating product: $e');
      rethrow;
    }
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
    } catch (e) {
      debugPrint('Error deleting product: $e');
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
      debugPrint('Error updating user role: $e');
      rethrow;
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error getting user data: $e');
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
      debugPrint('Error adding user to store: $e');
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
      debugPrint('Error updating user status: $e');
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
      debugPrint('Error updating store user role: $e');
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
      debugPrint('Error removing user from store: $e');
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
      debugPrint('Error getting user by email: $e');
      return null;
    }
  }

  // ===== Attendance Management =====

  // Check in guard
  Future<AttendanceModel> checkInGuard(String guardId, String storeId) async {
    try {
      // Check if guard already has an active attendance
      final existingQuery = await _firestore
          .collection('attendance')
          .where('guardId', isEqualTo: guardId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        // Return existing active attendance
        final doc = existingQuery.docs.first;
        return AttendanceModel.fromJson({...doc.data(), 'id': doc.id});
      }

      // Create new attendance record
      final attendance = AttendanceModel(
        id: _uuid.v4(),
        guardId: guardId,
        storeId: storeId,
        checkInTime: DateTime.now(),
        isActive: true,
      );

      await _firestore
          .collection('attendance')
          .doc(attendance.id)
          .set(attendance.toJson());

      return attendance;
    } catch (e) {
      debugPrint('Error checking in guard: $e');
      rethrow;
    }
  }

  // Check out guard
  Future<void> checkOutGuard(String attendanceId) async {
    try {
      await _firestore.collection('attendance').doc(attendanceId).update({
        'checkOutTime': DateTime.now().toIso8601String(),
        'isActive': false,
      });
    } catch (e) {
      debugPrint('Error checking out guard: $e');
      rethrow;
    }
  }

  // Get active attendance for guard
  Stream<AttendanceModel?> getActiveAttendance(String guardId) {
    return _firestore
        .collection('attendance')
        .where('guardId', isEqualTo: guardId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final doc = snapshot.docs.first;
          return AttendanceModel.fromJson({...doc.data(), 'id': doc.id});
        });
  }

  // Get attendance history for guard
  Stream<List<AttendanceModel>> getGuardAttendanceHistory(String guardId) {
    return _firestore
        .collection('attendance')
        .where('guardId', isEqualTo: guardId)
        .orderBy('checkInTime', descending: true)
        .limit(30)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    AttendanceModel.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }
}
