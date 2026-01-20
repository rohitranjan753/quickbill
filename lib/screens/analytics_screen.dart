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
                    ],
                  ),
                );
              }

              final allReceipts = snapshot.data ?? [];
              final filteredReceipts = _filterReceiptsByPeriod(allReceipts);
              final analytics = _calculateAnalytics(filteredReceipts);

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
                    _buildKeyMetrics(analytics),
                    const SizedBox(height: 24),

                    // Revenue Chart
                    _buildRevenueChart(filteredReceipts),
                    const SizedBox(height: 24),

                    // Payment Methods Chart
                    _buildPaymentMethodsChart(analytics),
                    const SizedBox(height: 24),

                    // Top Products
                    _buildTopProducts(analytics),
                    const SizedBox(height: 24),

                    // Sales by Day Chart
                    _buildSalesByDayChart(filteredReceipts),
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

    // Top products
    final productSales = <String, Map<String, dynamic>>{};
    for (var receipt in receipts) {
      for (var item in receipt.items) {
        final productName = item.product.name;
        if (productSales.containsKey(productName)) {
          productSales[productName]!['quantity'] += item.quantity;
          productSales[productName]!['revenue'] += item.totalPrice;
        } else {
          productSales[productName] = {
            'name': productName,
            'quantity': item.quantity,
            'revenue': item.totalPrice,
            'price': item.product.sellingPrice,
          };
        }
      }
    }

    final topProducts = productSales.values.toList()
      ..sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

    // Growth calculations (compare with previous period)
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

  Widget _buildKeyMetrics(Map<String, dynamic> analytics) {
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
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    double? growth,
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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

  Widget _buildPaymentMethodsChart(Map<String, dynamic> analytics) {
    final paymentMethods = analytics['paymentMethods'] as Map<String, double>;
    if (paymentMethods.isEmpty) return const SizedBox.shrink();

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
            'Payment Methods',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    _createPaymentPieChartData(paymentMethods),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildPaymentLegend(paymentMethods),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PieChartData _createPaymentPieChartData(Map<String, double> paymentMethods) {
    final colors = {
      'cash': const Color(0xFF10B981),
      'card': const Color(0xFF3B82F6),
      'upi': const Color(0xFF8B5CF6),
      'other': const Color(0xFFF59E0B),
    };

    final sections = paymentMethods.entries.map((entry) {
      final color = colors[entry.key] ?? const Color(0xFF64748B);
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChartData(
      sections: sections,
      sectionsSpace: 2,
      centerSpaceRadius: 40,
      startDegreeOffset: -90,
    );
  }

  Widget _buildPaymentLegend(Map<String, double> paymentMethods) {
    final colors = {
      'cash': const Color(0xFF10B981),
      'card': const Color(0xFF3B82F6),
      'upi': const Color(0xFF8B5CF6),
      'other': const Color(0xFFF59E0B),
    };

    final total = paymentMethods.values.fold<double>(0, (sum, value) => sum + value);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paymentMethods.entries.map((entry) {
        final percentage = (entry.value / total * 100).toStringAsFixed(1);
        final color = colors[entry.key] ?? const Color(0xFF64748B);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
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
                      entry.key.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontSize: 13,
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
    );
  }

  Widget _buildTopProducts(Map<String, dynamic> analytics) {
    final topProducts = analytics['topProducts'] as List<Map<String, dynamic>>;
    if (topProducts.isEmpty) return const SizedBox.shrink();

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
            'Top Products',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...topProducts.take(5).map((product) {
            final index = topProducts.indexOf(product);
            return _buildTopProductItem(product, index);
          }),
        ],
      ),
    );
  }

  Widget _buildTopProductItem(Map<String, dynamic> product, int index) {
    final colors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFC0C0C0), // Silver
      const Color(0xFFCD7F32), // Bronze
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: index < 3 ? colors[index].withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: index < colors.length
                  ? colors[index].withOpacity(0.2)
                  : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: index < colors.length ? colors[index] : const Color(0xFF64748B),
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
                  product['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${product['quantity']} units sold',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${(product['revenue'] as double).toStringAsFixed(2)}',
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

  Widget _buildSalesByDayChart(List<ReceiptModel> receipts) {
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
            'Sales by Day of Week',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              _createSalesByDayChartData(receipts),
            ),
          ),
        ],
      ),
    );
  }

  BarChartData _createSalesByDayChartData(List<ReceiptModel> receipts) {
    final salesByDay = <int, double>{
      1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0,
    };

    for (var receipt in receipts) {
      salesByDay[receipt.purchaseDate.weekday] =
          (salesByDay[receipt.purchaseDate.weekday] ?? 0) + receipt.totalAmount;
    }

    final barGroups = salesByDay.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key - 1,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: const Color(0xFF10B981),
            width: 20,
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
      maxY: salesByDay.values.reduce((a, b) => a > b ? a : b) * 1.2,
      barGroups: barGroups,
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  days[value.toInt()],
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
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
                  color: Color(0xFF64748B),
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
          return FlLine(
            color: const Color(0xFFE2E8F0),
            strokeWidth: 1,
          );
        },
      ),
      borderData: FlBorderData(show: false),
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
}
