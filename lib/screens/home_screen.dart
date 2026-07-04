import '../utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../models/user_model.dart';
import '../models/store_model.dart';
import '../services/firestore_service.dart';
import 'store_admin_home_screen.dart';
import 'guard_receipt_scanner_screen.dart';
import 'guard_scanned_receipts_screen.dart';
import 'customer_home_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
          );
        }

        final user = authState.user;

        if (user.role == UserRole.storeAdmin) {
          return const StoreAdminHomeScreen();
        } else if (user.role == UserRole.guard) {
          return _GuardHomeView(user: user);
        }

        return const CustomerHomeScreen();
      },
    );
  }
}

// Guard Home View as separate widget
class _GuardHomeView extends StatelessWidget {
  final UserModel user;

  const _GuardHomeView({required this.user});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Guard Dashboard',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
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
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              accountEmail: Text(
                user.email,
                style: const TextStyle(color: Color(0xFFA1A1B0)),
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
                              const CircularProgressIndicator(),
                          errorWidget: (context, url, error) => Text(
                            user.displayName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 40,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        user.displayName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
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
                    color: Colors.white.withValues(alpha: 0.15),
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
              leading: const Icon(Icons.dashboard_outlined, color: AppColors.textSecondary),
              title: const Text(
                'Dashboard',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: AppColors.textSecondary),
              title: const Text(
                'Scanned Receipts',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GuardScannedReceiptsScreen(
                      guardId: user.uid,
                      storeId: user.storeId ?? '',
                    ),
                  ),
                );
              },
            ),
            Divider(color: AppColors.divider, height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                context.read<AuthBloc>().add(AuthSignOutRequested());
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<StoreModel?>(
        stream: user.storeId != null
            ? Stream.fromFuture(firestoreService.getStore(user.storeId!))
            : Stream.value(null),
        builder: (context, storeSnapshot) {
          return StreamBuilder(
            stream: firestoreService.getActiveAttendance(user.uid),
            builder: (context, attendanceSnapshot) {
              final activeAttendance = attendanceSnapshot.data;

              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome header
                      const Text(
                        'Welcome Back,',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.8,
                        ),
                      ),
                      if (storeSnapshot.hasData && storeSnapshot.data != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentSurface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.store_outlined,
                                  size: 14,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  storeSnapshot.data!.name,
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Attendance Card
                      _AttendanceCard(
                        guardId: user.uid,
                        storeId: user.storeId ?? '',
                        activeAttendance: activeAttendance,
                      ),

                      const SizedBox(height: 20),

                      // Main Scanner Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.qr_code_scanner,
                                size: 64,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Receipt Verification',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Scan customer receipt QR codes to verify purchases before exit',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.65),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (activeAttendance?.isActive == null ||
                                      activeAttendance!.isActive == false) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please check in before scanning receipts',
                                        ),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          GuardReceiptScannerScreen(
                                            guardId: user.uid,
                                            storeId: user.storeId ?? '',
                                          ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.qr_code_scanner,
                                  size: 22,
                                  color: AppColors.primary,
                                ),
                                label: const Text(
                                  'Scan Receipt',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Quick Stats Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              icon: Icons.verified_outlined,
                              title: 'View History',
                              subtitle: 'See all scans',
                              iconColor: AppColors.success,
                              iconBg: AppColors.successSurface,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        GuardScannedReceiptsScreen(
                                          guardId: user.uid,
                                          storeId: user.storeId ?? '',
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              icon: Icons.info_outline_rounded,
                              title: 'Instructions',
                              subtitle: 'How to verify',
                              iconColor: AppColors.warning,
                              iconBg: AppColors.warningSurface,
                              onTap: () {
                                _showInstructionsDialog(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showInstructionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.accent),
            SizedBox(width: 10),
            Text(
              'Verification Instructions',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _InstructionStep(
              number: '1',
              text: 'Ask customer to show their receipt QR code',
            ),
            SizedBox(height: 12),
            _InstructionStep(number: '2', text: 'Tap "Scan Receipt" button'),
            SizedBox(height: 12),
            _InstructionStep(number: '3', text: 'Point camera at the QR code'),
            SizedBox(height: 12),
            _InstructionStep(
              number: '4',
              text: 'Verify receipt details match items in cart',
            ),
            SizedBox(height: 12),
            _InstructionStep(
              number: '5',
              text: 'Allow customer to exit if verified',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// Attendance Card Widget
class _AttendanceCard extends StatelessWidget {
  final String guardId;
  final String storeId;
  final dynamic activeAttendance;

  const _AttendanceCard({
    required this.guardId,
    required this.storeId,
    this.activeAttendance,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final isCheckedIn = activeAttendance != null;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isCheckedIn ? AppColors.successSurface : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCheckedIn
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCheckedIn
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCheckedIn ? Icons.timer_rounded : Icons.timer_off_rounded,
                  color: isCheckedIn ? AppColors.success : AppColors.textSecondary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCheckedIn ? 'On Duty' : 'Off Duty',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isCheckedIn ? AppColors.success : AppColors.textSecondary,
                      ),
                    ),
                    if (isCheckedIn)
                      StreamBuilder(
                        stream: Stream.periodic(const Duration(seconds: 1)),
                        builder: (context, snapshot) {
                          final duration = activeAttendance.workDuration;
                          final hours = duration?.inHours ?? 0;
                          final minutes = (duration?.inMinutes ?? 0) % 60;
                          final seconds = (duration?.inSeconds ?? 0) % 60;
                          return Text(
                            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  if (isCheckedIn) {
                    await firestoreService.checkOutGuard(activeAttendance.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Checked out successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } else {
                    await firestoreService.checkInGuard(guardId, storeId);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Checked in successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              icon: Icon(
                isCheckedIn ? Icons.logout : Icons.login,
                size: 20,
                color: isCheckedIn ? AppColors.error : AppColors.success,
              ),
              label: Text(
                isCheckedIn ? 'Check Out' : 'Check In',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final String number;
  final String text;

  const _InstructionStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
