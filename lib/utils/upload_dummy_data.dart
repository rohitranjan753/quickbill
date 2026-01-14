import 'package:flutter/material.dart';
import '../data/dummy_products.dart';
import '../services/product_service.dart';

/// Utility function to upload all dummy products to Firebase
/// Call this function from a button or during app initialization (for dev only)
Future<void> uploadDummyProductsToFirebase() async {
  final productService = ProductService();
  
  try {
    debugPrint('Starting to upload ${DummyProducts.all.length} products to Firebase...');
    
    await productService.batchAddProducts(DummyProducts.all);
    
    debugPrint('✅ Successfully uploaded all dummy products to Firebase!');
  } catch (e) {
    debugPrint('❌ Error uploading dummy products: $e');
    rethrow;
  }
}

/// Upload products by category
Future<void> uploadProductsByCategory(String category) async {
  final productService = ProductService();
  final products = DummyProducts.getByCategory(category);
  
  try {
    debugPrint('Uploading ${products.length} products from category: $category');
    
    await productService.batchAddProducts(products);
    
    debugPrint('✅ Successfully uploaded $category products!');
  } catch (e) {
    debugPrint('❌ Error uploading $category products: $e');
    rethrow;
  }
}

/// Widget that provides a button to upload dummy data (for development)
class UploadDummyDataButton extends StatefulWidget {
  const UploadDummyDataButton({super.key});

  @override
  State<UploadDummyDataButton> createState() => _UploadDummyDataButtonState();
}

class _UploadDummyDataButtonState extends State<UploadDummyDataButton> {
  bool _isUploading = false;

  Future<void> _handleUpload() async {
    setState(() => _isUploading = true);
    
    try {
      await uploadDummyProductsToFirebase();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Successfully uploaded all products to Firebase!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isUploading ? null : _handleUpload,
      icon: _isUploading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.cloud_upload),
      label: Text(_isUploading ? 'Uploading...' : 'Upload Dummy Products'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }
}
