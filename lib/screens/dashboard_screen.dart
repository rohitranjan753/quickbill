import '../utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../models/product_model.dart';
import '../models/receipt_model.dart';
import '../services/firestore_service.dart';
import 'add_product_screen.dart';
import 'sales_history_screen.dart';
import 'analytics_screen.dart';
import 'products_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          );
        }

        final user = authState.user;

        if (user.storeId == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: Text('No store associated with this account')),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              'Dashboard',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                tooltip: 'Refresh',
                onPressed: () => setState(() {}),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppColors.border),
            ),
          ),
          body: RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Header — solid near-black container
                  Container(
                    width: double.infinity,
                    color: AppColors.primary,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (user.photoURL != null)
                              ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: user.photoURL!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator(
                                        color: AppColors.accent,
                                      ),
                                  errorWidget: (context, url, error) =>
                                      CircleAvatar(
                                        backgroundColor: AppColors.accent,
                                        radius: 24,
                                        child: Text(
                                          user.displayName[0].toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                ),
                              )
                            else
                              CircleAvatar(
                                backgroundColor: AppColors.accent,
                                radius: 24,
                                child: Text(
                                  user.displayName[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back,',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user.displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Store ID chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.store_outlined,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 15,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Store ID: ${user.storeId}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quick Actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.add_box_outlined,
                                label: 'Add Product',
                                iconBg: AppColors.accentSurface,
                                iconColor: AppColors.accent,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AddProductScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.inventory_outlined,
                                label: 'Products',
                                iconBg: AppColors.surfaceElevated,
                                iconColor: AppColors.textPrimary,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ProductsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.receipt_long_outlined,
                                label: 'Sales',
                                iconBg: AppColors.warningSurface,
                                iconColor: AppColors.warning,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SalesHistoryScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.analytics_outlined,
                                label: 'Analytics',
                                iconBg: AppColors.successSurface,
                                iconColor: AppColors.success,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AnalyticsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Statistics Overview
                  StreamBuilder<List<ProductModel>>(
                    stream: _firestoreService.getStoreProducts(user.storeId!),
                    builder: (context, productSnapshot) {
                      return StreamBuilder<List<ReceiptModel>>(
                        stream: _firestoreService.getStoreSales(user.storeId!),
                        builder: (context, receiptSnapshot) {
                          final products = productSnapshot.data ?? [];
                          final receipts = receiptSnapshot.data ?? [];
                          debugPrint("Receipts: $receipts");

                          final activeProducts = products
                              .where((p) => p.status == ProductStatus.active)
                              .length;
                          final lowStockCount = products
                              .where(
                                (p) =>
                                    p.stockQuantity != null &&
                                    p.stockQuantity! < 10,
                              )
                              .length;
                          final totalInventoryValue = products.fold<double>(
                            0,
                            (sum, p) =>
                                sum + (p.sellingPrice * (p.stockQuantity ?? 0)),
                          );

                          // Calculate today's sales
                          final today = DateTime.now();
                          final todayStart = DateTime(
                            today.year,
                            today.month,
                            // today.day,
                          );
                          final todayReceipts = receipts.where(
                            (r) => r.purchaseDate.isAfter(todayStart),
                          );
                          debugPrint("Today Receipts: $todayReceipts");
                          final todaySales = todayReceipts.fold<double>(
                            0,
                            (sum, r) => sum + r.totalAmount,
                          );
                          final todayTransactions = todayReceipts.length;

                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Overview',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _StatCard(
                                  icon: Icons.trending_up_rounded,
                                  label: "Today's Sales",
                                  value: '₹${todaySales.toStringAsFixed(2)}',
                                  subtitle: '$todayTransactions transactions',
                                  accentColor: AppColors.accent,
                                  iconBg: AppColors.accentSurface,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _StatCard(
                                        icon: Icons.inventory_2_outlined,
                                        label: 'Total Products',
                                        value: '${products.length}',
                                        subtitle: '$activeProducts active',
                                        accentColor: AppColors.info,
                                        iconBg: AppColors.infoSurface,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _StatCard(
                                        icon: Icons.warning_amber_outlined,
                                        label: 'Low Stock',
                                        value: '$lowStockCount',
                                        subtitle: 'items',
                                        accentColor: lowStockCount > 0
                                            ? AppColors.error
                                            : AppColors.textTertiary,
                                        iconBg: lowStockCount > 0
                                            ? AppColors.errorSurface
                                            : AppColors.surfaceElevated,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _StatCard(
                                  icon: Icons.account_balance_wallet_outlined,
                                  label: 'Inventory Value',
                                  value:
                                      '₹${totalInventoryValue.toStringAsFixed(2)}',
                                  subtitle: 'Total stock worth',
                                  accentColor: AppColors.success,
                                  iconBg: AppColors.successSurface,
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // Recent Activity
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Sales',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SalesHistoryScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.accent,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'View All',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        StreamBuilder<List<ReceiptModel>>(
                          stream: _firestoreService.getStoreSales(
                            user.storeId!,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.accent,
                                ),
                              );
                            }

                            final receipts = snapshot.data ?? [];
                            final recentReceipts = receipts.take(5).toList();

                            if (recentReceipts.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: const BoxDecoration(
                                          color: AppColors.surfaceElevated,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.receipt_long_outlined,
                                          size: 28,
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'No recent sales',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return Column(
                              children: recentReceipts.map((receipt) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.accentSurface,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.receipt_outlined,
                                          color: AppColors.accent,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${receipt.items.length} items',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              _formatDateTime(
                                                receipt.purchaseDate,
                                              ),
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '₹${receipt.totalAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (date == today) {
      dateStr = 'Today';
    } else if (date == yesterday) {
      dateStr = 'Yesterday';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$dateStr at $hour:$minute $period';
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color accentColor;
  final Color iconBg;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left colored accent strip
            Container(width: 4, color: accentColor),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: accentColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            value,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
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
}
