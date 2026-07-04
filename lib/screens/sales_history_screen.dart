import '../utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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
  bool _isExporting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ReceiptModel> _filterReceipts(List<ReceiptModel> receipts) {
    var filtered = receipts;

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

    if (_paymentFilter != PaymentFilter.all) {
      filtered = filtered
          .where((r) => r.paymentMethod.toLowerCase() == _paymentFilter.name)
          .toList();
    }

    if (_verifiedOnly) {
      filtered = filtered.where((r) => r.verified).toList();
    }

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
      backgroundColor: AppColors.surface,
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
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Date Range',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SalesFilter.values.map((filter) {
                  final isSelected = _dateFilter == filter;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _dateFilter = filter;
                        if (filter == SalesFilter.custom) {
                          _showDateRangePicker();
                        }
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accent : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.accent : AppColors.border,
                        ),
                      ),
                      child: Text(
                        _getFilterLabel(filter),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PaymentFilter.values.map((filter) {
                  final isSelected = _paymentFilter == filter;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _paymentFilter = isSelected ? PaymentFilter.all : filter;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accent : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.accent : AppColors.border,
                        ),
                      ),
                      child: Text(
                        filter.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Verified Sales Only',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'Show only verified transactions',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  value: _verifiedOnly,
                  activeThumbColor: AppColors.accent,
                  onChanged: (value) {
                    setState(() => _verifiedOnly = value);
                    Navigator.pop(context);
                  },
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                ),
              ),

              const SizedBox(height: 24),

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
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reset All Filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.accent,
            onPrimary: Colors.white,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
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

  Future<void> _showExportDialog(List<ReceiptModel> receipts) async {
    if (receipts.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No sales data to export')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Export Sales Data',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.successSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.table_chart, color: AppColors.success, size: 20),
              ),
              title: const Text(
                'Export as CSV',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: const Text(
                'Excel-compatible spreadsheet',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _exportAsCSV(receipts);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.picture_as_pdf, color: AppColors.error, size: 20),
              ),
              title: const Text(
                'Export as PDF',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: const Text(
                'Printable report',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _exportAsPDF(receipts);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAsCSV(List<ReceiptModel> receipts) async {
    try {
      setState(() => _isExporting = true);

      final excel = excel_lib.Excel.createExcel();
      final sheet = excel['Sales Report'];

      sheet.appendRow([
        excel_lib.TextCellValue('Date'),
        excel_lib.TextCellValue('Receipt ID'),
        excel_lib.TextCellValue('Total Amount'),
        excel_lib.TextCellValue('Payment Method'),
        excel_lib.TextCellValue('Items Count'),
        excel_lib.TextCellValue('Verified'),
        excel_lib.TextCellValue('Product Names'),
      ]);

      for (final receipt in receipts) {
        final productNames = receipt.items
            .map((item) => '${item.product.name} (${item.quantity}x)')
            .join(', ');

        sheet.appendRow([
          excel_lib.TextCellValue(
            DateFormat('yyyy-MM-dd HH:mm').format(receipt.purchaseDate),
          ),
          excel_lib.TextCellValue(receipt.id),
          excel_lib.DoubleCellValue(receipt.totalAmount),
          excel_lib.TextCellValue(receipt.paymentMethod),
          excel_lib.IntCellValue(receipt.items.length),
          excel_lib.TextCellValue(receipt.verified ? 'Yes' : 'No'),
          excel_lib.TextCellValue(productNames),
        ]);
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/sales_report_$timestamp.xlsx';

      final fileBytes = excel.encode();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'Sales Report - $timestamp',
          text: 'Sales report containing ${receipts.length} transactions',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CSV exported successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportAsPDF(List<ReceiptModel> receipts) async {
    try {
      setState(() => _isExporting = true);

      final pdf = pw.Document();
      final stats = _calculateStats(receipts);
      final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
      final now = DateTime.now();

      const itemsPerPage = 20;
      final totalPages = (receipts.length / itemsPerPage).ceil();

      for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
        final startIndex = pageIndex * itemsPerPage;
        final endIndex = (startIndex + itemsPerPage).clamp(0, receipts.length);
        final pageReceipts = receipts.sublist(startIndex, endIndex);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Sales Report',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(now)}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.Text(
                      'Page ${pageIndex + 1} of $totalPages',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                if (pageIndex == 0) ...[
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                          children: [
                            _buildPdfStatItem(
                              'Total Sales',
                              'Rs. ${stats['totalSales'].toStringAsFixed(2)}',
                            ),
                            _buildPdfStatItem(
                              'Transactions',
                              '${stats['totalTransactions']}',
                            ),
                            _buildPdfStatItem(
                              'Avg Transaction',
                              'Rs. ${stats['averageTransaction'].toStringAsFixed(2)}',
                            ),
                            _buildPdfStatItem(
                              'Items Sold',
                              '${stats['totalItems']}',
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 8),
                        pw.Divider(),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                          children: [
                            _buildPdfStatItem(
                              'Cash Sales',
                              'Rs. ${stats['cashSales'].toStringAsFixed(2)}',
                            ),
                            _buildPdfStatItem(
                              'Card Sales',
                              'Rs. ${stats['cardSales'].toStringAsFixed(2)}',
                            ),
                            _buildPdfStatItem(
                              'UPI Sales',
                              'Rs. ${stats['upiSales'].toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),
                ],

                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1.5),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1),
                    4: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        _buildTableHeader('Date & Time'),
                        _buildTableHeader('Receipt ID'),
                        _buildTableHeader('Amount'),
                        _buildTableHeader('Payment'),
                        _buildTableHeader('Items'),
                      ],
                    ),
                    ...pageReceipts.map((receipt) {
                      return pw.TableRow(
                        children: [
                          _buildTableCell(
                            dateFormat.format(receipt.purchaseDate),
                          ),
                          _buildTableCell(receipt.id.substring(0, 8)),
                          _buildTableCell(
                            'Rs. ${receipt.totalAmount.toStringAsFixed(2)}',
                          ),
                          _buildTableCell(receipt.paymentMethod.toUpperCase()),
                          _buildTableCell('${receipt.items.length}'),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
      final filePath =
          '${directory.path}/QuickBill_Sales_Report_$timestamp.pdf';

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(filePath)],
        subject:
            'QuickBill Sales Report - ${DateFormat('MMM dd, yyyy').format(now)}',
        text: 'Sales report containing ${receipts.length} transactions',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF exported successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  pw.Widget _buildPdfStatItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 2),
        pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
      ],
    );
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 8)),
    );
  }

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
            appBar: _buildAppBar(null, null),
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
          appBar: _buildAppBar(user, null),
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
                    ],
                  ),
                );
              }

              final allReceipts = snapshot.data ?? [];
              final filteredReceipts = _filterReceipts(allReceipts);
              final stats = _calculateStats(filteredReceipts);

              if (allReceipts.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No Sales Yet',
                  subtitle: 'Sales transactions will appear here',
                );
              }

              return Column(
                children: [
                  // Search Bar
                  Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search by product, amount, receipt ID...',
                        hintStyle: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textTertiary,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  color: AppColors.textTertiary,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                    ),
                  ),

                  // Stats Summary — white card + border
                  Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.currency_rupee_rounded,
                                label: 'Total Sales',
                                value:
                                    '₹${stats['totalSales'].toStringAsFixed(2)}',
                                stripColor: AppColors.accent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.receipt_long_rounded,
                                label: 'Transactions',
                                value: '${stats['totalTransactions']}',
                                stripColor: AppColors.info,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.trending_up_rounded,
                                label: 'Avg Transaction',
                                value:
                                    '₹${stats['averageTransaction'].toStringAsFixed(2)}',
                                stripColor: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.shopping_bag_outlined,
                                label: 'Items Sold',
                                value: '${stats['totalItems']}',
                                stripColor: AppColors.warning,
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
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Method Breakdown',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildPaymentRow(
                            'Cash',
                            stats['cashSales'],
                            Icons.money_rounded,
                          ),
                          _buildPaymentRow(
                            'Card',
                            stats['cardSales'],
                            Icons.credit_card_rounded,
                          ),
                          _buildPaymentRow(
                            'UPI',
                            stats['upiSales'],
                            Icons.qr_code_scanner_rounded,
                          ),
                        ],
                      ),
                    ),

                  // Active Filters Indicator
                  if (_dateFilter != SalesFilter.all ||
                      _paymentFilter != PaymentFilter.all ||
                      _verifiedOnly)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.filter_list_rounded,
                            size: 16,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Filters active · ${filteredReceipts.length} of ${allReceipts.length} sales',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _dateFilter = SalesFilter.all;
                                _paymentFilter = PaymentFilter.all;
                                _verifiedOnly = false;
                              });
                            },
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
                    ),

                  // Sales List
                  Expanded(
                    child: filteredReceipts.isEmpty
                        ? _buildEmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No sales found',
                            subtitle: 'Try adjusting your filters',
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

  PreferredSizeWidget _buildAppBar(dynamic user, dynamic snapshot) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Sales History',
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
          icon: const Icon(Icons.tune_rounded, color: AppColors.textPrimary),
          tooltip: 'Filters',
          onPressed: _showFilterDialog,
        ),
        if (user != null && user.storeId != null)
          StreamBuilder<List<ReceiptModel>>(
            stream: _firestoreService.getStoreSales(user.storeId!),
            builder: (context, snapshot) {
              return IconButton(
                icon: _isExporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.textPrimary,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.download_rounded,
                        color: AppColors.textPrimary,
                      ),
                tooltip: 'Export',
                onPressed: _isExporting
                    ? null
                    : () {
                        final receipts = snapshot.data ?? [];
                        final filteredReceipts = _filterReceipts(receipts);
                        _showExportDialog(filteredReceipts);
                      },
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
            child: Icon(icon, size: 48, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color stripColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colored icon badge
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: stripColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: stripColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              method,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
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

  Widget _buildReceiptCard(ReceiptModel receipt) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    IconData paymentIcon;
    switch (receipt.paymentMethod.toLowerCase()) {
      case 'cash':
        paymentIcon = Icons.money_rounded;
        break;
      case 'card':
        paymentIcon = Icons.credit_card_rounded;
        break;
      case 'upi':
        paymentIcon = Icons.qr_code_scanner_rounded;
        break;
      default:
        paymentIcon = Icons.payment_rounded;
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
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Receipt icon in accent surface
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Amount — near-black bold
                        Text(
                          '₹${receipt.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateFormat.format(receipt.purchaseDate),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Verified badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: receipt.verified
                          ? AppColors.successSurface
                          : AppColors.errorSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: receipt.verified
                            ? AppColors.success.withValues(alpha: 0.3)
                            : AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          receipt.verified
                              ? Icons.verified_rounded
                              : Icons.hourglass_top_rounded,
                          size: 12,
                          color: receipt.verified ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          receipt.verified ? 'VERIFIED' : 'PENDING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: receipt.verified
                                ? AppColors.success
                                : AppColors.error,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildInfoChip(
                    Icons.shopping_bag_outlined,
                    '${receipt.items.length} items',
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    paymentIcon,
                    receipt.paymentMethod.toUpperCase(),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
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
    );
  }
}
