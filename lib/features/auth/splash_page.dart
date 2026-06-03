import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import 'auth_bloc/auth_bloc.dart';
import 'widgets/background_wave.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

    // Trigger session status check after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authBloc = context.read<AuthBloc>();
        if (authBloc.state is Authenticated || 
            authBloc.state is Unauthenticated || 
            authBloc.state is AuthFailure) {
          _navigate(authBloc.state);
        } else {
          authBloc.add(AppStarted());
        }
      }
    });
  }

  bool _hasNavigated = false;

  Future<void> _navigate(AuthState state) async {
    if (_hasNavigated) return;
    _hasNavigated = true;

    // Wait at least 2 seconds so the splash screen feels smooth and matches standard transitions
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    if (state is Authenticated) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (state is Unauthenticated || state is AuthFailure) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated || state is Unauthenticated || state is AuthFailure) {
          _navigate(state);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white, // White background from mockup
        body: Stack(
          children: [
            // Overlapping bottom waves
            const BackgroundWave(),
            
            // Content
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Brand Logo (centered)
                      Image.asset(
                        'assets/images/logo.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 12),
                      
                      // StockTrack Brand Title
                      Text(
                        'StockTrack',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy, // Navy color
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // Slogan
                      Text(
                        'Smart Stock. Better Business.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.neutralGray, // Slate Gray
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                    ],
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
