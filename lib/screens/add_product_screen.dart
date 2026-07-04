import '../utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _uuid = const Uuid();

  // Controllers
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _brandNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _baseQuantityController = TextEditingController(text: '1');
  final _mrpController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _taxPercentageController = TextEditingController(text: '0');
  final _maxQuantityController = TextEditingController();
  final _stockQuantityController = TextEditingController();

  // Dropdown values
  BarcodeType _barcodeType = BarcodeType.ean;
  UnitType _unitType = UnitType.piece;
  BaseUnit _baseUnit = BaseUnit.pcs;
  ProductStatus _status = ProductStatus.active;

  // Boolean values
  bool _isWeighted = false;
  bool _isAgeRestricted = false;
  bool _isTaxInclusive = true;
  bool _scanAllowed = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _skuController.dispose();
    _barcodeController.dispose();
    _nameController.dispose();
    _brandNameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _baseQuantityController.dispose();
    _mrpController.dispose();
    _sellingPriceController.dispose();
    _taxPercentageController.dispose();
    _maxQuantityController.dispose();
    _stockQuantityController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to add products')),
      );
      return;
    }

    final user = authState.user;
    if (user.storeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No store associated with your account')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final product = ProductModel(
        id: _uuid.v4(),
        storeId: user.storeId!,
        sku: _skuController.text.trim(),
        barcode: _barcodeController.text.trim(),
        barcodeType: _barcodeType,
        name: _nameController.text.trim(),
        brandName: _brandNameController.text.trim().isEmpty
            ? null
            : _brandNameController.text.trim(),
        category: _categoryController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        unitType: _unitType,
        baseUnit: _baseUnit,
        baseQuantity: double.parse(_baseQuantityController.text),
        isWeighted: _isWeighted,
        isAgeRestricted: _isAgeRestricted,
        mrp: double.parse(_mrpController.text),
        sellingPrice: double.parse(_sellingPriceController.text),
        taxPercentage: double.parse(_taxPercentageController.text),
        isTaxInclusive: _isTaxInclusive,
        currency: 'INR',
        maxQuantityPerCart: _maxQuantityController.text.isEmpty
            ? null
            : int.parse(_maxQuantityController.text),
        scanAllowed: _scanAllowed,
        stockQuantity: _stockQuantityController.text.isEmpty
            ? null
            : double.parse(_stockQuantityController.text),
        status: _status,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.addProduct(product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Product added successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding product: $e'),
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
          'Add Product',
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
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionCard(
              title: 'Basic Information',
              icon: Icons.info_outline_rounded,
              children: [
                _buildField(
                  controller: _skuController,
                  label: 'SKU',
                  hint: 'e.g., PROD-001',
                  required: true,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'SKU is required' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildField(
                        controller: _barcodeController,
                        label: 'Barcode',
                        hint: 'e.g., 1234567890123',
                        required: true,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Barcode is required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown<BarcodeType>(
                        label: 'Type',
                        value: _barcodeType,
                        items: BarcodeType.values
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type.name.toUpperCase()),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _barcodeType = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _nameController,
                  label: 'Product Name',
                  hint: 'e.g., Organic Milk',
                  required: true,
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Product name is required'
                      : null,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _brandNameController,
                  label: 'Brand Name',
                  hint: 'e.g., Amul',
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _categoryController,
                  label: 'Category',
                  hint: 'e.g., Dairy',
                  required: true,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Category is required' : null,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Product description',
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Unit & Quantity',
              icon: Icons.scale_rounded,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown<UnitType>(
                        label: 'Unit Type',
                        value: _unitType,
                        items: UnitType.values
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type.name.toUpperCase()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _unitType = value!;
                            if (_unitType == UnitType.weight) {
                              _baseUnit = BaseUnit.g;
                            } else {
                              _baseUnit = BaseUnit.pcs;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown<BaseUnit>(
                        label: 'Base Unit',
                        value: _baseUnit,
                        items: BaseUnit.values
                            .map((unit) => DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit.name.toUpperCase()),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _baseUnit = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _baseQuantityController,
                  label: 'Base Quantity',
                  hint: 'e.g., 500',
                  required: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Base quantity is required' : null,
                ),
                const SizedBox(height: 4),
                _buildToggleRow(
                  label: 'Weighted Product',
                  subtitle: 'Product sold by weight',
                  value: _isWeighted,
                  onChanged: (value) => setState(() => _isWeighted = value),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Pricing & Tax',
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
                const SizedBox(height: 14),
                _buildField(
                  controller: _taxPercentageController,
                  label: 'Tax Percentage',
                  suffixText: '%',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                ),
                const SizedBox(height: 4),
                _buildToggleRow(
                  label: 'Tax Inclusive',
                  subtitle: 'Tax is included in selling price',
                  value: _isTaxInclusive,
                  onChanged: (value) => setState(() => _isTaxInclusive = value),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Inventory & Settings',
              icon: Icons.inventory_2_rounded,
              children: [
                _buildField(
                  controller: _stockQuantityController,
                  label: 'Stock Quantity',
                  hint: 'Leave empty for unlimited',
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
                const SizedBox(height: 14),
                _buildDropdown<ProductStatus>(
                  label: 'Status',
                  value: _status,
                  items: ProductStatus.values
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.name.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _status = value!),
                ),
                const SizedBox(height: 4),
                _buildToggleRow(
                  label: 'Age Restricted',
                  subtitle: 'Requires age verification',
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

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
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
                        'Add Product',
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
