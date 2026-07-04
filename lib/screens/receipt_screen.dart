import '../utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../models/receipt_model.dart';
import '../models/cart_item_model.dart';
import '../services/firestore_service.dart';

class ReceiptScreen extends StatefulWidget {
  final String receiptId;

  const ReceiptScreen({super.key, required this.receiptId});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _showDetails = false;

  // Helper method to calculate tax breakdown
  Map<String, double> _calculateTaxBreakdown(List<CartItemModel> items) {
    final Map<String, double> taxBreakdown = {};
    double totalTax = 0.0;

    for (var item in items) {
      final taxPercentage = item.product.taxPercentage;
      final taxKey = '${taxPercentage.toStringAsFixed(0)}%';
      final itemTaxAmount = item.product.taxAmount * item.quantity;

      taxBreakdown[taxKey] = (taxBreakdown[taxKey] ?? 0.0) + itemTaxAmount;
      totalTax += itemTaxAmount;
    }

    taxBreakdown['total'] = totalTax;
    return taxBreakdown;
  }

  // Helper method to calculate subtotal (before tax)
  double _calculateSubtotal(List<CartItemModel> items) {
    double subtotal = 0.0;
    for (var item in items) {
      if (item.product.isTaxInclusive) {
        final basePrice =
            item.product.sellingPrice / (1 + item.product.taxPercentage / 100);
        subtotal += basePrice * item.quantity;
      } else {
        subtotal += item.product.sellingPrice * item.quantity;
      }
    }
    return subtotal;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    HapticFeedback.mediumImpact();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ReceiptModel?>(
      stream: _firestoreService.getReceiptStream(widget.receiptId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              title: const Text(
                'Receipt',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
              iconTheme: const IconThemeData(color: AppColors.textPrimary),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
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
            ),
          );
        }

        final receipt = snapshot.data;

        if (receipt == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              title: const Text(
                'Receipt',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
              iconTheme: const IconThemeData(color: AppColors.textPrimary),
            ),
            body: const Center(
              child: Text(
                'Receipt not found',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        final taxBreakdown = _calculateTaxBreakdown(receipt.items);
        final subtotal = _calculateSubtotal(receipt.items);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Receipt Hero Header — solid near-black
                        Container(
                          width: double.infinity,
                          color: AppColors.primary,
                          padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
                          child: Column(
                            children: [
                              // Status icon
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: receipt.verified
                                        ? AppColors.successSurface
                                        : AppColors.warningSurface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    receipt.verified
                                        ? Icons.verified_rounded
                                        : Icons.pending_outlined,
                                    size: 40,
                                    color: receipt.verified
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Column(
                                  children: [
                                    Text(
                                      receipt.verified
                                          ? 'Receipt Verified'
                                          : 'Payment Successful',
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      DateFormat(
                                        'MMM dd, yyyy • hh:mm a',
                                      ).format(receipt.purchaseDate),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withValues(alpha: 0.6),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // Amount — large white bold
                                    Text(
                                      '₹${receipt.totalAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Verification Status Banner
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: _buildStatusBanner(receipt.verified),
                        ),

                        // QR Code Section
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // QR Code card
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  children: [
                                    ScaleTransition(
                                      scale: _scaleAnimation,
                                      child: Stack(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppColors.surface,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: receipt.verified
                                                    ? AppColors.success
                                                    : AppColors.border,
                                                width: receipt.verified ? 2 : 1,
                                              ),
                                            ),
                                            child: QrImageView(
                                              data: widget.receiptId,
                                              version: QrVersions.auto,
                                              size: 200.0,
                                              backgroundColor: Colors.white,
                                              eyeStyle: const QrEyeStyle(
                                                eyeShape: QrEyeShape.square,
                                                color: AppColors.primary,
                                              ),
                                              dataModuleStyle:
                                                  const QrDataModuleStyle(
                                                    dataModuleShape:
                                                        QrDataModuleShape
                                                            .square,
                                                    color: AppColors.primary,
                                                  ),
                                            ),
                                          ),
                                          // Blur overlay when verified
                                          if (receipt.verified)
                                            Positioned.fill(
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: BackdropFilter(
                                                  filter: ImageFilter.blur(
                                                    sigmaX: 8.0,
                                                    sigmaY: 8.0,
                                                  ),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withValues(alpha: 0.3),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: const [
                                                          Icon(
                                                            Icons.check_circle_rounded,
                                                            size: 56,
                                                            color: AppColors.success,
                                                          ),
                                                          SizedBox(height: 10),
                                                          Text(
                                                            'VERIFIED',
                                                            style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight.w800,
                                                              color: AppColors.success,
                                                              letterSpacing: 2,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Receipt ID chip
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceElevated,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Text(
                                        'ID: ${widget.receiptId.substring(0, 12).toUpperCase()}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                          fontFamily: 'monospace',
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Instruction banner
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: receipt.verified
                                      ? AppColors.successSurface
                                      : AppColors.warningSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: receipt.verified
                                        ? AppColors.success.withValues(alpha: 0.3)
                                        : AppColors.warning.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      receipt.verified
                                          ? Icons.check_circle_outline_rounded
                                          : Icons.info_outline_rounded,
                                      size: 20,
                                      color: receipt.verified
                                          ? AppColors.success
                                          : AppColors.warning,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        receipt.verified
                                            ? 'Your receipt has been verified by security. You may exit the store.'
                                            : 'Show this QR code at the exit for verification.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: receipt.verified
                                              ? const Color(0xFF14532D)
                                              : const Color(0xFF78350F),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Order Details Toggle
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _showDetails = !_showDetails;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(9),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentSurface,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long_outlined,
                                      color: AppColors.accent,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'View Order Details',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    _showDetails
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.textTertiary,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Order Details (Expandable)
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Padding(
                            padding: const EdgeInsets.all(20),
                            child: _buildOrderDetails(
                              receipt,
                              subtotal,
                              taxBreakdown,
                            ),
                          ),
                          crossFadeState: _showDetails
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 300),
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),

                // Done Button — sticky
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      top: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Done Shopping',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBanner(bool isVerified) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: isVerified ? AppColors.successSurface : AppColors.warningSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isVerified ? Icons.verified_rounded : Icons.pending_outlined,
              color: isVerified ? AppColors.success : AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVerified ? 'Verification Status' : 'Pending Verification',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isVerified ? 'Verified by Security' : 'Awaiting Guard Scan',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (isVerified)
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 22,
            ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(
    ReceiptModel receipt,
    double subtotal,
    Map<String, double> taxBreakdown,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Items header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: const Text(
              'Items Purchased',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // Item rows with border-bottom divider
          ...List.generate(receipt.items.length, (index) {
            final item = receipt.items[index];
            final isLast = index == receipt.items.length - 1;
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isLast ? Colors.transparent : AppColors.border,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '${item.quantity}×',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (item.product.brandName != null)
                          Text(
                            item.product.brandName!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${item.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),

          // Subtotal / Tax / Total section
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                // Subtotal
                _buildSummaryRow(
                  'Subtotal',
                  '₹${subtotal.toStringAsFixed(2)}',
                  isBold: false,
                ),
                const SizedBox(height: 10),
                // Tax breakdown
                ...taxBreakdown.entries
                    .where((entry) => entry.key != 'total')
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildSummaryRow(
                          'Tax (${entry.key})',
                          '₹${entry.value.toStringAsFixed(2)}',
                          isBold: false,
                        ),
                      ),
                    ),
                Container(
                  height: 1,
                  color: AppColors.border,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
                const SizedBox(height: 8),
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '₹${receipt.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Payment method row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.payment_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Paid via ${receipt.paymentMethod}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
