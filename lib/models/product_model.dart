import 'package:equatable/equatable.dart';

enum UnitType { piece, weight }

enum BaseUnit { g, kg, ml, ltr, pcs }

enum BarcodeType { ean, upc, qr }

enum ProductStatus { active, inactive }

class ProductModel extends Equatable {
  final String id;
  final String storeId;
  final String? branchId;
  final String sku;
  final String barcode;
  final BarcodeType barcodeType;
  final String name;
  final String? brandName;
  final String category;
  final String? description;
  final UnitType unitType;
  final BaseUnit baseUnit;
  final double baseQuantity;
  final bool isWeighted;
  final bool isAgeRestricted;
  final double mrp;
  final double sellingPrice;
  final double taxPercentage;
  final bool isTaxInclusive;
  final String currency;
  final int? maxQuantityPerCart;
  final bool scanAllowed;
  final double? stockQuantity;
  final ProductStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.storeId,
    this.branchId,
    required this.sku,
    required this.barcode,
    required this.barcodeType,
    required this.name,
    this.brandName,
    required this.category,
    this.description,
    required this.unitType,
    required this.baseUnit,
    required this.baseQuantity,
    required this.isWeighted,
    required this.isAgeRestricted,
    required this.mrp,
    required this.sellingPrice,
    required this.taxPercentage,
    required this.isTaxInclusive,
    required this.currency,
    this.maxQuantityPerCart,
    required this.scanAllowed,
    this.stockQuantity,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // Computed property for price (using selling_price)
  double get price => sellingPrice;

  // Computed property for final price after tax (if not inclusive)
  double get finalPrice {
    if (isTaxInclusive) {
      return sellingPrice;
    } else {
      return sellingPrice * (1 + taxPercentage / 100);
    }
  }

  // Computed property for tax amount
  double get taxAmount {
    if (isTaxInclusive) {
      return sellingPrice - (sellingPrice / (1 + taxPercentage / 100));
    } else {
      return sellingPrice * (taxPercentage / 100);
    }
  }

  ProductModel copyWith({
    String? id,
    String? storeId,
    String? branchId,
    String? sku,
    String? barcode,
    BarcodeType? barcodeType,
    String? name,
    String? brandName,
    String? category,
    String? description,
    UnitType? unitType,
    BaseUnit? baseUnit,
    double? baseQuantity,
    bool? isWeighted,
    bool? isAgeRestricted,
    double? mrp,
    double? sellingPrice,
    double? taxPercentage,
    bool? isTaxInclusive,
    String? currency,
    int? maxQuantityPerCart,
    bool? scanAllowed,
    double? stockQuantity,
    ProductStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      branchId: branchId ?? this.branchId,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      barcodeType: barcodeType ?? this.barcodeType,
      name: name ?? this.name,
      brandName: brandName ?? this.brandName,
      category: category ?? this.category,
      description: description ?? this.description,
      unitType: unitType ?? this.unitType,
      baseUnit: baseUnit ?? this.baseUnit,
      baseQuantity: baseQuantity ?? this.baseQuantity,
      isWeighted: isWeighted ?? this.isWeighted,
      isAgeRestricted: isAgeRestricted ?? this.isAgeRestricted,
      mrp: mrp ?? this.mrp,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      isTaxInclusive: isTaxInclusive ?? this.isTaxInclusive,
      currency: currency ?? this.currency,
      maxQuantityPerCart: maxQuantityPerCart ?? this.maxQuantityPerCart,
      scanAllowed: scanAllowed ?? this.scanAllowed,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      branchId: json['branch_id'] as String?,
      sku: json['sku'] as String,
      barcode: json['barcode'] as String,
      barcodeType: BarcodeType.values.firstWhere(
        (e) =>
            e.name.toLowerCase() ==
            (json['barcode_type'] as String? ?? '').toLowerCase(),
        orElse: () => BarcodeType.ean,
      ),
      name: json['name'] as String,
      brandName: json['brand_name'] as String?,
      category: json['category'] as String,
      description: json['description'] as String?,
      unitType: UnitType.values.firstWhere(
        (e) => e.name == json['unit_type'],
        orElse: () => UnitType.piece,
      ),
      baseUnit: BaseUnit.values.firstWhere(
        (e) => e.name == json['base_unit'],
        orElse: () => BaseUnit.pcs,
      ),
      baseQuantity: (json['base_quantity'] as num).toDouble(),
      isWeighted: json['is_weighted'] as bool? ?? false,
      isAgeRestricted: json['is_age_restricted'] as bool? ?? false,
      mrp: (json['mrp'] as num).toDouble(),
      sellingPrice: (json['selling_price'] as num).toDouble(),
      taxPercentage: (json['tax_percentage'] as num).toDouble(),
      isTaxInclusive: json['is_tax_inclusive'] as bool? ?? true,
      currency: json['currency'] as String? ?? 'INR',
      maxQuantityPerCart: json['max_quantity_per_cart'] as int?,
      scanAllowed: json['scan_allowed'] as bool? ?? true,
      stockQuantity: json['stock_quantity'] != null 
          ? (json['stock_quantity'] as num).toDouble() 
          : null,
      status: ProductStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ProductStatus.active,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'branch_id': branchId,
      'sku': sku,
      'barcode': barcode,
      'barcode_type': barcodeType.name,
      'name': name,
      'brand_name': brandName,
      'category': category,
      'description': description,
      'unit_type': unitType.name,
      'base_unit': baseUnit.name,
      'base_quantity': baseQuantity,
      'is_weighted': isWeighted,
      'is_age_restricted': isAgeRestricted,
      'mrp': mrp,
      'selling_price': sellingPrice,
      'tax_percentage': taxPercentage,
      'is_tax_inclusive': isTaxInclusive,
      'currency': currency,
      'max_quantity_per_cart': maxQuantityPerCart,
      'scan_allowed': scanAllowed,
      'stock_quantity': stockQuantity,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        storeId,
        branchId,
        sku,
        barcode,
        barcodeType,
        name,
        brandName,
        category,
        description,
        unitType,
        baseUnit,
        baseQuantity,
        isWeighted,
        isAgeRestricted,
        mrp,
        sellingPrice,
        taxPercentage,
        isTaxInclusive,
        currency,
        maxQuantityPerCart,
        scanAllowed,
        stockQuantity,
        status,
        createdAt,
        updatedAt,
      ];
}
