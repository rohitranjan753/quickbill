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
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authState.user;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Store Management'),
            elevation: 0,
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(user.displayName),
                  accountEmail: Text(user.email),
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
                                  const CircularProgressIndicator(),
                              errorWidget: (context, url, error) => Text(
                                user.displayName[0].toUpperCase(),
                                style: const TextStyle(fontSize: 40),
                              ),
                            ),
                          )
                        : Text(
                            user.displayName[0].toUpperCase(),
                            style: const TextStyle(fontSize: 40),
                          ),
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                  ),
                  otherAccountsPictures: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.store,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Dashboard'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.inventory),
                  title: const Text('Products'),
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
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('User Management'),
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
                ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: const Text('Sales History'),
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
                ListTile(
                  leading: const Icon(Icons.analytics),
                  title: const Text('Analytics'),
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
                ListTile(
                  leading: const Icon(Icons.store_outlined),
                  title: const Text('Store Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Store Settings - Coming Soon'),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign Out'),
                  onTap: () {
                    context.read<AuthBloc>().add(AuthSignOutRequested());
                  },
                ),
              ],
            ),
          ),
          body: const DashboardScreen(),
        );
      },
    );
  }
}
