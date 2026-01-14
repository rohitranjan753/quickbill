import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/receipt_model.dart';

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
}
