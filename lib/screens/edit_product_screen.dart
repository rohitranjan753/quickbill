import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  // Controllers - Only for editable fields
  late final TextEditingController _nameController;
  late final TextEditingController _brandNameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _mrpController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _stockQuantityController;
  late final TextEditingController _maxQuantityController;

  // Editable fields
  late ProductStatus _status;
  late bool _isAgeRestricted;
  late bool _scanAllowed;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with current values
    _nameController = TextEditingController(text: widget.product.name);
    _brandNameController = TextEditingController(text: widget.product.brandName ?? '');
    _descriptionController = TextEditingController(text: widget.product.description ?? '');
    _mrpController = TextEditingController(text: widget.product.mrp.toStringAsFixed(2));
    _sellingPriceController = TextEditingController(text: widget.product.sellingPrice.toStringAsFixed(2));
    _stockQuantityController = TextEditingController(
      text: widget.product.stockQuantity?.toString() ?? '',
    );
    _maxQuantityController = TextEditingController(
      text: widget.product.maxQuantityPerCart?.toString() ?? '',
    );

    _status = widget.product.status;
    _isAgeRestricted = widget.product.isAgeRestricted;
    _scanAllowed = widget.product.scanAllowed;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandNameController.dispose();
    _descriptionController.dispose();
    _mrpController.dispose();
    _sellingPriceController.dispose();
    _stockQuantityController.dispose();
    _maxQuantityController.dispose();
    super.dispose();
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate pricing
    final mrp = double.tryParse(_mrpController.text);
    final sellingPrice = double.tryParse(_sellingPriceController.text);
    
    if (mrp != null && sellingPrice != null && sellingPrice > mrp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selling price cannot be greater than MRP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedProduct = widget.product.copyWith(
        name: _nameController.text.trim(),
        brandName: _brandNameController.text.trim().isEmpty
            ? null
            : _brandNameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        mrp: double.parse(_mrpController.text),
        sellingPrice: double.parse(_sellingPriceController.text),
        stockQuantity: _stockQuantityController.text.isEmpty
            ? null
            : double.parse(_stockQuantityController.text),
        maxQuantityPerCart: _maxQuantityController.text.isEmpty
            ? null
            : int.parse(_maxQuantityController.text),
        status: _status,
        isAgeRestricted: _isAgeRestricted,
        scanAllowed: _scanAllowed,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateProduct(updatedProduct);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product updated successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _updateProduct,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text(
              'SAVE',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Non-editable info card
            _buildInfoCard(),
            const SizedBox(height: 24),

            _buildSection(
              title: 'Basic Details',
              icon: Icons.edit,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Product name is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _brandNameController,
                  decoration: const InputDecoration(
                    labelText: 'Brand Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: 'Pricing',
              icon: Icons.currency_rupee,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _mrpController,
                        decoration: const InputDecoration(
                          labelText: 'MRP *',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'MRP is required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _sellingPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Selling Price *',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Selling price is required'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPriceCalculator(),
              ],
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: 'Inventory Management',
              icon: Icons.inventory,
              children: [
                TextFormField(
                  controller: _stockQuantityController,
                  decoration: InputDecoration(
                    labelText: 'Current Stock Quantity',
                    hintText: 'Leave empty for unlimited',
                    border: const OutlineInputBorder(),
                    suffixText: widget.product.baseUnit.name.toUpperCase(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _maxQuantityController,
                  decoration: const InputDecoration(
                    labelText: 'Max Quantity Per Cart',
                    hintText: 'Leave empty for unlimited',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: 'Product Settings',
              icon: Icons.settings,
              children: [
                DropdownButtonFormField<ProductStatus>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Product Status',
                    border: OutlineInputBorder(),
                  ),
                  items: ProductStatus.values
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Row(
                              children: [
                                Icon(
                                  status == ProductStatus.active
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: status == ProductStatus.active
                                      ? Colors.green
                                      : Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(status.name.toUpperCase()),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _status = value!),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Age Restricted'),
                  subtitle: const Text('Requires age verification for purchase'),
                  value: _isAgeRestricted,
                  onChanged: (value) =>
                      setState(() => _isAgeRestricted = value),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Scan Allowed'),
                  subtitle: const Text('Product can be scanned by customers'),
                  value: _scanAllowed,
                  onChanged: (value) => setState(() => _scanAllowed = value),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _updateProduct,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF10B981),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Update Product',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 20, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                'Product Information',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow('SKU', widget.product.sku),
          _buildInfoRow('Barcode', widget.product.barcode),
          _buildInfoRow('Category', widget.product.category),
          _buildInfoRow(
            'Unit',
            '${widget.product.baseQuantity} ${widget.product.baseUnit.name.toUpperCase()}',
          ),
          _buildInfoRow('Tax', '${widget.product.taxPercentage}% ${widget.product.isTaxInclusive ? "(Inclusive)" : "(Exclusive)"}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCalculator() {
    final mrp = double.tryParse(_mrpController.text) ?? 0;
    final selling = double.tryParse(_sellingPriceController.text) ?? 0;
    final discount = mrp > 0 ? ((mrp - selling) / mrp * 100) : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Discount:',
                style: TextStyle(fontSize: 13, color: Color(0xFF059669)),
              ),
              Text(
                '${discount.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Customer Pays:',
                style: TextStyle(fontSize: 13, color: Color(0xFF059669)),
              ),
              Text(
                '₹${widget.product.finalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}
