import '../utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dashboard_screen.dart';
import 'products_screen.dart';
import 'sales_history_screen.dart';
import 'analytics_screen.dart';
import 'user_management_screen.dart';

class StoreAdminHomeScreen extends StatelessWidget {
  const StoreAdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          );
        }

        final user = authState.user;
        final initial = user.displayName.isNotEmpty
            ? user.displayName[0].toUpperCase()
            : '?';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text(
              'Store Admin',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            iconTheme: const IconThemeData(color: AppColors.primary),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1, color: AppColors.border),
            ),
          ),
          drawer: Drawer(
            backgroundColor: AppColors.surface,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(
                    user.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  accountEmail: Text(
                    user.email,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.70),
                      fontSize: 13,
                    ),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: user.photoURL != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: user.photoURL!,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const CircularProgressIndicator(
                                      color: AppColors.accent),
                              errorWidget: (context, url, error) => Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                  ),
                  otherAccountsPictures: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.store_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _DrawerItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Dashboard',
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Products',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProductsScreen(),
                      ),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.people_outline_rounded,
                  label: 'User Management',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserManagementScreen(),
                      ),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'Sales History',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SalesHistoryScreen(),
                      ),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Analytics',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AnalyticsScreen(),
                      ),
                    );
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(height: 1, thickness: 1, color: AppColors.border),
                ),
                _DrawerItem(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  iconColor: AppColors.error,
                  labelColor: AppColors.error,
                  onTap: () {
                    context.read<AuthBloc>().add(AuthSignOutRequested());
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          body: const DashboardScreen(),
        );
      },
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;
  final Color labelColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppColors.textSecondary,
    this.labelColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: labelColor,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
      horizontalTitleGap: 8,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
