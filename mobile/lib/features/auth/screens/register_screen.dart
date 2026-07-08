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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _role = 'Renter'; // 'Renter' or 'Owner'
  int _currentStep = 0; // 0 for Role Selection, 1 for User Details Form
  bool _loading = false;
  bool _obscureText = true;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(listingsApiProvider).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            role: _role,
          );
      if (mounted) {
        setState(() {
          _success = true;
        });
        await Future.delayed(const Duration(milliseconds: 1600));
        if (mounted) {
          context.go('/app/profile');
        }
      }
    } on DioException catch (e) {
      setState(() => _error = extractError(e));
    } finally {
      if (mounted && !_success) setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogleSignIn(String? role) async {
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

      final returnedRole = await ref.read(listingsApiProvider).loginWithGoogle(
            idToken: idToken,
            email: googleUser.email,
            firstName: googleUser.displayName?.split(' ').first ?? 'Google',
            lastName: googleUser.displayName?.split(' ').skip(1).join(' ') ?? (role ?? 'User'),
            role: role,
          );

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

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String description,
    required IconData icon,
    required Color primaryColor,
    required ThemeData theme,
  }) {
    final isSelected = _role == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          _role = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : const Color(0xFFE5E7EB),
            width: 1.5, // Constant width to prevent layout shifts
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor.withOpacity(0.1) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? primaryColor : const Color(0xFF4B5563),
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6B7280),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? primaryColor : const Color(0xFFD1D5DB),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final scaffold = Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF111827)),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep = 0;
              });
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              
              const RentLankaLogo(
                height: 52, 
                isDarkBackground: false,
                blendColor: Colors.white,
              ),
              const SizedBox(height: AppSpacing.md),
              
              Text(
                _currentStep == 0 ? 'Choose your role' : 'Join RentLanka',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                _currentStep == 0
                    ? 'Select how you want to use the platform to customize your experience.'
                    : 'Fill in your details below to create your secure account.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.06, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: _currentStep == 0
                    ? Column(
                        key: const ValueKey('step-role'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRoleCard(
                            role: 'Renter',
                            title: 'I want to rent equipment',
                            description: 'Rent cameras, tools, camping gear & more.',
                            icon: LucideIcons.shoppingBag,
                            primaryColor: primaryColor,
                            theme: theme,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildRoleCard(
                            role: 'Owner',
                            title: 'I want to host equipment',
                            description: 'Earn money by listing your equipment.',
                            icon: LucideIcons.home,
                            primaryColor: primaryColor,
                            theme: theme,
                          ),
                          const SizedBox(height: AppSpacing.jumbo),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              onPressed: () {
                                setState(() {
                                  _currentStep = 1;
                                });
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Next Step',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
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
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: _loading ? null : () => _handleGoogleSignIn(_role),
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
                      )
                    : Column(
                        key: const ValueKey('step-details'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'First name',
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    TextField(
                                      controller: _firstNameController,
                                      decoration: const InputDecoration(hintText: 'John'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Last name',
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    TextField(
                                      controller: _lastNameController,
                                      decoration: const InputDecoration(hintText: 'Doe'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),

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
                            decoration: const InputDecoration(hintText: 'name@example.com'),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          Text(
                            'Phone number',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextField(
                            controller: _phoneController,
                            decoration: const InputDecoration(hintText: '+94 77 123 4567'),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: AppSpacing.lg),

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
                              hintText: 'Minimum 8 characters',
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

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              onPressed: _loading ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
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
                                  : const Text(
                                      'Create account',
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
                  color: const Color(0xFFEEF2FF).withOpacity(0.85),
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
                            'Account Created!',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              fontSize: 26,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Welcome to RentLanka! Your account is ready to use.',
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
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
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
  }
}
