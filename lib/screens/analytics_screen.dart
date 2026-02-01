import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../models/receipt_model.dart';
import '../services/firestore_service.dart';
import '../services/export_service.dart';
import '../services/pdf_service.dart';

enum AnalyticsPeriod { today, week, month, year, custom }
enum ChartType { revenue, transactions, products, categories }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ExportService _exportService = ExportService();
  final PdfService _pdfService = PdfService();

  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.month;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _showComparison = false;
  ChartType _selectedChartType = ChartType.revenue;
  String? _selectedCategory;
  int _touchedIndex = -1;
  int _touchedBarIndex = -1;

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
            appBar: AppBar(title: const Text('Analytics')),
            body: const Center(
              child: Text('No store associated with this account'),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            title: const Text('Analytics Dashboard'),
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  _showComparison ? Icons.compare_arrows : Icons.insights,
                  color: _showComparison ? const Color(0xFF10B981) : null,
                ),
                tooltip: 'Toggle Comparison',
                onPressed: () =>
                    setState(() => _showComparison = !_showComparison),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: () => setState(() {}),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.download),
                tooltip: 'Export Data',
                onSelected: (value) => _handleExport(value, user.storeId!),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'excel',
                    child: Row(
                      children: [
                        Icon(Icons.table_chart, color: Color(0xFF10B981)),
                        SizedBox(width: 12),
                        Text('Export to Excel'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444)),
                        SizedBox(width: 12),
                        Text('Export to PDF'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'print',
                    child: Row(
                      children: [
                        Icon(Icons.print, color: Color(0xFF3B82F6)),
                        SizedBox(width: 12),
                        Text('Print Report'),
                      ],
                    ),
                  ),
                ],
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
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => setState(() {}),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final allReceipts = snapshot.data ?? [];
              final filteredReceipts = _filterReceiptsByPeriod(allReceipts);
              final analytics = _calculateAnalytics(filteredReceipts);
              final previousAnalytics = _showComparison
                  ? _calculateAnalytics(
                      _getPreviousPeriodReceipts(
                        allReceipts,
                        _getPeriodDuration(),
                      ),
                    )
                  : null;

              if (allReceipts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 120,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Data Yet',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Analytics will appear once you have sales',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period Selector
                    _buildPeriodSelector(),
                    const SizedBox(height: 24),

                    // Key Metrics Cards
                    _buildKeyMetrics(analytics, previousAnalytics),
                    const SizedBox(height: 24),

                    // Quick Actions
                    _buildQuickActions(filteredReceipts),
                    const SizedBox(height: 24),

                    // Interactive Chart Selector
                    _buildChartTypeSelector(),
                    const SizedBox(height: 16),

                    // Main Chart (Dynamic based on selection)
                    _buildMainChart(filteredReceipts, analytics),
                    const SizedBox(height: 24),

                    // Category Filter & Analysis
                    _buildCategoryAnalysis(analytics),
                    const SizedBox(height: 24),

                    // Two Column Layout for Charts
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildPaymentMethodsChart(analytics)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildHourlySalesPattern(filteredReceipts),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Top Products with interactive features
                    _buildTopProducts(analytics),
                    const SizedBox(height: 24),

                    // Sales by Day Chart
                    _buildSalesByDayChart(filteredReceipts),
                    const SizedBox(height: 24),

                    // Profit Margin Analysis
                    _buildProfitMarginAnalysis(analytics),
                    const SizedBox(height: 24),

                    // Customer Behavior Insights
                    _buildCustomerBehaviorInsights(analytics, filteredReceipts),
                    const SizedBox(height: 24),

                    // Additional Insights
                    _buildAdditionalInsights(analytics),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<ReceiptModel> _filterReceiptsByPeriod(List<ReceiptModel> receipts) {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case AnalyticsPeriod.today:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case AnalyticsPeriod.week:
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case AnalyticsPeriod.month:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case AnalyticsPeriod.year:
        startDate = DateTime(now.year, 1, 1);
        break;
      case AnalyticsPeriod.custom:
        if (_customStartDate == null || _customEndDate == null) {
          return receipts;
        }
        return receipts
            .where((r) =>
                r.purchaseDate.isAfter(_customStartDate!) &&
                r.purchaseDate.isBefore(_customEndDate!))
            .toList();
    }

    return receipts.where((r) => r.purchaseDate.isAfter(startDate)).toList();
  }

  Map<String, dynamic> _calculateAnalytics(List<ReceiptModel> receipts) {
    if (receipts.isEmpty) {
      return {
        'totalRevenue': 0.0,
        'totalTransactions': 0,
        'averageOrderValue': 0.0,
        'totalItems': 0,
        'paymentMethods': <String, double>{},
        'topProducts': <Map<String, dynamic>>[],
        'revenueGrowth': 0.0,
        'transactionsGrowth': 0.0,
        'categories': <String, Map<String, dynamic>>{},
        'hourlyData': <int, Map<String, dynamic>>{},
        'uniqueCustomers': 0,
        'repeatCustomers': 0,
        'profitMargin': 0.0,
        'totalProfit': 0.0,
        'taxCollected': 0.0,
      };
    }

    // Basic metrics
    final totalRevenue = receipts.fold<double>(0, (sum, r) => sum + r.totalAmount);
    final totalTransactions = receipts.length;
    final averageOrderValue = totalRevenue / totalTransactions;
    final totalItems = receipts.fold<int>(0, (sum, r) => sum + r.items.length);

    // Payment methods breakdown
    final paymentMethods = <String, double>{};
    for (var receipt in receipts) {
      final method = receipt.paymentMethod.toLowerCase();
      paymentMethods[method] = (paymentMethods[method] ?? 0) + receipt.totalAmount;
    }

    // Category analysis
    final categories = <String, Map<String, dynamic>>{};
    for (var receipt in receipts) {
      for (var item in receipt.items) {
        final category = item.product.category;
        if (!categories.containsKey(category)) {
          categories[category] = {
            'revenue': 0.0,
            'quantity': 0,
            'transactions': 0,
          };
        }
        categories[category]!['revenue'] += item.totalPrice;
        categories[category]!['quantity'] += item.quantity;
        categories[category]!['transactions'] += 1;
      }
    }

    // Hourly sales pattern
    final hourlyData = <int, Map<String, dynamic>>{};
    for (var i = 0; i < 24; i++) {
      hourlyData[i] = {'revenue': 0.0, 'transactions': 0};
    }
    for (var receipt in receipts) {
      final hour = receipt.purchaseDate.hour;
      hourlyData[hour]!['revenue'] += receipt.totalAmount;
      hourlyData[hour]!['transactions'] += 1;
    }

    // Customer analysis
    final customerIds = receipts.map((r) => r.userId).toSet();
    final uniqueCustomers = customerIds.length;
    final customerPurchases = <String, int>{};
    for (var receipt in receipts) {
      customerPurchases[receipt.userId] =
          (customerPurchases[receipt.userId] ?? 0) + 1;
    }
    final repeatCustomers = customerPurchases.values
        .where((count) => count > 1)
        .length;

    // Profit and tax calculations
    var totalProfit = 0.0;
    var taxCollected = 0.0;
    for (var receipt in receipts) {
      for (var item in receipt.items) {
        final profit =
            (item.product.sellingPrice - (item.product.mrp * 0.7)) *
            item.quantity;
        totalProfit += profit;
        taxCollected += item.product.taxAmount * item.quantity;
      }
    }
    final profitMargin = totalRevenue > 0
        ? (totalProfit / totalRevenue) * 100
        : 0.0;

    // Top products
    final productSales = <String, Map<String, dynamic>>{};
    for (var receipt in receipts) {
      for (var item in receipt.items) {
        final productName = item.product.name;
        if (productSales.containsKey(productName)) {
          productSales[productName]!['quantity'] += item.quantity;
          productSales[productName]!['revenue'] += item.totalPrice;
          productSales[productName]!['transactions'] += 1;
        } else {
          productSales[productName] = {
            'name': productName,
            'quantity': item.quantity,
            'revenue': item.totalPrice,
            'price': item.product.sellingPrice,
            'category': item.product.category,
            'transactions': 1,
          };
        }
      }
    }

    final topProducts = productSales.values.toList()
      ..sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

    // Growth calculations
    final periodDuration = _getPeriodDuration();
    final previousPeriodReceipts = _getPreviousPeriodReceipts(receipts, periodDuration);
    final previousRevenue = previousPeriodReceipts.fold<double>(0, (sum, r) => sum + r.totalAmount);
    final revenueGrowth = previousRevenue > 0
        ? ((totalRevenue - previousRevenue) / previousRevenue) * 100
        : 0.0;
    final transactionsGrowth = previousPeriodReceipts.isNotEmpty
        ? ((totalTransactions - previousPeriodReceipts.length) / previousPeriodReceipts.length) * 100
        : 0.0;

    return {
      'totalRevenue': totalRevenue,
      'totalTransactions': totalTransactions,
      'averageOrderValue': averageOrderValue,
      'totalItems': totalItems,
      'paymentMethods': paymentMethods,
      'topProducts': topProducts.take(10).toList(),
      'revenueGrowth': revenueGrowth,
      'transactionsGrowth': transactionsGrowth,
      'categories': categories,
      'hourlyData': hourlyData,
      'uniqueCustomers': uniqueCustomers,
      'repeatCustomers': repeatCustomers,
      'profitMargin': profitMargin,
      'totalProfit': totalProfit,
      'taxCollected': taxCollected,
    };
  }

  Duration _getPeriodDuration() {
    switch (_selectedPeriod) {
      case AnalyticsPeriod.today:
        return const Duration(days: 1);
      case AnalyticsPeriod.week:
        return const Duration(days: 7);
      case AnalyticsPeriod.month:
        return const Duration(days: 30);
      case AnalyticsPeriod.year:
        return const Duration(days: 365);
      case AnalyticsPeriod.custom:
        if (_customStartDate != null && _customEndDate != null) {
          return _customEndDate!.difference(_customStartDate!);
        }
        return const Duration(days: 30);
    }
  }

  List<ReceiptModel> _getPreviousPeriodReceipts(
    List<ReceiptModel> allReceipts,
    Duration duration,
  ) {
    final now = DateTime.now();
    final periodStart = now.subtract(duration);
    final previousPeriodEnd = periodStart;
    final previousPeriodStart = periodStart.subtract(duration);

    return allReceipts
        .where((r) =>
            r.purchaseDate.isAfter(previousPeriodStart) &&
            r.purchaseDate.isBefore(previousPeriodEnd))
        .toList();
  }

  Widget _buildPeriodSelector() {
    return Container(
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
            'Time Period',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPeriodChip('Today', AnalyticsPeriod.today),
              _buildPeriodChip('This Week', AnalyticsPeriod.week),
              _buildPeriodChip('This Month', AnalyticsPeriod.month),
              _buildPeriodChip('This Year', AnalyticsPeriod.year),
              _buildPeriodChip('Custom', AnalyticsPeriod.custom),
            ],
          ),
          if (_selectedPeriod == AnalyticsPeriod.custom &&
              _customStartDate != null &&
              _customEndDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '${DateFormat('MMM dd, yyyy').format(_customStartDate!)} - ${DateFormat('MMM dd, yyyy').format(_customEndDate!)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, AnalyticsPeriod period) {
    final isSelected = _selectedPeriod == period;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) async {
        if (period == AnalyticsPeriod.custom) {
          final DateTimeRange? picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            setState(() {
              _selectedPeriod = period;
              _customStartDate = picked.start;
              _customEndDate = picked.end;
            });
          }
        } else {
          setState(() => _selectedPeriod = period);
        }
      },
      selectedColor: const Color(0xFF10B981).withOpacity(0.2),
      checkmarkColor: const Color(0xFF10B981),
    );
  }

  Widget _buildKeyMetrics(
    Map<String, dynamic> analytics,
    Map<String, dynamic>? previousAnalytics,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.currency_rupee,
                label: 'Total Revenue',
                value: '₹${analytics['totalRevenue'].toStringAsFixed(2)}',
                growth: analytics['revenueGrowth'],
                color: const Color(0xFF10B981),
                previousValue: previousAnalytics != null
                    ? '₹${previousAnalytics['totalRevenue'].toStringAsFixed(2)}'
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.receipt_long,
                label: 'Transactions',
                value: '${analytics['totalTransactions']}',
                growth: analytics['transactionsGrowth'],
                color: const Color(0xFF3B82F6),
                previousValue: previousAnalytics != null
                    ? '${previousAnalytics['totalTransactions']}'
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.trending_up,
                label: 'Avg Order Value',
                value: '₹${analytics['averageOrderValue'].toStringAsFixed(2)}',
                growth: null,
                color: const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.shopping_bag,
                label: 'Items Sold',
                value: '${analytics['totalItems']}',
                growth: null,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.people,
                label: 'Unique Customers',
                value: '${analytics['uniqueCustomers']}',
                growth: null,
                color: const Color(0xFFEC4899),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.account_balance_wallet,
                label: 'Profit Margin',
                value: '${analytics['profitMargin'].toStringAsFixed(1)}%',
                growth: null,
                color: const Color(0xFF06B6D4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    double? growth,
    String? previousValue,
  }) {
    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              if (growth != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: growth >= 0
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        growth >= 0 ? Icons.trending_up : Icons.trending_down,
                        size: 12,
                        color: growth >= 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${growth.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: growth >= 0
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_showComparison && previousValue != null)
                Text(
                  'vs $previousValue',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(List<ReceiptModel> receipts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.1),
            const Color(0xFF3B82F6).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt, color: Color(0xFF10B981), size: 20),
              SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickActionChip(
                'Today\'s Sales',
                Icons.today,
                () => setState(() => _selectedPeriod = AnalyticsPeriod.today),
              ),
              _buildQuickActionChip(
                'Best Sellers',
                Icons.star,
                () => _scrollToTopProducts(),
              ),
              _buildQuickActionChip(
                'Export Data',
                Icons.download,
                () => _handleExport('excel', receipts.first.storeId ?? ''),
              ),
              _buildQuickActionChip(
                'Peak Hours',
                Icons.schedule,
                () =>
                    setState(() => _selectedChartType = ChartType.transactions),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF10B981)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToTopProducts() {
    // Implement scroll to top products section
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scroll down to see Top Products'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildChartTypeSelector() {
    return Container(
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
            'Chart View',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildChartTypeChip(
                  'Revenue',
                  ChartType.revenue,
                  Icons.attach_money,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildChartTypeChip(
                  'Transactions',
                  ChartType.transactions,
                  Icons.receipt,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildChartTypeChip(
                  'Products',
                  ChartType.products,
                  Icons.inventory,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildChartTypeChip(
                  'Categories',
                  ChartType.categories,
                  Icons.category,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartTypeChip(String label, ChartType type, IconData icon) {
    final isSelected = _selectedChartType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedChartType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF10B981).withOpacity(0.1)
              : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF10B981)
                  : const Color(0xFF64748B),
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF10B981)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainChart(
    List<ReceiptModel> receipts,
    Map<String, dynamic> analytics,
  ) {
    switch (_selectedChartType) {
      case ChartType.revenue:
        return _buildRevenueChart(receipts);
      case ChartType.transactions:
        return _buildTransactionsChart(receipts);
      case ChartType.products:
        return _buildProductsChart(analytics);
      case ChartType.categories:
        return _buildCategoriesChart(analytics);
    }
  }

  Widget _buildRevenueChart(List<ReceiptModel> receipts) {
    if (receipts.isEmpty) return const SizedBox.shrink();

    return Container(
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
            'Revenue Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              _createRevenueChartData(receipts),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _createRevenueChartData(List<ReceiptModel> receipts) {
    final dailyRevenue = <DateTime, double>{};
    
    for (var receipt in receipts) {
      final date = DateTime(
        receipt.purchaseDate.year,
        receipt.purchaseDate.month,
        receipt.purchaseDate.day,
      );
      dailyRevenue[date] = (dailyRevenue[date] ?? 0) + receipt.totalAmount;
    }

    final sortedDates = dailyRevenue.keys.toList()..sort();
    final spots = <FlSpot>[];
    
    for (var i = 0; i < sortedDates.length; i++) {
      spots.add(FlSpot(i.toDouble(), dailyRevenue[sortedDates[i]]!));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1000,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: const Color(0xFFE2E8F0),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('MM/dd').format(sortedDates[value.toInt()]),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                    ),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1000,
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              return Text(
                '₹${(value / 1000).toStringAsFixed(0)}k',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (spots.length - 1).toDouble(),
      minY: 0,
      maxY: spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: const Color(0xFF10B981),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: const Color(0xFF10B981).withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsChart(List<ReceiptModel> receipts) {
    if (receipts.isEmpty) return const SizedBox.shrink();

    return Container(
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
            'Transaction Volume',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(_createTransactionsChartData(receipts)),
          ),
        ],
      ),
    );
  }

  LineChartData _createTransactionsChartData(List<ReceiptModel> receipts) {
    final dailyTransactions = <DateTime, int>{};

    for (var receipt in receipts) {
      final date = DateTime(
        receipt.purchaseDate.year,
        receipt.purchaseDate.month,
        receipt.purchaseDate.day,
      );
      dailyTransactions[date] = (dailyTransactions[date] ?? 0) + 1;
    }

    final sortedDates = dailyTransactions.keys.toList()..sort();
    final spots = <FlSpot>[];

    for (var i = 0; i < sortedDates.length; i++) {
      spots.add(
        FlSpot(i.toDouble(), dailyTransactions[sortedDates[i]]!.toDouble()),
      );
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: const Color(0xFFE2E8F0), strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('MM/dd').format(sortedDates[value.toInt()]),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                    ),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 5,
            reservedSize: 35,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (spots.length - 1).toDouble(),
      minY: 0,
      maxY: (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: const Color(0xFF3B82F6),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: const Color(0xFF3B82F6).withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildProductsChart(Map<String, dynamic> analytics) {
    final topProducts = (analytics['topProducts'] as List).take(5).toList();

    return Container(
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
            'Top 5 Products by Revenue',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: BarChart(_createProductsBarChartData(topProducts)),
          ),
        ],
      ),
    );
  }

  BarChartData _createProductsBarChartData(List<dynamic> products) {
    final barGroups = products.asMap().entries.map((entry) {
      final index = entry.key;
      final product = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (product['revenue'] as double),
            color: _touchedBarIndex == index
                ? const Color(0xFF10B981)
                : const Color(0xFF10B981).withOpacity(0.7),
            width: 30,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    }).toList();

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: products.isNotEmpty
          ? (products
                    .map((p) => p['revenue'] as double)
                    .reduce((a, b) => a > b ? a : b) *
                1.2)
          : 100,
      barGroups: barGroups,
      barTouchData: BarTouchData(
        enabled: true,
        touchCallback: (FlTouchEvent event, barTouchResponse) {
          setState(() {
            if (!event.isInterestedForInteractions ||
                barTouchResponse == null ||
                barTouchResponse.spot == null) {
              _touchedBarIndex = -1;
              return;
            }
            _touchedBarIndex = barTouchResponse.spot!.touchedBarGroupIndex;
          });
        },
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFF1F2937),
          tooltipRoundedRadius: 8,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final product = products[groupIndex];
            return BarTooltipItem(
              '${product['name']}\n',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              children: [
                TextSpan(
                  text: '₹${(product['revenue'] as double).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 11,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() < products.length) {
                final productName = products[value.toInt()]['name'] as String;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    productName.length > 8
                        ? '${productName.substring(0, 8)}...'
                        : productName,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              return Text(
                '₹${(value / 1000).toStringAsFixed(0)}k',
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              );
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1000,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: const Color(0xFFE2E8F0), strokeWidth: 1);
        },
      ),
      borderData: FlBorderData(show: false),
    );
  }

  Widget _buildCategoriesChart(Map<String, dynamic> analytics) {
    final categories =
        analytics['categories'] as Map<String, Map<String, dynamic>>;

    return Container(
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
            'Sales by Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: categories.isEmpty
                ? const Center(child: Text('No category data available'))
                : Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: PieChart(
                          _createCategoriesPieChartData(categories),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildCategoryLegend(categories)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  PieChartData _createCategoriesPieChartData(
    Map<String, Map<String, dynamic>> categories,
  ) {
    final colors = [
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF06B6D4),
      const Color(0xFFEF4444),
    ];

    final sections = categories.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final categoryEntry = entry.value;
      final isTouched = index == _touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 70.0 : 60.0;
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: categoryEntry.value['revenue'] as double,
        title: isTouched
            ? '${((categoryEntry.value['revenue'] as double) / categories.values.fold<double>(0, (sum, cat) => sum + (cat['revenue'] as double)) * 100).toStringAsFixed(1)}%'
            : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChartData(
      pieTouchData: PieTouchData(
        touchCallback: (FlTouchEvent event, pieTouchResponse) {
          setState(() {
            if (!event.isInterestedForInteractions ||
                pieTouchResponse == null ||
                pieTouchResponse.touchedSection == null) {
              _touchedIndex = -1;
              return;
            }
            _touchedIndex =
                pieTouchResponse.touchedSection!.touchedSectionIndex;
          });
        },
      ),
      sections: sections,
      sectionsSpace: 2,
      centerSpaceRadius: 40,
      startDegreeOffset: -90,
    );
  }

  Widget _buildCategoryLegend(Map<String, Map<String, dynamic>> categories) {
    final colors = [
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF06B6D4),
      const Color(0xFFEF4444),
    ];

    final total = categories.values.fold<double>(
      0,
      (sum, cat) => sum + (cat['revenue'] as double),
    );

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: categories.entries.toList().asMap().entries.map((entry) {
          final index = entry.key;
          final categoryEntry = entry.value;
          final percentage =
              ((categoryEntry.value['revenue'] as double) / total * 100)
                  .toStringAsFixed(1);
          final color = colors[index % colors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryEntry.key,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryAnalysis(Map<String, dynamic> analytics) {
    final categories =
        analytics['categories'] as Map<String, Map<String, dynamic>>;
    if (categories.isEmpty) return const SizedBox.shrink();

    final categoryList = categories.entries.toList()
      ..sort(
        (a, b) => (b.value['revenue'] as double).compareTo(
          a.value['revenue'] as double,
        ),
      );

    return Container(
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
          Row(
            children: [
              const Text(
                'Category Performance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (_selectedCategory != null)
                TextButton.icon(
                  onPressed: () => setState(() => _selectedCategory = null),
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear Filter'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categoryList.take(8).map((entry) {
              final isSelected = _selectedCategory == entry.key;
              return FilterChip(
                label: Text(entry.key),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? entry.key : null;
                  });
                },
                selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                checkmarkColor: const Color(0xFF10B981),
                avatar: isSelected
                    ? null
                    : CircleAvatar(
                        backgroundColor: const Color(
                          0xFF10B981,
                        ).withOpacity(0.1),
                        child: Text(
                          '${entry.value['quantity']}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              );
            }).toList(),
          ),
          if (_selectedCategory != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCategoryMetric(
                      'Revenue',
                      '₹${categories[_selectedCategory]!['revenue'].toStringAsFixed(2)}',
                      Icons.currency_rupee,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: const Color(0xFFE2E8F0),
                  ),
                  Expanded(
                    child: _buildCategoryMetric(
                      'Quantity',
                      '${categories[_selectedCategory]!['quantity']}',
                      Icons.inventory_2,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: const Color(0xFFE2E8F0),
                  ),
                  Expanded(
                    child: _buildCategoryMetric(
                      'Transactions',
                      '${categories[_selectedCategory]!['transactions']}',
                      Icons.receipt,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF10B981)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildHourlySalesPattern(List<ReceiptModel> receipts) {
    final hourlyData = <int, Map<String, dynamic>>{};
    for (var i = 0; i < 24; i++) {
      hourlyData[i] = {'revenue': 0.0, 'transactions': 0};
    }

    for (var receipt in receipts) {
      final hour = receipt.purchaseDate.hour;
      hourlyData[hour]!['revenue'] += receipt.totalAmount;
      hourlyData[hour]!['transactions'] += 1;
    }

    return Container(
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
          Row(
            children: [
              const Icon(Icons.access_time, size: 18, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              const Text(
                'Hourly Pattern',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: LineChart(_createHourlyChartData(hourlyData),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [_buildPeakHourIndicator(hourlyData)],
          ),
        ],
      ),
    );
  }

  LineChartData _createHourlyChartData(
    Map<int, Map<String, dynamic>> hourlyData,
  ) {
    final spots = hourlyData.entries
        .map(
          (e) => FlSpot(
            e.key.toDouble(),
            (e.value['transactions'] as int).toDouble(),
          ),
        )
        .toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 2,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: const Color(0xFFE2E8F0), strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 6,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${value.toInt()}h',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF64748B),
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 2,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}',
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF64748B),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 23,
      minY: 0,
      maxY: (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.3)
          .ceilToDouble(),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: const Color(0xFF8B5CF6),
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: const Color(0xFF8B5CF6).withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildPeakHourIndicator(Map<int, Map<String, dynamic>> hourlyData) {
    final peakHour = hourlyData.entries.reduce(
      (a, b) =>
          (a.value['transactions'] as int) > (b.value['transactions'] as int)
          ? a
          : b,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: Color(0xFF8B5CF6)),
          const SizedBox(width: 6),
          Text(
            'Peak: ${peakHour.key}:00 (${peakHour.value['transactions']} sales)',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B5CF6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitMarginAnalysis(Map<String, dynamic> analytics) {
    final profitMargin = analytics['profitMargin'] as double;
    final totalProfit = analytics['totalProfit'] as double;
    final totalRevenue = analytics['totalRevenue'] as double;
    final taxCollected = analytics['taxCollected'] as double;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF06B6D4).withOpacity(0.1),
            const Color(0xFF10B981).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFF06B6D4),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Profit & Tax Analysis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildProfitMetric(
                  'Gross Profit',
                  '₹${totalProfit.toStringAsFixed(2)}',
                  Icons.trending_up,
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProfitMetric(
                  'Profit Margin',
                  '${profitMargin.toStringAsFixed(1)}%',
                  Icons.percent,
                  const Color(0xFF06B6D4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProfitMetric(
                  'Tax Collected',
                  '₹${taxCollected.toStringAsFixed(2)}',
                  Icons.receipt_long,
                  const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: profitMargin / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF06B6D4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerBehaviorInsights(
    Map<String, dynamic> analytics,
    List<ReceiptModel> receipts,
  ) {
    final uniqueCustomers = analytics['uniqueCustomers'] as int;
    final repeatCustomers = analytics['repeatCustomers'] as int;
    final repeatRate = uniqueCustomers > 0
        ? (repeatCustomers / uniqueCustomers * 100)
        : 0.0;
    final avgOrderValue = analytics['averageOrderValue'] as double;
    final avgItemsPerOrder =
        analytics['totalItems'] /
        (analytics['totalTransactions'] > 0
            ? analytics['totalTransactions']
            : 1);

    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.people,
                  color: Color(0xFFEC4899),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Customer Behavior',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildBehaviorCard(
                  'Unique Customers',
                  '$uniqueCustomers',
                  Icons.person,
                  const Color(0xFFEC4899),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBehaviorCard(
                  'Repeat Customers',
                  '$repeatCustomers',
                  Icons.repeat,
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBehaviorCard(
                  'Repeat Rate',
                  '${repeatRate.toStringAsFixed(1)}%',
                  Icons.loyalty,
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBehaviorCard(
                  'Avg Items/Order',
                  avgItemsPerOrder.toStringAsFixed(1),
                  Icons.shopping_cart,
                  const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInsights(Map<String, dynamic> analytics) {
    return Container(
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
            'Additional Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildInsightRow(
            'Average Items per Transaction',
            '${(analytics['totalItems'] / (analytics['totalTransactions'] > 0 ? analytics['totalTransactions'] : 1)).toStringAsFixed(1)}',
            Icons.shopping_cart,
          ),
          _buildInsightRow(
            'Highest Single Transaction',
            '₹${analytics['totalRevenue'].toStringAsFixed(2)}',
            Icons.star,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF64748B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport(String type, String storeId) async {
    try {
      // Get all receipts for the selected period
      final allReceipts = await _firestoreService.getStoreSales(storeId).first;
      final receipts = _filterReceiptsByPeriod(allReceipts);

      if (receipts.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No data to export for selected period'),
              backgroundColor: Color(0xFFF59E0B),
            ),
          );
        }
        return;
      }

      switch (type) {
        case 'excel':
          await _exportService.exportToExcel(context, receipts, _selectedPeriod);
          break;
        case 'pdf':
          await _pdfService.generateAnalyticsPdf(context, receipts, _selectedPeriod);
          break;
        case 'print':
          await _pdfService.printAnalytics(context, receipts, _selectedPeriod);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Widget _buildPaymentMethodsChart(Map<String, dynamic> analytics) {
    final paymentMethods = analytics['paymentMethods'] as Map<String, double>;

    if (paymentMethods.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
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
          Row(
            children: [
              const Icon(Icons.payment, size: 18, color: Color(0xFF10B981)),
              const SizedBox(width: 8),
              const Text(
                'Payment Methods',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...paymentMethods.entries.map((entry) {
            final total = paymentMethods.values.fold<double>(
              0,
              (sum, val) => sum + val,
            );
            final percentage = (entry.value / total) * 100;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getPaymentIcon(entry.key),
                            size: 16,
                            color: _getPaymentColor(entry.key),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.key.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₹${entry.value.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getPaymentColor(entry.key),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${percentage.toStringAsFixed(1)}% of total',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'upi':
        return Icons.qr_code_scanner;
      case 'wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  Color _getPaymentColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return const Color(0xFF10B981);
      case 'card':
        return const Color(0xFF3B82F6);
      case 'upi':
        return const Color(0xFF8B5CF6);
      case 'wallet':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  Widget _buildTopProducts(Map<String, dynamic> analytics) {
    final topProducts = analytics['topProducts'] as List;

    if (topProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.star,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Top Selling Products',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topProducts.take(10).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            final revenue = product['revenue'] as double;
            final quantity = product['quantity'];
            final name = product['name'] as String;
            final category = product['category'] as String;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: index < 3
                      ? const Color(0xFFF59E0B).withOpacity(0.3)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: index < 3
                          ? const Color(0xFFF59E0B).withOpacity(0.2)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: index < 3
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Qty: $quantity',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${revenue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${product['transactions']} orders',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSalesByDayChart(List<ReceiptModel> receipts) {
    if (receipts.isEmpty) return const SizedBox.shrink();

    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayData = <int, Map<String, dynamic>>{};

    for (var i = 0; i < 7; i++) {
      dayData[i] = {'revenue': 0.0, 'transactions': 0};
    }

    for (var receipt in receipts) {
      final day = (receipt.purchaseDate.weekday - 1) % 7;
      dayData[day]!['revenue'] += receipt.totalAmount;
      dayData[day]!['transactions'] += 1;
    }

    return Container(
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
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 18,
                color: Color(0xFF3B82F6),
              ),
              const SizedBox(width: 8),
              const Text(
                'Sales by Day of Week',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(_createDayOfWeekChartData(dayData, dayNames)),
          ),
        ],
      ),
    );
  }

  BarChartData _createDayOfWeekChartData(
    Map<int, Map<String, dynamic>> dayData,
    List<String> dayNames,
  ) {
    final maxRevenue = dayData.values
        .map((d) => d['revenue'] as double)
        .reduce((a, b) => a > b ? a : b);

    final barGroups = dayData.entries.map((entry) {
      final index = entry.key;
      final revenue = entry.value['revenue'] as double;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: revenue,
            color: const Color(0xFF3B82F6),
            width: 24,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                const Color(0xFF3B82F6).withOpacity(0.7),
                const Color(0xFF3B82F6),
              ],
            ),
          ),
        ],
      );
    }).toList();

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxRevenue * 1.2,
      barGroups: barGroups,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFF1F2937),
          tooltipRoundedRadius: 8,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final data = dayData[groupIndex]!;
            return BarTooltipItem(
              '${dayNames[groupIndex]}\n',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              children: [
                TextSpan(
                  text: '₹${(data['revenue'] as double).toStringAsFixed(2)}\n',
                  style: const TextStyle(
                    color: Color(0xFF3B82F6),
                    fontSize: 11,
                  ),
                ),
                TextSpan(
                  text: '${data['transactions']} orders',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < dayNames.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    dayNames[value.toInt()],
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              return Text(
                '₹${(value / 1000).toStringAsFixed(0)}k',
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              );
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxRevenue / 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: const Color(0xFFE2E8F0), strokeWidth: 1);
        },
      ),
      borderData: FlBorderData(show: false),
    );
  }
}
