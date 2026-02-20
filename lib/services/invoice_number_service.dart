import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for generating sequential invoice numbers
class InvoiceNumberService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Generate next invoice number for a store
  /// Format: STORE_PREFIX-YYYY-NNNNNN (e.g., QBS-2026-000001)
  Future<String> generateInvoiceNumber(String storeId) async {
    try {
      final year = DateTime.now().year;
      final counterDocId = '${storeId}_$year';
      
      // Use transaction to ensure sequential numbers
      return await _firestore.runTransaction((transaction) async {
        final counterRef = _firestore
            .collection('invoice_counters')
            .doc(counterDocId);
        
        final counterDoc = await transaction.get(counterRef);
        
        int nextNumber = 1;
        
        if (counterDoc.exists) {
          nextNumber = (counterDoc.data()?['last_number'] ?? 0) + 1;
          transaction.update(counterRef, {
            'last_number': nextNumber,
            'updated_at': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(counterRef, {
            'store_id': storeId,
            'year': year,
            'last_number': nextNumber,
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
        
        // Format: QBS-2026-000001
        final storePrefix = storeId.substring(0, 3).toUpperCase();
        final paddedNumber = nextNumber.toString().padLeft(6, '0');
        return '$storePrefix-$year-$paddedNumber';
      });
    } catch (e) {
      // Fallback to timestamp-based ID if transaction fails
      return 'INV-${DateTime.now().millisecondsSinceEpoch}';
    }
  }
  
  /// Parse invoice number to get details
  static Map<String, dynamic>? parseInvoiceNumber(String invoiceNumber) {
    final parts = invoiceNumber.split('-');
    
    if (parts.length == 3) {
      return {
        'prefix': parts[0],
        'year': int.tryParse(parts[1]),
        'number': int.tryParse(parts[2]),
      };
    }
    
    return null;
  }
  
  /// Get current invoice counter for a store
  Future<int> getCurrentCounter(String storeId) async {
    try {
      final year = DateTime.now().year;
      final counterDocId = '${storeId}_$year';
      
      final doc = await _firestore
          .collection('invoice_counters')
          .doc(counterDocId)
          .get();
      
      if (doc.exists) {
        return doc.data()?['last_number'] ?? 0;
      }
      
      return 0;
    } catch (e) {
      return 0;
    }
  }
  
  /// Reset counter for new year (admin function)
  Future<void> resetYearlyCounter(String storeId, int year) async {
    try {
      final counterDocId = '${storeId}_$year';
      
      await _firestore.collection('invoice_counters').doc(counterDocId).set({
        'store_id': storeId,
        'year': year,
        'last_number': 0,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }
}
