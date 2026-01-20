import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/receipt_model.dart';
import '../models/store_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
}
