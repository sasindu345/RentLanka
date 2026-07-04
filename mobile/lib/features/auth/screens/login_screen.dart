import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/shared/widgets/rentlanka_logo.dart';
import 'package:mobile/shared/widgets/subtle_wave_painter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscureText = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(listingsApiProvider).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (mounted) context.go('/app/explore');
    } on DioException catch (e) {
      setState(() => _error = extractError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white, // Consistent crisp White background to match transparent logo
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF111827)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              
              // Typographic brand logo styled for light background (increased size, removed background)
              const RentLankaLogo(
                height: 60, 
                isDarkBackground: false,
                blendColor: Colors.white,
              ),
              const SizedBox(height: AppSpacing.lg),
                  
                  Text(
                    'Welcome back',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: const Color(0xFF111827), // Slate-900 heading color
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Sign in to explore gear or manage your rentals.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF4B5563), // Slate-600 subtitle color
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Email Field
                  Text(
                    'Email address',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: 'name@example.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Password Field
                  Text(
                    'Password',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText ? LucideIcons.eye : LucideIcons.eyeOff,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          setState(() => _obscureText = !_obscureText);
                        },
                      ),
                    ),
                    obscureText: _obscureText,
                  ),
                  
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.error.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.alertCircle, color: theme.colorScheme.error, size: 18),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              _error!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Email Sign-In Button
                  SizedBox(
                    width: double.infinity,
                    height: 52, // Explicit 52px height matching design guidelines
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14), // Explicit 14px radius
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign in'),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Text(
                          'or continue with',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Google Sign-In Button (Place-holder for later activation)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Google Sign-In will be configured soon.')),
                        );
                      },
                      icon: SizedBox(
                        width: 18,
                        height: 18,
                        child: CustomPaint(
                          painter: GoogleLogoPainter(),
                        ),
                      ),
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
                      label: const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        );
  }
}

class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double radius = math.min(width, height) / 2;
    
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.4
      ..isAntiAlias = true;

    final Rect rect = Rect.fromCircle(
      center: Offset(width / 2, height / 2),
      radius: radius - paint.strokeWidth / 2,
    );

    // Blue segment
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.75 * math.pi, 0.9 * math.pi, false, paint);

    // Green segment
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.15 * math.pi, 0.7 * math.pi, false, paint);

    // Yellow segment
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 0.85 * math.pi, 0.4 * math.pi, false, paint);

    // Red segment
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 1.25 * math.pi, 0.5 * math.pi, false, paint);

    // Horizontal bar of G
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(width / 2, height / 2 - paint.strokeWidth / 2, radius * 0.9, paint.strokeWidth),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
