import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/shared/widgets/rentlanka_logo.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:mobile/core/theme/app_theme.dart';

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
  bool _success = false;

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
      if (mounted) {
        setState(() {
          _success = true;
        });
        await Future.delayed(const Duration(milliseconds: 1600));
        if (mounted) {
          context.go('/app/explore');
        }
      }
    } on DioException catch (e) {
      setState(() => _error = extractError(e));
    } finally {
      if (mounted && !_success) setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final googleSignIn = GoogleSignIn(scopes: ['email']);
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _loading = false);
        return; // User cancelled
      }

      final googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      String? role;
      String? returnedRole;
      bool completed = false;

      while (!completed) {
        try {
          returnedRole = await ref.read(listingsApiProvider).loginWithGoogle(
                idToken: idToken,
                email: googleUser.email,
                firstName: googleUser.displayName?.split(' ').first ?? 'Google',
                lastName: googleUser.displayName?.split(' ').skip(1).join(' ') ?? 'User',
                role: role,
              );
          completed = true;
        } on DioException catch (e) {
          final errStr = extractError(e);
          if (errStr.contains('role (Renter or Owner) is required')) {
            if (!mounted) return;
            final selectedRole = await showDialog<String>(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Choose Your Role'),
                  content: const Text(
                    'No RentLanka account is registered with this Google email yet. Please choose your role to sign up:',
                  ),
                  actions: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context, 'Renter'),
                      child: const Text('Renter'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, 'Owner'),
                      child: const Text('Owner'),
                    ),
                  ],
                );
              },
            );

            if (selectedRole == null) {
              setState(() => _loading = false);
              return;
            }
            role = selectedRole;
          } else {
            rethrow;
          }
        }
      }

      if (mounted) {
        setState(() {
          _success = true;
        });
        await Future.delayed(const Duration(milliseconds: 1600));
        if (mounted) {
          if (returnedRole == 'Owner') {
            context.go('/app/owner');
          } else {
            context.go('/app/explore');
          }
        }
      }
    } on DioException catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      setState(() => _error = extractError(e));
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      setState(() => _error = 'Google Sign-In failed: $e');
    } finally {
      if (mounted && !_success) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final primaryColor = theme.colorScheme.primary;

          final scaffold = Scaffold(
            backgroundColor: Colors.white,
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
              const SizedBox(height: AppSpacing.sm),
              
              // Typographic brand logo styled for light background
              const RentLankaLogo(
                height: 52, 
                isDarkBackground: false,
                blendColor: Colors.white,
              ),
              const SizedBox(height: AppSpacing.md),
              
              Text(
                'Welcome back',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: const Color(0xFF111827), // Slate-900 heading color
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
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
                    backgroundColor: primaryColor,
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

              // Google Sign-In Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _handleGoogleSignIn,
                  icon: Image.asset(
                    'assets/images/google-logo.png',
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
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

    if (_success) {
      return Stack(
        children: [
          scaffold,
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: Container(
                  color: const Color(0xFFEEF2FF).withOpacity(0.85), // Theme-aligned semi-transparent background
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF22C55E).withOpacity(0.12),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              LucideIcons.check,
                              color: Color(0xFF16A34A),
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Welcome Back!',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              fontSize: 26,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'You have successfully signed in to your account.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF475569),
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 48),
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)), // App Indigo primary loader
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

          return scaffold;
        },
      ),
    );
  }
}
