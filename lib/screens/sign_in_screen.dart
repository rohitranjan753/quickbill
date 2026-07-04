import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFFDC2626),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF5B5FEF),
              ),
            );
          }

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo / Icon area
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C0C0F),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        size: 52,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // App Title
                    const Text(
                      'QuickBill',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0C0C0F),
                        letterSpacing: -2,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Scan. Shop. Pay.',
                      style: TextStyle(
                        fontSize: 17,
                        color: Color(0xFF6B6B7A),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),

                    const SizedBox(height: 52),

                    // Feature rows
                    _buildFeatureRow(
                      Icons.check_circle_outline_rounded,
                      'Scan barcodes instantly',
                    ),
                    const SizedBox(height: 14),
                    _buildFeatureRow(
                      Icons.check_circle_outline_rounded,
                      'Build your cart easily',
                    ),
                    const SizedBox(height: 14),
                    _buildFeatureRow(
                      Icons.check_circle_outline_rounded,
                      'Get digital receipts',
                    ),

                    const SizedBox(height: 52),

                    // Google Sign-In Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          context.read<AuthBloc>().add(AuthSignInRequested());
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                            color: Color(0xFFE5E5E3),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/google_logo.png',
                              height: 22,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.login,
                                  color: Color(0xFF2563EB),
                                  size: 22,
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Sign in with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0C0C0F),
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Terms hint
                    Text(
                      'By signing in, you agree to our Terms of Service',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFFA1A1B0),
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFF5B5FEF), size: 18),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF6B6B7A),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
