import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all products
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final querySnapshot = await _firestore.collection('products').get();
      return querySnapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting products: $e');
      return [];
    }
  }

  // Get product by ID
  Future<ProductModel?> getProductById(String id) async {
    try {
      final doc = await _firestore.collection('products').doc(id).get();
      if (doc.exists && doc.data() != null) {
        return ProductModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting product: $e');
      return null;
    }
  }

  // Get product by GTIN (barcode)
  Future<ProductModel?> getProductByGtin(String gtin) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('gtin', isEqualTo: gtin)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return ProductModel.fromJson(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      debugPrint('Error getting product by GTIN: $e');
      return null;
    }
  }

  // Add product
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
  Future<void> deleteProduct(String id) async {
    try {
      await _firestore.collection('products').doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting product: $e');
      rethrow;
    }
  }

  // Batch add products
  Future<void> batchAddProducts(List<ProductModel> products) async {
    try {
      final batch = _firestore.batch();
      
      for (var product in products) {
        final docRef = _firestore.collection('products').doc(product.id);
        batch.set(docRef, product.toJson());
      }
      
      await batch.commit();
      debugPrint('Successfully uploaded ${products.length} products to Firebase');
    } catch (e) {
      debugPrint('Error batch adding products: $e');
      rethrow;
    }
  }
}
