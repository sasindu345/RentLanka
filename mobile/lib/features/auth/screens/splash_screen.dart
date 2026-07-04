import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/shared/widgets/rentlanka_logo.dart';
import 'package:mobile/core/theme/app_spacing.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();
    _startInitFlow();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _startInitFlow() async {
    // Keep splash visible for at least 2 seconds for premium branding loading feel
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final api = ref.read(listingsApiProvider);
      final loggedIn = await api.isLoggedIn();

      if (mounted) {
        if (loggedIn) {
          context.go('/app/explore');
        } else {
          context.go('/welcome');
        }
      }
    } catch (_) {
      if (mounted) context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Clean premium off-white background
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Large brand logo wrapped in Hero for transition (increased size)
              const Hero(
                tag: 'brand-logo-hero',
                child: RentLankaLogo(height: 120),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Elegant thin circular loader (increased size)
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
