import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import 'sales_history_screen.dart';
import 'analytics_screen.dart';

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

class StoreAdminHomeScreen extends StatefulWidget {
  const StoreAdminHomeScreen({super.key});

  @override
  State<StoreAdminHomeScreen> createState() => _StoreAdminHomeScreenState();
}

class _StoreAdminHomeScreenState extends State<StoreAdminHomeScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  ProductStatus? _filterStatus;
  bool _showLowStock = false;
  SortOption _sortOption = SortOption.newest;
  bool _isGridView = false;
  Set<String> _selectedProducts = {};
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
        return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.sku.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (p.brandName?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                false) ||
            p.barcode.contains(_searchQuery);
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

    // Apply sorting
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
            backgroundColor: const Color(0xFF10B981),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort Products',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
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
                  groupValue: _sortOption,
                  title: Text(option.$2),
                  secondary: Icon(option.$3, size: 20),
                  onChanged: (value) {
                    setState(() => _sortOption = value!);
                    Navigator.pop(context);
                  },
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
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
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _filterStatus == null,
                  onSelected: (selected) {
                    setState(() => _filterStatus = null);
                    Navigator.pop(context);
                  },
                ),
                ...ProductStatus.values.map(
                  (status) => FilterChip(
                    label: Text(status.name.toUpperCase()),
                    selected: _filterStatus == status,
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
              title: const Text('Show Low Stock Only'),
              subtitle: const Text('Items with less than 10 units'),
              value: _showLowStock,
              onChanged: (value) {
                setState(() => _showLowStock = value);
                Navigator.pop(context);
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showBulkActionsMenu(List<ProductModel> allProducts) {
    showModalBottomSheet(
      context: context,
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Color(0xFF10B981)),
              title: const Text('Mark as Active'),
              onTap: () {
                Navigator.pop(context);
                _bulkUpdateStatus(ProductStatus.active, allProducts);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Color(0xFFF59E0B)),
              title: const Text('Mark as Inactive'),
              onTap: () {
                Navigator.pop(context);
                _bulkUpdateStatus(ProductStatus.inactive, allProducts);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: Color(0xFF64748B)),
              title: const Text('Cancel Selection'),
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

  void _resetFiltersAndScrollToTop() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _filterStatus = null;
      _showLowStock = false;
      _sortOption = SortOption.newest;
      _isSelectionMode = false;
      _selectedProducts.clear();
      _fabAnimationController.reverse();
    });

    // Scroll to top with animation
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authState.user;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Store Dashboard'),
            elevation: 0,
            actions: [
              if (_isSelectionMode)
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Cancel Selection',
                  onPressed: _toggleSelectionMode,
                )
              else ...[
                IconButton(
                  icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                  tooltip: _isGridView ? 'List View' : 'Grid View',
                  onPressed: () => setState(() => _isGridView = !_isGridView),
                ),
                IconButton(
                  icon: const Icon(Icons.sort),
                  tooltip: 'Sort',
                  onPressed: _showSortOptions,
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Filter',
                  onPressed: _showFilterOptions,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Add Product',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddProductScreen(),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(user.displayName),
                  accountEmail: Text(user.email),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: user.photoURL != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: user.photoURL!,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const CircularProgressIndicator(),
                              errorWidget: (context, url, error) => Text(
                                user.displayName[0].toUpperCase(),
                                style: const TextStyle(fontSize: 40),
                              ),
                            ),
                          )
                        : Text(
                            user.displayName[0].toUpperCase(),
                            style: const TextStyle(fontSize: 40),
                          ),
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                  ),
                  otherAccountsPictures: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.store,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Dashboard'),
                  selected: true,
                  onTap: () {
                    Navigator.pop(context);
                    _resetFiltersAndScrollToTop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.inventory),
                  title: const Text('Products'),
                  onTap: () {
                    Navigator.pop(context);
                    _resetFiltersAndScrollToTop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: const Text('Sales History'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SalesHistoryScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.analytics),
                  title: const Text('Analytics'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AnalyticsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.store_outlined),
                  title: const Text('Store Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Store Settings - Coming Soon'),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign Out'),
                  onTap: () {
                    context.read<AuthBloc>().add(AuthSignOutRequested());
                  },
                ),
              ],
            ),
          ),
          body: user.storeId == null
              ? const Center(
                  child: Text('No store associated with this account'),
                )
              : StreamBuilder<List<ProductModel>>(
                  stream: _firestoreService.getStoreProducts(user.storeId!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final allProducts = snapshot.data ?? [];
                    final products = _filterProducts(allProducts);
                    final lowStockCount = allProducts
                        .where(
                          (p) =>
                              p.stockQuantity != null && p.stockQuantity! < 10,
                        )
                        .length;
                    final totalValue = allProducts.fold<double>(
                      0,
                      (sum, p) =>
                          sum + (p.sellingPrice * (p.stockQuantity ?? 0)),
                    );

                    if (allProducts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 120,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'No Products Yet',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'Start adding products to your store inventory',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AddProductScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Your First Product'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        // Trigger rebuild by calling setState
                        setState(() {});
                      },
                      child: Column(
                        children: [
                          // Search Bar
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: Colors.white,
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search by name, SKU, barcode...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FA),
                              ),
                              onChanged: (value) {
                                setState(() => _searchQuery = value);
                              },
                            ),
                          ),

                          // Enhanced Stats Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            color: const Color(0xFFF8F9FA),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        icon: Icons.inventory_2,
                                        label: 'Total Products',
                                        value: '${allProducts.length}',
                                        color: const Color(0xFF10B981),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        icon: Icons.check_circle,
                                        label: 'Active',
                                        value:
                                            '${allProducts.where((p) => p.status == ProductStatus.active).length}',
                                        color: const Color(0xFF3B82F6),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        icon: Icons.warning_amber,
                                        label: 'Low Stock',
                                        value: '$lowStockCount',
                                        color: lowStockCount > 0
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF10B981),
                                        Color(0xFF059669),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF10B981,
                                        ).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Total Inventory Value',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            '💰 Estimated Stock Worth',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '₹${totalValue.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Active Filters & Sort Indicator
                          if (_filterStatus != null ||
                              _showLowStock ||
                              _sortOption != SortOption.newest)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              color: const Color(0xFFFEF3C7),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Showing ${products.length} of ${allProducts.length} products • Sorted by ${_getSortLabel()}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _filterStatus = null;
                                        _showLowStock = false;
                                        _sortOption = SortOption.newest;
                                      });
                                    },
                                    child: const Text(
                                      'Reset',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Selection Mode Banner
                          if (_isSelectionMode)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              color: const Color(0xFFDCFCE7),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF059669),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '${_selectedProducts.length} items selected',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF059669),
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        _showBulkActionsMenu(allProducts),
                                    child: const Text('Actions'),
                                  ),
                                ],
                              ),
                            ),

                          // Product List/Grid
                          Expanded(
                            child: products.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.search_off,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No products found',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : _isGridView
                                ? GridView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.all(16),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                          childAspectRatio: 0.75,
                                        ),
                                    itemCount: products.length,
                                    itemBuilder: (context, index) {
                                      final product = products[index];
                                      return _buildProductGridCard(product);
                                    },
                                  )
                                : ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.all(16),
                                    itemCount: products.length,
                                    itemBuilder: (context, index) {
                                      final product = products[index];
                                      return _buildProductCard(product);
                                    },
                                  ),
                          ),
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
                      child: const Icon(Icons.checklist),
                      tooltip: 'Bulk Actions',
                      mini: true,
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton(
                      heroTag: 'add',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddProductScreen(),
                          ),
                        );
                      },
                      child: const Icon(Icons.add),
                      tooltip: 'Add Product',
                    ),
                  ],
                ),
        );
      },
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

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductGridCard(ProductModel product) {
    final isSelected = _selectedProducts.contains(product.id);
    final stockQuantity = product.stockQuantity;

    // Stock level colors and metadata
    Color gradientStart;
    Color gradientEnd;
    Color stockBadgeColor;
    IconData stockIcon;

    if (stockQuantity == null) {
      gradientStart = const Color(0xFF6366F1);
      gradientEnd = const Color(0xFF8B5CF6);
      stockBadgeColor = const Color(0xFF6366F1);
      stockIcon = Icons.all_inclusive;
    } else if (stockQuantity > 10) {
      gradientStart = const Color(0xFF10B981);
      gradientEnd = const Color(0xFF059669);
      stockBadgeColor = const Color(0xFF10B981);
      stockIcon = Icons.check_circle_outline;
    } else if (stockQuantity >= 5) {
      gradientStart = const Color(0xFFF59E0B);
      gradientEnd = const Color(0xFFD97706);
      stockBadgeColor = const Color(0xFFF59E0B);
      stockIcon = Icons.warning_amber_rounded;
    } else {
      gradientStart = const Color(0xFFEF4444);
      gradientEnd = const Color(0xFFDC2626);
      stockBadgeColor = const Color(0xFFEF4444);
      stockIcon = Icons.error_outline_rounded;
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? gradientStart : Colors.grey.shade200,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? gradientStart : Colors.grey.shade400)
                  .withOpacity(isSelected ? 0.3 : 0.15),
              blurRadius: isSelected ? 16 : 8,
              offset: Offset(0, isSelected ? 6 : 3),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section with Gradient & Badges (Reduced Height)
            Stack(
              children: [
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [gradientStart, gradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.inventory_2_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                // Discount Badge (Changed to Orange/Amber)
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B35).withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_offer,
                            color: Colors.white,
                            size: 10,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$discountPercent%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Selection Indicator
                if (_isSelectionMode)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected
                            ? gradientStart
                            : Colors.grey.shade400,
                        size: 20,
                      ),
                    ),
                  ),
                // Status Badge
                if (!_isSelectionMode)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: product.status == ProductStatus.active
                            ? const Color(0xFF10B981)
                            : const Color(0xFF64748B),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            product.status.name.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            // Product Info Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Brand Name or SKU
                    if (product.brandName != null)
                      Text(
                        product.brandName!,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Row(
                        children: [
                          Icon(
                            Icons.qr_code_2_rounded,
                            size: 10,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              product.sku,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    // Divider
                    Container(
                      height: 1,
                      margin: const EdgeInsets.only(top: 6, bottom: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.grey.shade300,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    // Price & Stock Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Price Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasDiscount) ...[
                                Text(
                                  '₹${product.mrp.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey.shade400,
                                    decoration: TextDecoration.lineThrough,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 1),
                              ],
                              Text(
                                '₹${product.sellingPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF10B981),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Stock Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: stockBadgeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: stockBadgeColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(stockIcon, size: 12, color: stockBadgeColor),
                              const SizedBox(height: 1),
                              Text(
                                stockQuantity != null
                                    ? stockQuantity.toStringAsFixed(0)
                                    : '∞',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: stockBadgeColor,
                                ),
                              ),
                            ],
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

  Widget _buildProductCard(ProductModel product) {
    final isSelected = _selectedProducts.contains(product.id);
    final stockQuantity = product.stockQuantity;

    // Stock level gradient colors and metadata
    Color gradientStart;
    Color gradientEnd;
    Color stockTextColor;
    IconData stockIcon;
    String stockStatus;

    if (stockQuantity == null) {
      // Unlimited stock - Purple gradient
      gradientStart = const Color(0xFF6366F1);
      gradientEnd = const Color(0xFF8B5CF6);
      stockTextColor = const Color(0xFF6366F1);
      stockIcon = Icons.all_inclusive;
      stockStatus = 'Unlimited';
    } else if (stockQuantity > 10) {
      // Good stock - Green gradient
      gradientStart = const Color(0xFF10B981);
      gradientEnd = const Color(0xFF059669);
      stockTextColor = const Color(0xFF059669);
      stockIcon = Icons.inventory;
      stockStatus = 'In Stock';
    } else if (stockQuantity >= 5) {
      // Medium stock - Orange gradient
      gradientStart = const Color(0xFFF59E0B);
      gradientEnd = const Color(0xFFD97706);
      stockTextColor = const Color(0xFFD97706);
      stockIcon = Icons.warning_amber;
      stockStatus = 'Low Stock';
    } else {
      // Critical stock - Red gradient
      gradientStart = const Color(0xFFEF4444);
      gradientEnd = const Color(0xFFDC2626);
      stockTextColor = const Color(0xFFDC2626);
      stockIcon = Icons.error_outline;
      stockStatus = 'Critical';
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? gradientStart
                : (stockQuantity != null && stockQuantity < 5
                      ? gradientStart.withOpacity(0.4)
                      : const Color(0xFFE2E8F0)),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? gradientStart : gradientStart).withOpacity(
                0.08,
              ),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Section - Main Info
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selection checkbox or Product Icon
                  if (_isSelectionMode)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isSelected ? gradientStart : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                    )
                  else
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [gradientStart, gradientEnd],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: gradientStart.withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  const SizedBox(width: 16),
                  // Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (product.brandName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            product.brandName!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        // SKU
                        Row(
                          children: [
                            Icon(
                              Icons.qr_code_2_rounded,
                              size: 14,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.sku,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Price Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${product.sellingPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF10B981),
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(height: 2),
                        Text(
                          '₹${product.mrp.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                            decoration: TextDecoration.lineThrough,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6B35).withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '$discountPercent% OFF',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Divider
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    gradientStart.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Bottom Section - Stock & Status
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Stock Status with Gradient Background
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            gradientStart.withOpacity(0.12),
                            gradientEnd.withOpacity(0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: gradientStart.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(stockIcon, size: 18, color: stockTextColor),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stockStatus,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: stockTextColor.withOpacity(0.8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                stockQuantity != null
                                    ? '${stockQuantity.toStringAsFixed(0)} ${product.baseUnit.name}'
                                    : '∞',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: stockTextColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Product Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: product.status == ProductStatus.active
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: product.status == ProductStatus.active
                            ? const Color(0xFF10B981).withOpacity(0.2)
                            : const Color(0xFFEF4444).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: product.status == ProductStatus.active
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (product.status == ProductStatus.active
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEF4444))
                                        .withOpacity(0.4),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          product.status.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: product.status == ProductStatus.active
                                ? const Color(0xFF047857)
                                : const Color(0xFFB91C1C),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Chevron Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: gradientStart.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: gradientStart,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Product Actions Bottom Sheet
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'SKU: ${product.sku}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _ActionButton(
            icon: Icons.edit,
            label: 'Edit Product',
            color: const Color(0xFF3B82F6),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProductScreen(product: product),
                ),
              );
              if (result == true) {
                onUpdated();
              }
            },
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: product.status == ProductStatus.active
                ? Icons.visibility_off
                : Icons.visibility,
            label: product.status == ProductStatus.active
                ? 'Mark as Inactive'
                : 'Mark as Active',
            color: const Color(0xFFF59E0B),
            onTap: () async {
              Navigator.pop(context);
              try {
                await firestoreService.updateProduct(
                  product.copyWith(
                    status: product.status == ProductStatus.active
                        ? ProductStatus.inactive
                        : ProductStatus.active,
                    updatedAt: DateTime.now(),
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product status updated'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
                onUpdated();
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.delete_outline,
            label: 'Delete Product',
            color: const Color(0xFFEF4444),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await firestoreService.deleteProduct(product.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product deleted successfully'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
                onUpdated();
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
