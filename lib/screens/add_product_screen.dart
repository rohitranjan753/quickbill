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
  BarcodeType _barcodeType = BarcodeType.EAN;
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
          const SnackBar(
            content: Text('Product added successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding product: $e')),
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
        title: const Text('Add Product'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection(
              title: 'Basic Information',
              icon: Icons.info_outline,
              children: [
                TextFormField(
                  controller: _skuController,
                  decoration: const InputDecoration(
                    labelText: 'SKU *',
                    hintText: 'e.g., PROD-001',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'SKU is required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _barcodeController,
                        decoration: const InputDecoration(
                          labelText: 'Barcode *',
                          hintText: 'e.g., 1234567890123',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Barcode is required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<BarcodeType>(
                        value: _barcodeType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name *',
                    hintText: 'e.g., Organic Milk',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Product name is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _brandNameController,
                  decoration: const InputDecoration(
                    labelText: 'Brand Name',
                    hintText: 'e.g., Amul',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    hintText: 'e.g., Dairy',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Category is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Product description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Unit & Quantity',
              icon: Icons.scale,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<UnitType>(
                        value: _unitType,
                        decoration: const InputDecoration(
                          labelText: 'Unit Type',
                          border: OutlineInputBorder(),
                        ),
                        items: UnitType.values
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type.name.toUpperCase()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _unitType = value!;
                            // Auto-update base unit
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
                      child: DropdownButtonFormField<BaseUnit>(
                        value: _baseUnit,
                        decoration: const InputDecoration(
                          labelText: 'Base Unit',
                          border: OutlineInputBorder(),
                        ),
                        items: BaseUnit.values
                            .map((unit) => DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit.name.toUpperCase()),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _baseUnit = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _baseQuantityController,
                  decoration: const InputDecoration(
                    labelText: 'Base Quantity *',
                    hintText: 'e.g., 500',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Base quantity is required' : null,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Is Weighted Product'),
                  subtitle: const Text('Product sold by weight'),
                  value: _isWeighted,
                  onChanged: (value) => setState(() => _isWeighted = value),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Pricing & Tax',
              icon: Icons.attach_money,
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _taxPercentageController,
                  decoration: const InputDecoration(
                    labelText: 'Tax Percentage',
                    suffixText: '%',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Tax Inclusive'),
                  subtitle: const Text('Tax is included in selling price'),
                  value: _isTaxInclusive,
                  onChanged: (value) => setState(() => _isTaxInclusive = value),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Inventory & Settings',
              icon: Icons.inventory_2,
              children: [
                TextFormField(
                  controller: _stockQuantityController,
                  decoration: const InputDecoration(
                    labelText: 'Stock Quantity',
                    hintText: 'Leave empty for unlimited',
                    border: OutlineInputBorder(),
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
                const SizedBox(height: 16),
                DropdownButtonFormField<ProductStatus>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: ProductStatus.values
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.name.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _status = value!),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Age Restricted'),
                  subtitle: const Text('Requires age verification'),
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
              onPressed: _isLoading ? null : _saveProduct,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF10B981),
                disabledBackgroundColor: Colors.grey,
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
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
