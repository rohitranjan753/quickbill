import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:quickbill/utils/upload_dummy_data.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../blocs/cart/cart_bloc.dart';
import '../blocs/cart/cart_state.dart';
import '../models/user_model.dart';
import 'scanner_screen.dart';
import 'cart_screen.dart';
import 'receipts_screen.dart';
import 'register_store_screen.dart';
import 'store_admin_home_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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

        // Route based on user role
        if (user.role == UserRole.storeAdmin) {
          return const StoreAdminHomeScreen();
        } else if (user.role == UserRole.guard) {
          // TODO: Create Guard home screen
          return _buildGuardView(context, user);
        }

        // Default: Customer view
        return _buildCustomerView(context, user);
      },
    );
  }

  Widget _buildCustomerView(BuildContext context, UserModel user) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickBill'),
        elevation: 0,
        actions: [
          BlocBuilder<CartBloc, CartState>(
            builder: (context, cartState) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    },
                  ),
                  if (cartState.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          '${cartState.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
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
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('My Receipts'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReceiptsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            // Register as Store button (only for customers)
            if (user.role == UserRole.customer)
              ListTile(
                leading: const Icon(Icons.store, color: Color(0xFF10B981)),
                title: const Text(
                  'Register as Store',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterStoreScreen(),
                    ),
                  );
                },
              ),
            if (user.role == UserRole.customer) const Divider(),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner, size: 120, color: Colors.blue),
            const SizedBox(height: 40),
            const Text(
              'Ready to Shop?',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Scan product barcodes to add them to your cart',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScannerScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.qr_code_scanner, size: 28),
              label: const Text(
                'Start Scanning',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            UploadDummyDataButton()
          ],
        ),
      ),
    );
  }

  Widget _buildGuardView(BuildContext context, UserModel user) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guard Dashboard'), elevation: 0),
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
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
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
                    Icons.security,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 120,
              color: Color(0xFF3B82F6),
            ),
            const SizedBox(height: 40),
            const Text(
              'Receipt Verification',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Scan customer receipts to verify purchases',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to receipt scanner for guards
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Receipt Scanner - Coming Soon'),
                  ),
                );
              },
              icon: const Icon(Icons.qr_code_scanner, size: 28),
              label: const Text('Scan Receipt', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
