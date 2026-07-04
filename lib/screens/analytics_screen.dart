import '../utils/app_theme.dart';
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
            backgroundColor: AppColors.background,
            body: Center(
              child: Text(
                'Not authenticated',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        final user = authState.user;
        if (user.storeId == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: _buildAppBar(null),
            body: const Center(
              child: Text(
                'No store associated with this account',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(user.storeId),
          body: StreamBuilder<List<ReceiptModel>>(
            stream: _firestoreService.getStoreSales(user.storeId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: AppColors.errorSurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline,
                          size: 40,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => setState(() {}),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
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
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.analytics_outlined,
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'No Data Yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Analytics will appear once you have sales',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
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
                    _buildPeriodSelector(),
                    const SizedBox(height: 20),

                    _buildKeyMetrics(analytics, previousAnalytics),
                    const SizedBox(height: 20),

                    _buildQuickActions(filteredReceipts),
                    const SizedBox(height: 20),

                    _buildChartTypeSelector(),
                    const SizedBox(height: 16),

                    _buildMainChart(filteredReceipts, analytics),
                    const SizedBox(height: 20),

                    _buildCategoryAnalysis(analytics),
                    const SizedBox(height: 20),

                    _buildPaymentMethodsChart(analytics),
                    const SizedBox(height: 20),

                    _buildHourlySalesPattern(filteredReceipts),
                    const SizedBox(height: 20),

                    _buildTopProducts(analytics),
                    const SizedBox(height: 20),

                    _buildSalesByDayChart(filteredReceipts),
                    const SizedBox(height: 20),

                    _buildProfitMarginAnalysis(analytics),
                    const SizedBox(height: 20),

                    _buildCustomerBehaviorInsights(analytics, filteredReceipts),
                    const SizedBox(height: 20),

                    _buildAdditionalInsights(analytics),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(String? storeId) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Analytics',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _showComparison ? Icons.compare_arrows_rounded : Icons.insights_rounded,
            color: _showComparison ? AppColors.accent : AppColors.textPrimary,
          ),
          tooltip: 'Toggle Comparison',
          onPressed: () => setState(() => _showComparison = !_showComparison),
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
          tooltip: 'Refresh',
          onPressed: () => setState(() {}),
        ),
        if (storeId != null)
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_rounded, color: AppColors.textPrimary),
            tooltip: 'Export Data',
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            onSelected: (value) => _handleExport(value, storeId),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.successSurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.table_chart_rounded,
                        color: AppColors.success,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Export to Excel',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.errorSurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: AppColors.error,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Export to PDF',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.infoSurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.print_rounded,
                        color: AppColors.info,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Print Report',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
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

    final totalRevenue = receipts.fold<double>(0, (sum, r) => sum + r.totalAmount);
    final totalTransactions = receipts.length;
    final averageOrderValue = totalRevenue / totalTransactions;
    final totalItems = receipts.fold<int>(0, (sum, r) => sum + r.items.length);

    final paymentMethods = <String, double>{};
    for (var receipt in receipts) {
      final method = receipt.paymentMethod.toLowerCase();
      paymentMethods[method] = (paymentMethods[method] ?? 0) + receipt.totalAmount;
    }

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

    final hourlyData = <int, Map<String, dynamic>>{};
    for (var i = 0; i < 24; i++) {
      hourlyData[i] = {'revenue': 0.0, 'transactions': 0};
    }
    for (var receipt in receipts) {
      final hour = receipt.purchaseDate.hour;
      hourlyData[hour]!['revenue'] += receipt.totalAmount;
      hourlyData[hour]!['transactions'] += 1;
    }

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

  // ──────────────────────────────────────────
  // Period Selector
  // ──────────────────────────────────────────

  Widget _buildPeriodSelector() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Time Period',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
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
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '${DateFormat('MMM dd, yyyy').format(_customStartDate!)} — ${DateFormat('MMM dd, yyyy').format(_customEndDate!)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
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
    return GestureDetector(
      onTap: () async {
        if (period == AnalyticsPeriod.custom) {
          final DateTimeRange? picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            builder: (context, child) => Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.accent,
                  onPrimary: Colors.white,
                ),
              ),
              child: child!,
            ),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Key Metrics
  // ──────────────────────────────────────────

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
                icon: Icons.currency_rupee_rounded,
                label: 'Total Revenue',
                value: '₹${analytics['totalRevenue'].toStringAsFixed(2)}',
                growth: analytics['revenueGrowth'],
                stripColor: AppColors.accent,
                previousValue: previousAnalytics != null
                    ? '₹${previousAnalytics['totalRevenue'].toStringAsFixed(2)}'
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.receipt_long_rounded,
                label: 'Transactions',
                value: '${analytics['totalTransactions']}',
                growth: analytics['transactionsGrowth'],
                stripColor: AppColors.info,
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
                icon: Icons.trending_up_rounded,
                label: 'Avg Order Value',
                value: '₹${analytics['averageOrderValue'].toStringAsFixed(2)}',
                growth: null,
                stripColor: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.shopping_bag_outlined,
                label: 'Items Sold',
                value: '${analytics['totalItems']}',
                growth: null,
                stripColor: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.people_rounded,
                label: 'Unique Customers',
                value: '${analytics['uniqueCustomers']}',
                growth: null,
                stripColor: AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Profit Margin',
                value: '${analytics['profitMargin'].toStringAsFixed(1)}%',
                growth: null,
                stripColor: AppColors.info,
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
    required Color stripColor,
    required String value,
    double? growth,
    String? previousValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: stripColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: stripColor, size: 18),
              ),
              const Spacer(),
              if (growth != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: growth >= 0
                        ? AppColors.successSurface
                        : AppColors.errorSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        growth >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 11,
                        color: growth >= 0 ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${growth.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: growth >= 0 ? AppColors.success : AppColors.error,
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
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_showComparison && previousValue != null)
                Text(
                  'vs $previousValue',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // Quick Actions
  // ──────────────────────────────────────────

  Widget _buildQuickActions(List<ReceiptModel> receipts) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: AppColors.accent, size: 18),
              SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
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
                Icons.today_rounded,
                () => setState(() => _selectedPeriod = AnalyticsPeriod.today),
              ),
              _buildQuickActionChip(
                'Best Sellers',
                Icons.star_rounded,
                () => _scrollToTopProducts(),
              ),
              if (receipts.isNotEmpty)
                _buildQuickActionChip(
                  'Export Data',
                  Icons.download_rounded,
                  () => _handleExport('excel', receipts.first.storeId),
                ),
              _buildQuickActionChip(
                'Peak Hours',
                Icons.schedule_rounded,
                () => setState(
                    () => _selectedChartType = ChartType.transactions),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToTopProducts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scroll down to see Top Products'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Chart Type Selector
  // ──────────────────────────────────────────

  Widget _buildChartTypeSelector() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chart View',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildChartTypeChip(
                  'Revenue',
                  ChartType.revenue,
                  Icons.attach_money_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildChartTypeChip(
                  'Transactions',
                  ChartType.transactions,
                  Icons.receipt_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildChartTypeChip(
                  'Products',
                  ChartType.products,
                  Icons.inventory_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildChartTypeChip(
                  'Categories',
                  ChartType.categories,
                  Icons.category_rounded,
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
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentSurface : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.accent : AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
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

  // ──────────────────────────────────────────
  // Revenue Chart
  // ──────────────────────────────────────────

  Widget _buildRevenueChart(List<ReceiptModel> receipts) {
    if (receipts.isEmpty) return const SizedBox.shrink();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Trend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(_createRevenueChartData(receipts)),
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
          return FlLine(color: AppColors.border, strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                      color: AppColors.textSecondary,
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
                  color: AppColors.textSecondary,
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
          color: AppColors.accent,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.accent.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  // Transactions Chart
  // ──────────────────────────────────────────

  Widget _buildTransactionsChart(List<ReceiptModel> receipts) {
    if (receipts.isEmpty) return const SizedBox.shrink();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transaction Volume',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
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
          return FlLine(color: AppColors.border, strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                      color: AppColors.textSecondary,
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
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
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
      maxY: (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.info,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.info.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  // Products Chart
  // ──────────────────────────────────────────

  Widget _buildProductsChart(Map<String, dynamic> analytics) {
    final topProducts = (analytics['topProducts'] as List).take(5).toList();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 5 Products by Revenue',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
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
                ? AppColors.accent
                : AppColors.accent.withValues(alpha: 0.7),
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
          getTooltipColor: (_) => AppColors.primary,
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
                  text:
                      '₹${(product['revenue'] as double).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.accentSurface,
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
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                      color: AppColors.textSecondary,
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
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
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
          return FlLine(color: AppColors.border, strokeWidth: 1);
        },
      ),
      borderData: FlBorderData(show: false),
    );
  }

  // ──────────────────────────────────────────
  // Categories Chart
  // ──────────────────────────────────────────

  Widget _buildCategoriesChart(Map<String, dynamic> analytics) {
    final categories =
        analytics['categories'] as Map<String, Map<String, dynamic>>;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales by Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: categories.isEmpty
                ? Center(
                    child: Text(
                      'No category data available',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: PieChart(
                          _createCategoriesPieChartData(categories),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(child: _buildCategoryLegend(categories)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // Pie chart colours are intentionally distinct but not rainbow-gradient
  static const _pieColors = [
    AppColors.accent,
    AppColors.info,
    AppColors.success,
    AppColors.warning,
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
    Color(0xFFDB2777),
  ];

  PieChartData _createCategoriesPieChartData(
    Map<String, Map<String, dynamic>> categories,
  ) {
    final sections = categories.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final categoryEntry = entry.value;
      final isTouched = index == _touchedIndex;
      final fontSize = isTouched ? 15.0 : 11.0;
      final radius = isTouched ? 70.0 : 60.0;

      return PieChartSectionData(
        color: _pieColors[index % _pieColors.length],
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
          final color = _pieColors[index % _pieColors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryEntry.key,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
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

  // ──────────────────────────────────────────
  // Category Analysis
  // ──────────────────────────────────────────

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

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Category Performance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (_selectedCategory != null)
                GestureDetector(
                  onTap: () => setState(() => _selectedCategory = null),
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categoryList.take(8).map((entry) {
              final isSelected = _selectedCategory == entry.key;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedCategory = isSelected ? null : entry.key;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accentSurface : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isSelected) ...[
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppColors.accentSurface,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${entry.value['quantity']}',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? AppColors.accent : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedCategory != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCategoryMetric(
                      'Revenue',
                      '₹${categories[_selectedCategory]!['revenue'].toStringAsFixed(2)}',
                      Icons.currency_rupee_rounded,
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppColors.border),
                  Expanded(
                    child: _buildCategoryMetric(
                      'Quantity',
                      '${categories[_selectedCategory]!['quantity']}',
                      Icons.inventory_2_rounded,
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppColors.border),
                  Expanded(
                    child: _buildCategoryMetric(
                      'Transactions',
                      '${categories[_selectedCategory]!['transactions']}',
                      Icons.receipt_rounded,
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
        Icon(icon, size: 18, color: AppColors.accent),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  // Hourly Sales Pattern
  // ──────────────────────────────────────────

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

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.accentSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Hourly Pattern',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: LineChart(_createHourlyChartData(hourlyData)),
          ),
          const SizedBox(height: 12),
          Center(child: _buildPeakHourIndicator(hourlyData)),
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
          return FlLine(color: AppColors.border, strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                    color: AppColors.textSecondary,
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
                  color: AppColors.textSecondary,
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
          color: AppColors.accent,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.accent.withValues(alpha: 0.08),
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
        color: AppColors.accentSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 13, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            'Peak: ${peakHour.key}:00 (${peakHour.value['transactions']} sales)',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // Profit Margin Analysis
  // ──────────────────────────────────────────

  Widget _buildProfitMarginAnalysis(Map<String, dynamic> analytics) {
    final profitMargin = analytics['profitMargin'] as double;
    final totalProfit = analytics['totalProfit'] as double;
    final taxCollected = analytics['taxCollected'] as double;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.infoSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.info,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Profit & Tax Analysis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
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
                  Icons.trending_up_rounded,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProfitMetric(
                  'Profit Margin',
                  '${profitMargin.toStringAsFixed(1)}%',
                  Icons.percent_rounded,
                  AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProfitMetric(
                  'Tax Collected',
                  '₹${taxCollected.toStringAsFixed(2)}',
                  Icons.receipt_long_rounded,
                  AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: profitMargin / 100,
              minHeight: 7,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.info),
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
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // Customer Behavior Insights
  // ──────────────────────────────────────────

  Widget _buildCustomerBehaviorInsights(
    Map<String, dynamic> analytics,
    List<ReceiptModel> receipts,
  ) {
    final uniqueCustomers = analytics['uniqueCustomers'] as int;
    final repeatCustomers = analytics['repeatCustomers'] as int;
    final repeatRate = uniqueCustomers > 0
        ? (repeatCustomers / uniqueCustomers * 100)
        : 0.0;
    final avgItemsPerOrder =
        analytics['totalItems'] /
        (analytics['totalTransactions'] > 0
            ? analytics['totalTransactions']
            : 1);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.people_rounded,
                  color: AppColors.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Customer Behavior',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
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
                  Icons.person_rounded,
                  AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBehaviorCard(
                  'Repeat Customers',
                  '$repeatCustomers',
                  Icons.repeat_rounded,
                  AppColors.success,
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
                  Icons.loyalty_rounded,
                  AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBehaviorCard(
                  'Avg Items/Order',
                  avgItemsPerOrder.toStringAsFixed(1),
                  Icons.shopping_cart_rounded,
                  AppColors.warning,
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
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // Additional Insights
  // ──────────────────────────────────────────

  Widget _buildAdditionalInsights(Map<String, dynamic> analytics) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional Insights',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInsightRow(
            'Average Items per Transaction',
            '${(analytics['totalItems'] / (analytics['totalTransactions'] > 0 ? analytics['totalTransactions'] : 1)).toStringAsFixed(1)}',
            Icons.shopping_cart_rounded,
          ),
          _buildInsightRow(
            'Highest Single Transaction',
            '₹${analytics['totalRevenue'].toStringAsFixed(2)}',
            Icons.star_rounded,
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
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // Payment Methods Chart
  // ──────────────────────────────────────────

  Widget _buildPaymentMethodsChart(Map<String, dynamic> analytics) {
    final paymentMethods = analytics['paymentMethods'] as Map<String, double>;
    final isEmpty =
        paymentMethods.isEmpty || paymentMethods.values.every((v) => v == 0);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.accentSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.payment_rounded,
                  size: 16,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Payment Methods',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isEmpty)
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.payment_outlined,
                      size: 36,
                      color: AppColors.textTertiary,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No payment data',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...paymentMethods.entries.map((entry) {
              final total = paymentMethods.values
                  .fold<double>(0, (sum, val) => sum + val);
              final percentage = (entry.value / total) * 100;
              final color = _getPaymentColor(entry.key);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                _getPaymentIcon(entry.key),
                                size: 15,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              entry.key.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${entry.value.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: percentage / 100,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.money_rounded;
      case 'card':
        return Icons.credit_card_rounded;
      case 'upi':
        return Icons.qr_code_scanner_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  Color _getPaymentColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return AppColors.success;
      case 'card':
        return AppColors.info;
      case 'upi':
        return AppColors.accent;
      case 'wallet':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  // ──────────────────────────────────────────
  // Top Products
  // ──────────────────────────────────────────

  Widget _buildTopProducts(Map<String, dynamic> analytics) {
    final topProducts = analytics['topProducts'] as List;

    if (topProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.warningSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: AppColors.warning,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Top Selling Products',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
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
            final isTop3 = index < 3;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isTop3
                      ? AppColors.warning.withValues(alpha: 0.35)
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isTop3
                          ? AppColors.warningSurface
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isTop3
                            ? AppColors.warning.withValues(alpha: 0.3)
                            : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isTop3
                              ? AppColors.warning
                              : AppColors.textSecondary,
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
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentSurface,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Qty: $quantity',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${product['transactions']} orders',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // Sales by Day of Week
  // ──────────────────────────────────────────

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

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.infoSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Sales by Day of Week',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
            color: AppColors.info,
            width: 22,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(5),
              topRight: Radius.circular(5),
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
          getTooltipColor: (_) => AppColors.primary,
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
                    color: AppColors.accentSurface,
                    fontSize: 11,
                  ),
                ),
                TextSpan(
                  text: '${data['transactions']} orders',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
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
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                      color: AppColors.textSecondary,
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
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
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
          return FlLine(color: AppColors.border, strokeWidth: 1);
        },
      ),
      borderData: FlBorderData(show: false),
    );
  }

  // ──────────────────────────────────────────
  // Export
  // ──────────────────────────────────────────

  Future<void> _handleExport(String type, String storeId) async {
    try {
      final allReceipts =
          await _firestoreService.getStoreSales(storeId).first;
      final receipts = _filterReceiptsByPeriod(allReceipts);

      if (receipts.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No data to export for selected period'),
            ),
          );
        }
        return;
      }

      switch (type) {
        case 'excel':
          if (!mounted) return;
          await _exportService.exportToExcel(context, receipts, _selectedPeriod);
          break;
        case 'pdf':
          if (!mounted) return;
          await _pdfService.generateAnalyticsPdf(
              context, receipts, _selectedPeriod);
          break;
        case 'print':
          if (!mounted) return;
          await _pdfService.printAnalytics(context, receipts, _selectedPeriod);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // ──────────────────────────────────────────
  // Shared Card container
  // ──────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
