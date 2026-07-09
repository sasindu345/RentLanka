import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/api/verification_api.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_radius.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SignupVerificationScreen extends ConsumerStatefulWidget {
  final String? devToken;

  const SignupVerificationScreen({
    super.key,
    this.devToken,
  });

  @override
  ConsumerState<SignupVerificationScreen> createState() =>
      _SignupVerificationScreenState();
}

class _SignupVerificationScreenState
    extends ConsumerState<SignupVerificationScreen> {
  final _tokenController = TextEditingController();
  bool _loading = false;
  bool _isVerified = false;
  String? _error;
  String? _success;
  String? _activeDevToken;

  @override
  void initState() {
    super.initState();
    _activeDevToken = widget.devToken;
    if (_activeDevToken != null) {
      // Printed to terminal console only as requested
      debugPrint('========================================================');
      debugPrint('DEVELOPMENT EMAIL VERIFICATION TOKEN: $_activeDevToken');
      debugPrint('========================================================');
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => _error = 'Please enter the verification code.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      await ref.read(verificationApiProvider).verifyEmail(token);
      setState(() {
        _isVerified = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Invalid verification code. Please check and try again.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendToken() async {
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      final newDevToken =
          await ref.read(verificationApiProvider).sendEmailToken();
      setState(() {
        _success = 'A new verification code has been sent to your email.';
        if (newDevToken != null) {
          _activeDevToken = newDevToken;
          debugPrint('========================================================');
          debugPrint('DEVELOPMENT EMAIL VERIFICATION TOKEN (RESEND): $_activeDevToken');
          debugPrint('========================================================');
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to resend verification code. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If verification succeeded, show the premium welcome success screen
    if (_isVerified) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                // Large animated-looking Success Checkmark
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.partyPopper,
                      size: 80,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Welcome to RentLanka! 🎉',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Your email has been verified successfully. Your account is active and you are ready to find premium rental equipment or publish your own items.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => context.go('/app/explore'),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      );
    }

    // Default Code Verification input screen
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Email Verification'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => context.go('/welcome'),
            child: const Text('Cancel'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                LucideIcons.mailCheck,
                size: 80,
                color: Color(0xFF0D9488),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Verify your Email',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'We have sent a verification code to your registered email address. Please enter the 6-character code below to verify your account.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (_success != null) ...[
                Text(
                  _success!,
                  style: const TextStyle(
                    color: Color(0xFF0D9488),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              Text(
                'Verification Code',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  hintText: 'e.g. 8A5B2C',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              
              FilledButton(
                onPressed: _loading ? null : _verify,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Verify Email'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              
              OutlinedButton(
                onPressed: _loading ? null : _resendToken,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Resend Code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
