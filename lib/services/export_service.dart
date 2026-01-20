import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/receipt_model.dart';
import '../screens/analytics_screen.dart';

class ExportService {
  Future<void> exportToExcel(
    BuildContext context,
    List<ReceiptModel> receipts,
    AnalyticsPeriod period,
  ) async {
    try {
      // Generate CSV content (Excel-compatible)
      final csvContent = _generateCSV(receipts);
      
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/analytics_${_getPeriodName(period)}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv');
      
      // Write CSV content
      await file.writeAsString(csvContent);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Analytics Report - ${_getPeriodName(period)}',
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Analytics exported successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  String _generateCSV(List<ReceiptModel> receipts) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Receipt ID,Date,Time,Total Amount,Payment Method,Items Count');
    
    // Data rows
    for (var receipt in receipts) {
      final date = DateFormat('yyyy-MM-dd').format(receipt.purchaseDate);
      final time = DateFormat('HH:mm:ss').format(receipt.purchaseDate);
      
      buffer.writeln(
        '${receipt.id},'
        '$date,'
        '$time,'
        '${receipt.totalAmount.toStringAsFixed(2)},'
        '${receipt.paymentMethod},'
        '${receipt.items.length}'
      );
    }
    
    // Summary
    buffer.writeln('');
    buffer.writeln('Summary');
    buffer.writeln('Total Transactions,${receipts.length}');
    buffer.writeln('Total Revenue,${receipts.fold<double>(0, (sum, r) => sum + r.totalAmount).toStringAsFixed(2)}');
    buffer.writeln('Average Order Value,${(receipts.fold<double>(0, (sum, r) => sum + r.totalAmount) / receipts.length).toStringAsFixed(2)}');
    
    return buffer.toString();
  }

  String _getPeriodName(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.today:
        return 'Today';
      case AnalyticsPeriod.week:
        return 'This_Week';
      case AnalyticsPeriod.month:
        return 'This_Month';
      case AnalyticsPeriod.year:
        return 'This_Year';
      case AnalyticsPeriod.custom:
        return 'Custom_Period';
    }
  }
}
