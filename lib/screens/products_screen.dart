import '../utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';

enum SortOption {
  nameAsc,
  nameDesc,
  priceAsc,
  priceDesc,
  stockAsc,
  stockDesc,
  newest,
  oldest,
}

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  ProductStatus? _filterStatus;
  bool _showLowStock = false;
  SortOption _sortOption = SortOption.newest;
  bool _isGridView = true; // Changed default to grid view
  final Set<String> _selectedProducts = {};
  bool _isSelectionMode = false;
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    var filtered = products;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        final query = _searchQuery.toLowerCase();
        return p.name.toLowerCase().contains(query) ||
            p.sku.toLowerCase().contains(query) ||
            (p.brandName?.toLowerCase().contains(query) ?? false) ||
            p.barcode.contains(_searchQuery) ||
            p.category.toLowerCase().contains(query) ||
            (p.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    if (_filterStatus != null) {
      filtered = filtered.where((p) => p.status == _filterStatus).toList();
    }

    if (_showLowStock) {
      filtered = filtered.where((p) {
        if (p.stockQuantity == null) return false;
        return p.stockQuantity! < 10;
      }).toList();
    }

    filtered = _sortProducts(filtered);
    return filtered;
  }

  List<ProductModel> _sortProducts(List<ProductModel> products) {
    final sorted = List<ProductModel>.from(products);
    switch (_sortOption) {
      case SortOption.nameAsc:
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.nameDesc:
        sorted.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortOption.priceAsc:
        sorted.sort((a, b) => a.sellingPrice.compareTo(b.sellingPrice));
        break;
      case SortOption.priceDesc:
        sorted.sort((a, b) => b.sellingPrice.compareTo(a.sellingPrice));
        break;
      case SortOption.stockAsc:
        sorted.sort(
          (a, b) => (a.stockQuantity ?? double.infinity).compareTo(
            b.stockQuantity ?? double.infinity,
          ),
        );
        break;
      case SortOption.stockDesc:
        sorted.sort(
          (a, b) => (b.stockQuantity ?? double.infinity).compareTo(
            a.stockQuantity ?? double.infinity,
          ),
        );
        break;
      case SortOption.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.oldest:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }
    return sorted;
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedProducts.clear();
      }
      if (_isSelectionMode) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    });
  }

  void _toggleProductSelection(String productId) {
    setState(() {
      if (_selectedProducts.contains(productId)) {
        _selectedProducts.remove(productId);
      } else {
        _selectedProducts.add(productId);
      }
    });
  }

  Future<void> _bulkUpdateStatus(
    ProductStatus status,
    List<ProductModel> allProducts,
  ) async {
    final productsToUpdate = allProducts
        .where((p) => _selectedProducts.contains(p.id))
        .toList();

    try {
      for (var product in productsToUpdate) {
        await _firestoreService.updateProduct(
          product.copyWith(status: status, updatedAt: DateTime.now()),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${productsToUpdate.length} products updated'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {
          _selectedProducts.clear();
          _isSelectionMode = false;
          _fabAnimationController.reverse();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showProductActions(BuildContext context, ProductModel product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ProductActionsSheet(
        product: product,
        firestoreService: _firestoreService,
        onUpdated: () => setState(() {}),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort Products',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            RadioGroup<SortOption>(
              groupValue: _sortOption,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _sortOption = value);
                Navigator.pop(context);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...[
                    (SortOption.nameAsc, 'Name (A-Z)', Icons.sort_by_alpha),
                    (SortOption.nameDesc, 'Name (Z-A)', Icons.sort_by_alpha),
                    (
                      SortOption.priceAsc,
                      'Price (Low to High)',
                      Icons.arrow_upward,
                    ),
                    (
                      SortOption.priceDesc,
                      'Price (High to Low)',
                      Icons.arrow_downward,
                    ),
                    (SortOption.stockAsc, 'Stock (Low to High)', Icons.inventory),
                    (
                      SortOption.stockDesc,
                      'Stock (High to Low)',
                      Icons.inventory_2,
                    ),
                    (SortOption.newest, 'Newest First', Icons.access_time),
                    (SortOption.oldest, 'Oldest First', Icons.history),
                  ].map((option) {
                    return RadioListTile<SortOption>(
                      value: option.$1,
                      title: Text(option.$2),
                      secondary: Icon(option.$3, size: 20),
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.accent,
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Products',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Status',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _filterStatus == null,
                  selectedColor: AppColors.accentSurface,
                  checkmarkColor: AppColors.accent,
                  onSelected: (selected) {
                    setState(() => _filterStatus = null);
                    Navigator.pop(context);
                  },
                ),
                ...ProductStatus.values.map(
                  (status) => FilterChip(
                    label: Text(status.name.toUpperCase()),
                    selected: _filterStatus == status,
                    selectedColor: AppColors.accentSurface,
                    checkmarkColor: AppColors.accent,
                    onSelected: (selected) {
                      setState(() => _filterStatus = selected ? status : null);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text(
                'Show Low Stock Only',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: const Text(
                'Items with less than 10 units',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              value: _showLowStock,
              // ignore: deprecated_member_use
              activeColor: AppColors.accent,
              onChanged: (value) {
                setState(() => _showLowStock = value);
                Navigator.pop(context);
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkActionsMenu(List<ProductModel> allProducts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bulk Actions (${_selectedProducts.length} selected)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
              ),
              title: const Text(
                'Mark as Active',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _bulkUpdateStatus(ProductStatus.active, allProducts);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined, color: AppColors.warning),
              title: const Text(
                'Mark as Inactive',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _bulkUpdateStatus(ProductStatus.inactive, allProducts);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: AppColors.textSecondary),
              title: const Text(
                'Cancel Selection',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleSelectionMode();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getSortLabel() {
    switch (_sortOption) {
      case SortOption.nameAsc:
        return 'Name (A-Z)';
      case SortOption.nameDesc:
        return 'Name (Z-A)';
      case SortOption.priceAsc:
        return 'Price (Low to High)';
      case SortOption.priceDesc:
        return 'Price (High to Low)';
      case SortOption.stockAsc:
        return 'Stock (Low to High)';
      case SortOption.stockDesc:
        return 'Stock (High to Low)';
      case SortOption.newest:
        return 'Newest First';
      case SortOption.oldest:
        return 'Oldest First';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          );
        }

        final user = authState.user;

        if (user.storeId == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Text(
                'No store associated with this account',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              'Products',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppColors.border),
            ),
            actions: [
              if (_isSelectionMode)
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  tooltip: 'Cancel Selection',
                  onPressed: _toggleSelectionMode,
                )
              else ...[
                IconButton(
                  icon: Icon(
                    _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: _isGridView ? 'List View' : 'Grid View',
                  onPressed: () => setState(() => _isGridView = !_isGridView),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.sort_rounded,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Sort',
                  onPressed: _showSortOptions,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.tune_rounded,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Filter',
                  onPressed: _showFilterOptions,
                ),
              ],
            ],
          ),
          body: StreamBuilder<List<ProductModel>>(
            stream: _firestoreService.getStoreProducts(user.storeId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: AppColors.accent,
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Loading products...',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: AppColors.errorSurface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline_rounded,
                            size: 28,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final allProducts = snapshot.data ?? [];
              final products = _filterProducts(allProducts);
              final lowStockCount = allProducts
                  .where(
                    (p) => p.stockQuantity != null && p.stockQuantity! < 10,
                  )
                  .length;
              final totalValue = allProducts.fold<double>(
                0,
                (sum, p) => sum + (p.sellingPrice * (p.stockQuantity ?? 0)),
              );

              if (allProducts.isEmpty) {
                return Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceElevated,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            size: 40,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No Products Yet',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Start building your inventory\nby adding your first product',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddProductScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text(
                            'Add Your First Product',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                color: AppColors.accent,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Search Bar
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            hintStyle: const TextStyle(
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.textTertiary,
                              size: 22,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      color: AppColors.textTertiary,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 4,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                        ),
                      ),
                    ),

                    // Stats Cards
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildModernStatCard(
                                    icon: Icons.inventory_2_rounded,
                                    label: 'Total',
                                    value: '${allProducts.length}',
                                    accentColor: AppColors.accent,
                                    iconBg: AppColors.accentSurface,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildModernStatCard(
                                    icon: Icons.check_circle_outline_rounded,
                                    label: 'Active',
                                    value:
                                        '${allProducts.where((p) => p.status == ProductStatus.active).length}',
                                    accentColor: AppColors.success,
                                    iconBg: AppColors.successSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildModernStatCard(
                                    icon: Icons.warning_amber_rounded,
                                    label: 'Low Stock',
                                    value: '$lowStockCount',
                                    accentColor: lowStockCount > 0
                                        ? AppColors.warning
                                        : AppColors.textTertiary,
                                    iconBg: lowStockCount > 0
                                        ? AppColors.warningSurface
                                        : AppColors.surfaceElevated,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildModernStatCard(
                                    icon: Icons.currency_rupee_rounded,
                                    label: 'Value',
                                    value: '₹${_formatCompactNumber(totalValue)}',
                                    accentColor: AppColors.success,
                                    iconBg: AppColors.successSurface,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Active Filters Banner
                    if (_filterStatus != null ||
                        _showLowStock ||
                        _sortOption != SortOption.newest)
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.filter_alt_rounded,
                                color: AppColors.accent,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${products.length} of ${allProducts.length} products • ${_getSortLabel()}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _filterStatus = null;
                                    _showLowStock = false;
                                    _sortOption = SortOption.newest;
                                  });
                                },
                                child: const Text(
                                  'Clear',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Selection Mode Banner
                    if (_isSelectionMode)
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${_selectedProducts.length} items selected',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    _showBulkActionsMenu(allProducts),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Actions',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Products Grid/List
                    if (products.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.all(24),
                            padding: const EdgeInsets.all(36),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: const BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.search_off_rounded,
                                    size: 32,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No products found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Try adjusting your filters',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else if (_isGridView)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.75,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            return _buildEnhancedProductGridCard(
                              products[index],
                            );
                          }, childCount: products.length),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            return _buildEnhancedProductCard(products[index]);
                          }, childCount: products.length),
                        ),
                      ),

                    // Bottom Padding
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              );
            },
          ),
          floatingActionButton: _isSelectionMode
              ? null
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      heroTag: 'select',
                      onPressed: _toggleSelectionMode,
                      mini: true,
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.accent,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: const Icon(Icons.checklist_rounded),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton.extended(
                      heroTag: 'add',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddProductScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded, size: 22),
                      label: const Text(
                        'Add Product',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  String _formatCompactNumber(double number) {
    if (number >= 10000000) {
      return '${(number / 10000000).toStringAsFixed(1)}Cr';
    } else if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(1)}L';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }

  Widget _buildModernStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
    required Color iconBg,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accentColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: accentColor, size: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedProductGridCard(ProductModel product) {
    final isSelected = _selectedProducts.contains(product.id);
    final stockQuantity = product.stockQuantity;

    Color stockAccentColor;
    Color stockBadgeBg;
    String stockLabel;

    if (stockQuantity == null) {
      stockAccentColor = AppColors.accent;
      stockBadgeBg = AppColors.accentSurface;
      stockLabel = '∞';
    } else if (stockQuantity > 10) {
      stockAccentColor = AppColors.success;
      stockBadgeBg = AppColors.successSurface;
      stockLabel = stockQuantity.toStringAsFixed(0);
    } else if (stockQuantity >= 5) {
      stockAccentColor = AppColors.warning;
      stockBadgeBg = AppColors.warningSurface;
      stockLabel = stockQuantity.toStringAsFixed(0);
    } else {
      stockAccentColor = AppColors.error;
      stockBadgeBg = AppColors.errorSurface;
      stockLabel = stockQuantity.toStringAsFixed(0);
    }

    final hasDiscount = product.mrp != product.sellingPrice;
    final discountPercent = hasDiscount
        ? (((product.mrp - product.sellingPrice) / product.mrp) * 100)
              .toStringAsFixed(0)
        : '0';

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleProductSelection(product.id);
        } else {
          _showProductActions(context, product);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          _toggleSelectionMode();
          _toggleProductSelection(product.id);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image / Icon Section — muted bg, no gradient
            Stack(
              children: [
                Container(
                  height: 110,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColors.textTertiary,
                      size: 40,
                    ),
                  ),
                ),
                // Discount badge
                if (hasDiscount)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorSurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$discountPercent% OFF',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                // Selection checkbox or Status pill
                Positioned(
                  top: 10,
                  right: 10,
                  child: _isSelectionMode
                      ? AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.textTertiary,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.textTertiary,
                            size: 20,
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: product.status == ProductStatus.active
                                ? AppColors.successSurface
                                : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.status.name.toUpperCase(),
                            style: TextStyle(
                              color: product.status == ProductStatus.active
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                ),
              ],
            ),
            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.brandName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.brandName!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    // Price & Stock Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Price
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasDiscount)
                              Text(
                                '₹${product.mrp.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textTertiary,
                                  decoration: TextDecoration.lineThrough,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            Text(
                              '₹${product.sellingPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        // Stock Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: stockBadgeBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            stockLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: stockAccentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedProductCard(ProductModel product) {
    final isSelected = _selectedProducts.contains(product.id);
    final stockQuantity = product.stockQuantity;

    Color stockAccentColor;
    Color stockBadgeBg;
    String stockStatus;

    if (stockQuantity == null) {
      stockAccentColor = AppColors.accent;
      stockBadgeBg = AppColors.accentSurface;
      stockStatus = 'Unlimited';
    } else if (stockQuantity > 10) {
      stockAccentColor = AppColors.success;
      stockBadgeBg = AppColors.successSurface;
      stockStatus = 'In Stock';
    } else if (stockQuantity >= 5) {
      stockAccentColor = AppColors.warning;
      stockBadgeBg = AppColors.warningSurface;
      stockStatus = 'Low Stock';
    } else {
      stockAccentColor = AppColors.error;
      stockBadgeBg = AppColors.errorSurface;
      stockStatus = 'Critical';
    }

    final hasDiscount = product.mrp != product.sellingPrice;

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleProductSelection(product.id);
        } else {
          _showProductActions(context, product);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          _toggleSelectionMode();
          _toggleProductSelection(product.id);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Product Icon — muted bg, near-black icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: AppColors.textPrimary,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Stock status pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: stockBadgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          stockStatus,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: stockAccentColor,
                          ),
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.errorSurface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${(((product.mrp - product.sellingPrice) / product.mrp) * 100).toStringAsFixed(0)}% OFF',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hasDiscount)
                  Text(
                    '₹${product.mrp.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      decoration: TextDecoration.lineThrough,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                Text(
                  '₹${product.sellingPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductActionsSheet extends StatelessWidget {
  final ProductModel product;
  final FirestoreService firestoreService;
  final VoidCallback onUpdated;

  const _ProductActionsSheet({
    required this.product,
    required this.firestoreService,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: AppColors.accent),
            title: const Text(
              'Edit Product',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            contentPadding: EdgeInsets.zero,
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProductScreen(product: product),
                ),
              );
              onUpdated();
            },
          ),
          ListTile(
            leading: Icon(
              product.status == ProductStatus.active
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.warning,
            ),
            title: Text(
              product.status == ProductStatus.active
                  ? 'Mark as Inactive'
                  : 'Mark as Active',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            contentPadding: EdgeInsets.zero,
            onTap: () async {
              Navigator.pop(context);
              await firestoreService.updateProduct(
                product.copyWith(
                  status: product.status == ProductStatus.active
                      ? ProductStatus.inactive
                      : ProductStatus.active,
                  updatedAt: DateTime.now(),
                ),
              );
              onUpdated();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            title: const Text(
              'Delete Product',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            contentPadding: EdgeInsets.zero,
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Delete Product',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  content: Text(
                    'Delete "${product.name}"?',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await firestoreService.deleteProduct(product.id);
                        onUpdated();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
