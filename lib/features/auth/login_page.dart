import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import 'auth_bloc/auth_bloc.dart';
import 'widgets/background_wave.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          Navigator.pushReplacementNamed(context, '/home');
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white, // White background matching mockup
        body: Stack(
          children: [
            // Bottom waves
            const BackgroundWave(),
            
            // Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360), // Max width 360px from design brief
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        
                        // Centered Logo
                        Center(
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 90,
                            height: 90,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Brand name
                        Text(
                          'StockTrack',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNavy, // Navy
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        
                        // Slogan
                        Text(
                          'Smart Stock. Better Business.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.neutralGray, // Slate Gray
                          ),
                        ),
                        const SizedBox(height: 36),
                        
                        // Welcome text
                        Text(
                          'Welcome back!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        Text(
                          'Login with your Google account',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.neutralGray,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Google Sign-In button
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final isLoading = state is AuthLoading;
                            
                            if (isLoading) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                                  ),
                                ),
                              );
                            }
                            
                            return ElevatedButton(
                              onPressed: () {
                                context.read<AuthBloc>().add(GoogleSignInRequested());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen, // Primary Green
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12), // 12px from design brief
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomPaint(
                                    size: const Size(20, 20),
                                    painter: WhiteGoogleIconPainter(),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Sign in with Google',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        // OR Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: AppColors.neutralGray.withOpacity(0.2),
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.neutralGray.withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: AppColors.neutralGray.withOpacity(0.2),
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Secure & Easy card (matches mockup)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4FBF7), // Soft green-grey background
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.lightGreen.withOpacity(0.6),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                color: AppColors.primaryGreen,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Secure & Easy',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryNavy,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "We'll never share your data. Your data is always protected.",
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.neutralGray,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),
                        
                        // Version label (matches mockup)
                        Text(
                          'Version 1.0.0',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.neutralGray.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter to draw a clean white Google logo G
class WhiteGoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final double width = size.width;
    final double height = size.height;
    final double cx = width / 2;
    final double cy = height / 2;
    final double r = width / 2;

    // Draw the outer circular boundary but cut out the right sector
    final Path path = Path()
      ..moveTo(cx, cy)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        0.75, // Start angle (skip bottom-right to top-right sector)
        4.8,  // Sweep angle (draw most of the circle)
        false,
      )
      ..close();
    canvas.drawPath(path, paint);

    // Draw the inner circle to create a ring
    paint.color = AppColors.primaryGreen; // Match parent background color
    canvas.drawCircle(Offset(cx, cy), r * 0.5, paint);

    // Draw the horizontal bar of Google G
    paint.color = Colors.white;
    final Path barPath = Path()
      ..moveTo(cx, cy - r * 0.15)
      ..lineTo(cx + r * 0.95, cy - r * 0.15)
      ..lineTo(cx + r * 0.95, cy + r * 0.15)
      ..lineTo(cx, cy + r * 0.15)
      ..close();
    canvas.drawPath(barPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
