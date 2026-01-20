import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/receipt_model.dart';
import '../screens/analytics_screen.dart';

class PdfService {
  Future<void> generateAnalyticsPdf(
    BuildContext context,
    List<ReceiptModel> receipts,
    AnalyticsPeriod period,
  ) async {
    try {
      final pdf = await _createAnalyticsPdf(receipts, period);
      
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/analytics_${_getPeriodName(period)}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
      
      // Save PDF
      await file.writeAsBytes(await pdf.save());
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Analytics Report - ${_getPeriodName(period)}',
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF generated successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> printAnalytics(
    BuildContext context,
    List<ReceiptModel> receipts,
    AnalyticsPeriod period,
  ) async {
    try {
      final pdf = await _createAnalyticsPdf(receipts, period);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<pw.Document> _createAnalyticsPdf(
    List<ReceiptModel> receipts,
    AnalyticsPeriod period,
  ) async {
    final pdf = pw.Document();
    
    // Calculate analytics
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
          };
        }
      }
    }
    
    final topProducts = productSales.values.toList()
      ..sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Analytics Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${_getPeriodName(period)} - ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
                    style: const pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Key Metrics
            pw.Text(
              'Key Metrics',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                children: [
                  _buildMetricRow('Total Revenue', '₹${totalRevenue.toStringAsFixed(2)}'),
                  _buildMetricRow('Total Transactions', '$totalTransactions'),
                  _buildMetricRow('Average Order Value', '₹${averageOrderValue.toStringAsFixed(2)}'),
                  _buildMetricRow('Total Items Sold', '$totalItems'),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Payment Methods
            pw.Text(
              'Payment Methods Breakdown',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                children: paymentMethods.entries.map((entry) {
                  final percentage = (entry.value / totalRevenue * 100).toStringAsFixed(1);
                  return _buildMetricRow(
                    entry.key.toUpperCase(),
                    '₹${entry.value.toStringAsFixed(2)} ($percentage%)',
                  );
                }).toList(),
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Top Products
            pw.Text(
              'Top 10 Products',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('Rank', isHeader: true),
                    _buildTableCell('Product', isHeader: true),
                    _buildTableCell('Quantity', isHeader: true),
                    _buildTableCell('Revenue', isHeader: true),
                  ],
                ),
                ...topProducts.take(10).toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final product = entry.value;
                  return pw.TableRow(
                    children: [
                      _buildTableCell('${index + 1}'),
                      _buildTableCell(product['name']),
                      _buildTableCell('${product['quantity']}'),
                      _buildTableCell('₹${(product['revenue'] as double).toStringAsFixed(2)}'),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );
    
    return pdf;
  }

  pw.Widget _buildMetricRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  String _getPeriodName(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.today:
        return 'Today';
      case AnalyticsPeriod.week:
        return 'This Week';
      case AnalyticsPeriod.month:
        return 'This Month';
      case AnalyticsPeriod.year:
        return 'This Year';
      case AnalyticsPeriod.custom:
        return 'Custom Period';
    }
  }
}
