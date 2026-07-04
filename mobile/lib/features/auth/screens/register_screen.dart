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
      if (mounted) context.go('/app/profile');
    } on DioException catch (e) {
      setState(() => _error = extractError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
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

    return Scaffold(
      backgroundColor: Colors.white, // Consistent White background to match transparent logo
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
              const SizedBox(height: AppSpacing.md),
              
              // Typographic brand logo (increased size, removed background)
              const RentLankaLogo(
                height: 60, 
                isDarkBackground: false,
                blendColor: Colors.white,
              ),
              const SizedBox(height: AppSpacing.lg),
                  
                  // Title changes depending on wizard step
                  Text(
                    _currentStep == 0 ? 'Choose your role' : 'Join RentLanka',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.bold,
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

                  // Animated transition between steps (snappy micro-animation)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.06, 0.0), // Subtle horizontal slide-in
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
                                icon: LucideIcons.store,
                                primaryColor: primaryColor,
                                theme: theme,
                              ),
                              const SizedBox(height: AppSpacing.jumbo),
                              
                              // Next button
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
                                      SizedBox(width: 8),
                                      Icon(LucideIcons.arrowRight, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            key: const ValueKey('step-details'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // First name and Last name side-by-side
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

                              // Email Address
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

                              // Phone Number
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

                              // Password
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
                              
                              // Submit button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: FilledButton(
                                  onPressed: _loading ? null : _submit,
                                  style: FilledButton.styleFrom(
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
  }
}
