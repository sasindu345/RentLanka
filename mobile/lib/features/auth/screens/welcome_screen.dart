import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/shared/widgets/rentlanka_logo.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _buttonsController;

  late Animation<double> _heroOpacity;
  late Animation<Offset> _heroSlide;

  late Animation<double> _buttonsOpacity;
  late Animation<Offset> _buttonsSlide;

  @override
  void initState() {
    super.initState();

    // Entry animation for tagline and categories
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    _heroOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic),
    );

    _heroSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic),
    );

    // Slide-up overlay animation for bottom actions sheet card (280ms)
    _buttonsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _buttonsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonsController, curve: Curves.easeOut),
    );

    _buttonsSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _buttonsController, curve: Curves.easeOutQuart),
    );

    // Stagger animation sequence: wait for the 700ms Hero transition to complete first
    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted) {
        _heroController.forward().then((_) {
          Future.delayed(const Duration(milliseconds: 60), () {
            if (mounted) _buttonsController.forward();
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _buttonsController.dispose();
    super.dispose();
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required String title,
    required Color startColor,
    required Color endColor,
  }) {
    return Container(
      width: 105,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [startColor, endColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white, // Pure white background to match transparent logo
      body: Stack(
        children: [
          // Background soft wave decoration at the bottom (opacity 6%)
          Positioned.fill(
            child: CustomPaint(
              painter: SubtleWavePainter(
                color: primaryColor.withOpacity(0.06),
              ),
            ),
          ),

          // Main Onboarding Layout Container
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Large brand image logo wrapped in Hero for transition (increased size)
                const Hero(
                  tag: 'brand-logo-hero',
                  child: RentLankaLogo(height: 95, isDarkBackground: false),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Hero Area Subtitle Tagline - fades & slides up smoothly after logo settles
                FadeTransition(
                  opacity: _heroOpacity,
                  child: SlideTransition(
                    position: _heroSlide,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Structured Title and Subtitle
                        Text(
                          'Rent cameras, tools, camping gear & more',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF111827), // Slate-900
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'from trusted people across Sri Lanka.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF6B7280), // Slate-600
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // Curated category row to fill empty space and generate interest
                FadeTransition(
                  opacity: _heroOpacity,
                  child: SlideTransition(
                    position: _heroSlide,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'EXPLORE POPULAR GEAR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF9CA3AF),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildCategoryCard(
                                icon: LucideIcons.camera,
                                title: 'Camera',
                                startColor: const Color(0xFF6366F1),
                                endColor: const Color(0xFF3B82F6),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              _buildCategoryCard(
                                icon: LucideIcons.tent,
                                title: 'Camping',
                                startColor: const Color(0xFF8B5CF6),
                                endColor: const Color(0xFFEC4899),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              _buildCategoryCard(
                                icon: LucideIcons.wrench,
                                title: 'Tools',
                                startColor: const Color(0xFFF59E0B),
                                endColor: const Color(0xFFEF4444),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // Bottom Action Sheet Container with Slide Up Overlay Entrance
                SlideTransition(
                  position: _buttonsSlide,
                  child: FadeTransition(
                    opacity: _buttonsOpacity,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl + 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28), // Rounded sheet corner radius
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, -6), // Shadow floating over the wave
                          ),
                        ],
                        border: const Border(
                          top: BorderSide(
                            color: Color(0xFFF3F4F6), // Subtly divides the sheet boundary
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Subtle handle indicator at the top for overlay look
                          Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Get Started: Primary filled button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              onPressed: () => context.push('/register'),
                              style: FilledButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Sign In: Secondary outlined button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () => context.push('/login'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF111827),
                                side: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Browse as Guest: Ghost link button
                          TextButton(
                            onPressed: () => context.go('/app/explore'),
                            style: TextButton.styleFrom(
                              foregroundColor: primaryColor,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Browse as Guest',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SubtleWavePainter extends CustomPainter {
  final Color color;

  SubtleWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Position wave decoration in the bottom 30% area
    final startY = size.height * 0.72;
    path.moveTo(0, startY);

    // Single smooth quadratic Bezier wave
    path.quadraticBezierTo(
      size.width * 0.5,
      startY - 35,
      size.width,
      startY - 8,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
