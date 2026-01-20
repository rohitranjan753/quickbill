import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../models/receipt_model.dart';
import '../services/firestore_service.dart';
import 'receipt_screen.dart';

enum SalesFilter { all, today, yesterday, thisWeek, thisMonth, custom }

enum PaymentFilter { all, cash, card, upi, other }

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  SalesFilter _dateFilter = SalesFilter.all;
  PaymentFilter _paymentFilter = PaymentFilter.all;
  bool _verifiedOnly = false;
  String _searchQuery = '';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ReceiptModel> _filterReceipts(List<ReceiptModel> receipts) {
    var filtered = receipts;

    // Apply date filter
    final now = DateTime.now();
    switch (_dateFilter) {
      case SalesFilter.today:
        final todayStart = DateTime(now.year, now.month, now.day);
        filtered = filtered
            .where((r) => r.purchaseDate.isAfter(todayStart))
            .toList();
        break;
      case SalesFilter.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        final yesterdayStart = DateTime(yesterday.year, yesterday.month, yesterday.day);
        final yesterdayEnd = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        filtered = filtered
            .where((r) =>
                r.purchaseDate.isAfter(yesterdayStart) &&
                r.purchaseDate.isBefore(yesterdayEnd))
            .toList();
        break;
      case SalesFilter.thisWeek:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
        filtered = filtered
            .where((r) => r.purchaseDate.isAfter(weekStartDate))
            .toList();
        break;
      case SalesFilter.thisMonth:
        final monthStart = DateTime(now.year, now.month, 1);
        filtered = filtered
            .where((r) => r.purchaseDate.isAfter(monthStart))
            .toList();
        break;
      case SalesFilter.custom:
        if (_customStartDate != null && _customEndDate != null) {
          filtered = filtered
              .where((r) =>
                  r.purchaseDate.isAfter(_customStartDate!) &&
                  r.purchaseDate.isBefore(_customEndDate!))
              .toList();
        }
        break;
      case SalesFilter.all:
        break;
    }

    // Apply payment filter
    if (_paymentFilter != PaymentFilter.all) {
      filtered = filtered
          .where((r) => r.paymentMethod.toLowerCase() == _paymentFilter.name)
          .toList();
    }

    // Apply verified filter
    if (_verifiedOnly) {
      filtered = filtered.where((r) => r.verified).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((r) {
        final query = _searchQuery.toLowerCase();
        return r.id.toLowerCase().contains(query) ||
            r.totalAmount.toString().contains(query) ||
            r.items.any((item) => item.product.name.toLowerCase().contains(query));
      }).toList();
    }

    return filtered;
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Sales',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Date Filter
              const Text(
                'Date Range',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SalesFilter.values.map((filter) {
                  return FilterChip(
                    label: Text(_getFilterLabel(filter)),
                    selected: _dateFilter == filter,
                    onSelected: (selected) {
                      setState(() {
                        _dateFilter = filter;
                        if (filter == SalesFilter.custom) {
                          _showDateRangePicker();
                        }
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Payment Method Filter
              const Text(
                'Payment Method',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PaymentFilter.values.map((filter) {
                  return FilterChip(
                    label: Text(filter.name.toUpperCase()),
                    selected: _paymentFilter == filter,
                    onSelected: (selected) {
                      setState(() {
                        _paymentFilter = selected ? filter : PaymentFilter.all;
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Verified Filter
              SwitchListTile(
                title: const Text('Verified Sales Only'),
                subtitle: const Text('Show only verified transactions'),
                value: _verifiedOnly,
                onChanged: (value) {
                  setState(() => _verifiedOnly = value);
                  Navigator.pop(context);
                },
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 24),

              // Reset Filters
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _dateFilter = SalesFilter.all;
                    _paymentFilter = PaymentFilter.all;
                    _verifiedOnly = false;
                    _customStartDate = null;
                    _customEndDate = null;
                  });
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reset All Filters'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFilterLabel(SalesFilter filter) {
    switch (filter) {
      case SalesFilter.all:
        return 'All Time';
      case SalesFilter.today:
        return 'Today';
      case SalesFilter.yesterday:
        return 'Yesterday';
      case SalesFilter.thisWeek:
        return 'This Week';
      case SalesFilter.thisMonth:
        return 'This Month';
      case SalesFilter.custom:
        return 'Custom Range';
    }
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
    }
  }

  Map<String, dynamic> _calculateStats(List<ReceiptModel> receipts) {
    if (receipts.isEmpty) {
      return {
        'totalSales': 0.0,
        'totalTransactions': 0,
        'averageTransaction': 0.0,
        'totalItems': 0,
        'verifiedCount': 0,
        'cashSales': 0.0,
        'cardSales': 0.0,
        'upiSales': 0.0,
      };
    }

    final totalSales = receipts.fold<double>(0, (sum, r) => sum + r.totalAmount);
    final totalTransactions = receipts.length;
    final averageTransaction = totalSales / totalTransactions;
    final totalItems = receipts.fold<int>(0, (sum, r) => sum + r.items.length);
    final verifiedCount = receipts.where((r) => r.verified).length;

    final cashSales = receipts
        .where((r) => r.paymentMethod.toLowerCase() == 'cash')
        .fold<double>(0, (sum, r) => sum + r.totalAmount);
    final cardSales = receipts
        .where((r) => r.paymentMethod.toLowerCase() == 'card')
        .fold<double>(0, (sum, r) => sum + r.totalAmount);
    final upiSales = receipts
        .where((r) => r.paymentMethod.toLowerCase() == 'upi')
        .fold<double>(0, (sum, r) => sum + r.totalAmount);

    return {
      'totalSales': totalSales,
      'totalTransactions': totalTransactions,
      'averageTransaction': averageTransaction,
      'totalItems': totalItems,
      'verifiedCount': verifiedCount,
      'cashSales': cashSales,
      'cardSales': cardSales,
      'upiSales': upiSales,
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: Text('Not authenticated')),
          );
        }

        final user = authState.user;
        if (user.storeId == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Sales History')),
            body: const Center(
              child: Text('No store associated with this account'),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            title: const Text('Sales History'),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filters',
                onPressed: _showFilterDialog,
              ),
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Export',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export feature - Coming Soon')),
                  );
                },
              ),
            ],
          ),
          body: StreamBuilder<List<ReceiptModel>>(
            stream: _firestoreService.getStoreSales(user.storeId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              final allReceipts = snapshot.data ?? [];
              final filteredReceipts = _filterReceipts(allReceipts);
              final stats = _calculateStats(filteredReceipts);

              if (allReceipts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 120,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Sales Yet',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sales transactions will appear here',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // Search Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by product, amount, receipt ID...',
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

                  // Stats Cards
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.currency_rupee,
                                label: 'Total Sales',
                                value: '₹${stats['totalSales'].toStringAsFixed(2)}',
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.receipt_long,
                                label: 'Transactions',
                                value: '${stats['totalTransactions']}',
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.trending_up,
                                label: 'Avg Transaction',
                                value: '₹${stats['averageTransaction'].toStringAsFixed(2)}',
                                color: const Color(0xFF8B5CF6),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.shopping_bag,
                                label: 'Items Sold',
                                value: '${stats['totalItems']}',
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Payment Breakdown
                  if (filteredReceipts.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Method Breakdown',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildPaymentRow('Cash', stats['cashSales'], Icons.money),
                          _buildPaymentRow('Card', stats['cardSales'], Icons.credit_card),
                          _buildPaymentRow('UPI', stats['upiSales'], Icons.qr_code_scanner),
                        ],
                      ),
                    ),

                  // Active Filters Indicator
                  if (_dateFilter != SalesFilter.all ||
                      _paymentFilter != PaymentFilter.all ||
                      _verifiedOnly)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: const Color(0xFFFEF3C7),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.filter_list,
                            size: 16,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Filters active: ${filteredReceipts.length} of ${allReceipts.length} sales',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _dateFilter = SalesFilter.all;
                                _paymentFilter = PaymentFilter.all;
                                _verifiedOnly = false;
                              });
                            },
                            child: const Text('Clear', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ),

                  // Sales List
                  Expanded(
                    child: filteredReceipts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No sales found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your filters',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredReceipts.length,
                            itemBuilder: (context, index) {
                              final receipt = filteredReceipts[index];
                              return _buildReceiptCard(receipt);
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String method, double amount, IconData icon) {
    if (amount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF64748B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              method,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(ReceiptModel receipt) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    
    Color paymentColor;
    IconData paymentIcon;
    switch (receipt.paymentMethod.toLowerCase()) {
      case 'cash':
        paymentColor = const Color(0xFF10B981);
        paymentIcon = Icons.money;
        break;
      case 'card':
        paymentColor = const Color(0xFF3B82F6);
        paymentIcon = Icons.credit_card;
        break;
      case 'upi':
        paymentColor = const Color(0xFF8B5CF6);
        paymentIcon = Icons.qr_code_scanner;
        break;
      default:
        paymentColor = const Color(0xFF64748B);
        paymentIcon = Icons.payment;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReceiptScreen(receiptId: receipt.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: receipt.verified
                ? const Color(0xFF10B981).withOpacity(0.3)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        paymentColor.withOpacity(0.2),
                        paymentColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(paymentIcon, color: paymentColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${receipt.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateFormat.format(receipt.purchaseDate),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (receipt.verified)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified,
                          size: 14,
                          color: Color(0xFF10B981),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'VERIFIED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF047857),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.grey[200],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  Icons.shopping_bag,
                  '${receipt.items.length} items',
                  const Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  paymentIcon,
                  receipt.paymentMethod.toUpperCase(),
                  paymentColor,
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
