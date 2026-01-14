import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../blocs/cart/cart_bloc.dart';
import '../blocs/cart/cart_event.dart';
import '../blocs/cart/cart_state.dart';
import '../models/cart_item_model.dart';
import '../models/receipt_model.dart';
import '../services/firestore_service.dart';
import 'receipt_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedPaymentMethod = 'UPI';
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'name': 'UPI',
      'icon': Icons.account_balance_wallet_outlined,
      'subtitle': 'GPay, PhonePe, Paytm',
    },
    {
      'name': 'Card',
      'icon': Icons.credit_card_outlined,
      'subtitle': 'Credit or Debit Card',
    },
    {
      'name': 'Wallet',
      'icon': Icons.wallet_outlined,
      'subtitle': 'Digital Wallets',
    },
  ];

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
        // If tax is inclusive, subtract tax to get base price
        final basePrice =
            item.product.sellingPrice / (1 + item.product.taxPercentage / 100);
        subtotal += basePrice * item.quantity;
      } else {
        // If tax is not inclusive, use selling price directly
        subtotal += item.product.sellingPrice * item.quantity;
      }
    }
    return subtotal;
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);
    HapticFeedback.heavyImpact();

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      final authState = context.read<AuthBloc>().state;
      final cartState = context.read<CartBloc>().state;

      if (authState is! AuthAuthenticated) {
        throw Exception('User not authenticated');
      }

      // Create receipt
      final receipt = ReceiptModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: authState.user.uid,
        items: cartState.items,
        totalAmount: cartState.totalAmount,
        purchaseDate: DateTime.now(),
        paymentMethod: _selectedPaymentMethod,
      );

      // Save receipt to Firestore
      final receiptId = await _firestoreService.saveReceipt(receipt);

      // Clear cart
      if (mounted) {
        context.read<CartBloc>().add(CartCleared());

        // Navigate to receipt screen with success animation
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ReceiptScreen(receiptId: receiptId),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 400),
          ),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Payment failed: ${e.toString()}')),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          if (cartState.items.isEmpty) {
            return const Center(child: Text('Cart is empty'));
          }

          final taxBreakdown = _calculateTaxBreakdown(cartState.items);
          final subtotal = _calculateSubtotal(cartState.items);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Summary Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
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
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_outlined,
                                    color: Color(0xFF10B981),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Order Summary',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _SummaryRow(
                              label: 'Items',
                              value: '${cartState.itemCount}',
                              isRegular: true,
                            ),
                            const SizedBox(height: 12),
                            _SummaryRow(
                              label: 'Subtotal',
                              value: '₹${subtotal.toStringAsFixed(2)}',
                              isRegular: true,
                            ),
                            const SizedBox(height: 12),
                            // Tax Breakdown
                            ...taxBreakdown.entries
                                .where((entry) => entry.key != 'total')
                                .map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _SummaryRow(
                                      label: 'Tax (${entry.key})',
                                      value:
                                          '₹${entry.value.toStringAsFixed(2)}',
                                      isRegular: true,
                                    ),
                                  ),
                                ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(height: 1),
                            ),
                            _SummaryRow(
                              label: 'Grand Total',
                              value:
                                  '₹${cartState.totalAmount.toStringAsFixed(2)}',
                              isRegular: false,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Payment Method Section
                      const Text(
                        'Payment Method',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 16),

                      ...List.generate(_paymentMethods.length, (index) {
                        final method = _paymentMethods[index];
                        final isSelected =
                            _selectedPaymentMethod == method['name'];

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedPaymentMethod = method['name'];
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFE2E8F0),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: const Color(
                                      0xFF0F172A,
                                    ).withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    method['icon'],
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        method['name'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFF1A1A1A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        method['subtitle'],
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF0F172A)
                                          : const Color(0xFFCBD5E1),
                                      width: 2,
                                    ),
                                    color: isSelected
                                        ? const Color(0xFF0F172A)
                                        : Colors.white,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Pay Button - Sticky Bottom
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _isProcessing ? null : _processPayment,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          disabledBackgroundColor: const Color(0xFF94A3B8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.lock_outline, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Pay ₹${cartState.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
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
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isRegular;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.isRegular,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isRegular ? 15 : 18,
            fontWeight: isRegular ? FontWeight.w500 : FontWeight.w700,
            color: isRegular
                ? const Color(0xFF64748B)
                : const Color(0xFF1A1A1A),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isRegular ? 15 : 22,
            fontWeight: isRegular ? FontWeight.w600 : FontWeight.w700,
            color: isRegular
                ? const Color(0xFF1A1A1A)
                : const Color(0xFF10B981),
            letterSpacing: isRegular ? 0 : -0.5,
          ),
        ),
      ],
    );
  }
}
