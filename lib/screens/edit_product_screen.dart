import '../utils/app_theme.dart';
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

    _nameController = TextEditingController(text: widget.product.name);
    _brandNameController =
        TextEditingController(text: widget.product.brandName ?? '');
    _descriptionController =
        TextEditingController(text: widget.product.description ?? '');
    _mrpController =
        TextEditingController(text: widget.product.mrp.toStringAsFixed(2));
    _sellingPriceController = TextEditingController(
        text: widget.product.sellingPrice.toStringAsFixed(2));
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

    final mrp = double.tryParse(_mrpController.text);
    final sellingPrice = double.tryParse(_sellingPriceController.text);

    if (mrp != null && sellingPrice != null && sellingPrice > mrp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selling price cannot be greater than MRP'),
          backgroundColor: AppColors.error,
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
          SnackBar(
            content: const Text('Product updated successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating product: $e'),
            backgroundColor: AppColors.error,
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Edit Product',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _isLoading ? null : _updateProduct,
              icon: const Icon(Icons.save_rounded,
                  color: AppColors.accent, size: 18),
              label: const Text(
                'Save',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
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
            const SizedBox(height: 16),

            _buildSectionCard(
              title: 'Basic Details',
              icon: Icons.edit_rounded,
              children: [
                _buildField(
                  controller: _nameController,
                  label: 'Product Name',
                  required: true,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Product name is required' : null,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _brandNameController,
                  label: 'Brand Name',
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _descriptionController,
                  label: 'Description',
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: 'Pricing',
              icon: Icons.currency_rupee_rounded,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _mrpController,
                        label: 'MRP',
                        prefixText: '₹ ',
                        required: true,
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
                      child: _buildField(
                        controller: _sellingPriceController,
                        label: 'Selling Price',
                        prefixText: '₹ ',
                        required: true,
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
            const SizedBox(height: 16),

            _buildSectionCard(
              title: 'Inventory Management',
              icon: Icons.inventory_rounded,
              children: [
                _buildField(
                  controller: _stockQuantityController,
                  label: 'Current Stock Quantity',
                  hint: 'Leave empty for unlimited',
                  suffixText: widget.product.baseUnit.name.toUpperCase(),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _maxQuantityController,
                  label: 'Max Quantity Per Cart',
                  hint: 'Leave empty for unlimited',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: 'Product Settings',
              icon: Icons.settings_rounded,
              children: [
                _buildDropdown<ProductStatus>(
                  label: 'Product Status',
                  value: _status,
                  items: ProductStatus.values
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: status == ProductStatus.active
                                        ? AppColors.success
                                        : AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(status.name.toUpperCase()),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _status = value!),
                ),
                const SizedBox(height: 4),
                _buildToggleRow(
                  label: 'Age Restricted',
                  subtitle: 'Requires age verification for purchase',
                  value: _isAgeRestricted,
                  onChanged: (value) =>
                      setState(() => _isAgeRestricted = value),
                ),
                _buildToggleRow(
                  label: 'Scan Allowed',
                  subtitle: 'Product can be scanned by customers',
                  value: _scanAllowed,
                  onChanged: (value) => setState(() => _scanAllowed = value),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.border,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              const Text(
                'Product Information',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          _buildInfoRow('SKU', widget.product.sku),
          _buildInfoRow('Barcode', widget.product.barcode),
          _buildInfoRow('Category', widget.product.category),
          _buildInfoRow(
            'Unit',
            '${widget.product.baseQuantity} ${widget.product.baseUnit.name.toUpperCase()}',
          ),
          _buildInfoRow(
            'Tax',
            '${widget.product.taxPercentage}% ${widget.product.isTaxInclusive ? "(Inclusive)" : "(Exclusive)"}',
          ),
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
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Discount',
                style: TextStyle(fontSize: 13, color: AppColors.accent),
              ),
              Text(
                '${discount.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Customer Pays',
                style: TextStyle(fontSize: 13, color: AppColors.accent),
              ),
              Text(
                '₹${widget.product.finalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accentSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 17, color: AppColors.accent),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? prefixText,
    String? suffixText,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        labelStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w400,
        ),
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.textTertiary,
        ),
        prefixText: prefixText,
        suffixText: suffixText,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
      dropdownColor: AppColors.surface,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildToggleRow({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accent,
            activeTrackColor: AppColors.accentSurface,
            inactiveThumbColor: AppColors.textTertiary,
            inactiveTrackColor: AppColors.border,
          ),
        ],
      ),
    );
  }
}
