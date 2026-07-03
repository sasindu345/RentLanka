import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/api/verification_api.dart';
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_radius.dart';
import 'package:lucide_icons/lucide_icons.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  UserProfile? _user;
  bool _loading = true;

  final _emailTokenController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nicController = TextEditingController();

  String? _activeStep;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _emailTokenController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _nicController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    setState(() => _loading = true);
    try {
      final user = await ref.read(listingsApiProvider).getCurrentUser();
      if (mounted) {
        setState(() {
          _user = user;
          _phoneController.text = user.phoneNumber;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runSendStep({
    required String step,
    required Future<String?> Function() send,
    required TextEditingController controller,
    required String codeLabel,
  }) async {
    setState(() {
      _activeStep = step;
      _error = null;
      _success = null;
    });
    try {
      final code = await send();
      if (mounted) {
        if (code != null && code.isNotEmpty) {
          controller.text = code;
          setState(() => _success = '$codeLabel: $code (auto-filled below)');
        } else {
          setState(() => _success = 'Sent. Restart the API if no code appears, then try again.');
        }
      }
    } on DioException catch (e) {
      if (mounted) setState(() => _error = extractError(e));
    } finally {
      if (mounted) setState(() => _activeStep = null);
    }
  }

  Future<void> _runStep(String step, Future<void> Function() action) async {
    setState(() {
      _activeStep = step;
      _error = null;
      _success = null;
    });
    try {
      await action();
      await _loadUser();
      if (mounted) {
        setState(() => _success = 'Step completed successfully.');
      }
    } on DioException catch (e) {
      if (mounted) setState(() => _error = extractError(e));
    } finally {
      if (mounted) setState(() => _activeStep = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading && _user == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Verification')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final user = _user;
    if (user == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Verification')),
        body: const Center(child: Text('Unable to load profile')),
      );
    }

    final level = user.verificationLevel;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Verification'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(true),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadUser,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.info, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Dev mode: tap Send — the code appears here and auto-fills the field below.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            if (_success != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_success!, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: AppSpacing.lg),
            
            _StepCard(
              title: '1. Email verification',
              subtitle: 'Confirm your email address',
              done: level >= 0,
              child: level >= 0
                  ? null
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton(
                          onPressed: _activeStep == 'email-send'
                              ? null
                              : () => _runSendStep(
                                    step: 'email-send',
                                    controller: _emailTokenController,
                                    codeLabel: 'Email token',
                                    send: () => ref.read(verificationApiProvider).sendEmailToken(),
                                  ),
                          child: Text(_activeStep == 'email-send' ? 'Sending...' : 'Send verification email'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text('Verification token', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _emailTokenController,
                          decoration: const InputDecoration(hintText: 'e.g. 123456'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton(
                          onPressed: _activeStep == 'email-verify'
                              ? null
                              : () => _runStep('email-verify', () async {
                                    await ref.read(verificationApiProvider).verifyEmail(
                                          _emailTokenController.text.trim(),
                                        );
                                  }),
                          child: Text(_activeStep == 'email-verify' ? 'Verifying...' : 'Verify email'),
                        ),
                      ],
                    ),
            ),
            
            _StepCard(
              title: '2. Phone verification',
              subtitle: 'Verify your mobile number with OTP',
              done: level >= 1,
              locked: level < 0,
              child: level >= 1
                  ? null
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Phone number', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _phoneController,
                          decoration: const InputDecoration(hintText: '+94771234567'),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton(
                          onPressed: _activeStep == 'sms-send'
                              ? null
                              : () => _runSendStep(
                                    step: 'sms-send',
                                    controller: _otpController,
                                    codeLabel: 'SMS OTP',
                                    send: () => ref.read(verificationApiProvider).sendSmsOtp(
                                          _phoneController.text.trim(),
                                        ),
                                  ),
                          child: Text(_activeStep == 'sms-send' ? 'Sending...' : 'Send SMS OTP'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text('SMS OTP', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _otpController,
                          decoration: const InputDecoration(hintText: 'e.g. 123456'),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton(
                          onPressed: _activeStep == 'sms-verify'
                              ? null
                              : () => _runStep('sms-verify', () async {
                                    await ref.read(verificationApiProvider).verifySmsOtp(
                                          _otpController.text.trim(),
                                        );
                                  }),
                          child: Text(_activeStep == 'sms-verify' ? 'Verifying...' : 'Verify phone'),
                        ),
                      ],
                    ),
            ),
            
            _StepCard(
              title: '3. NIC verification',
              subtitle: 'Submit your National Identity Card number',
              done: level >= 2,
              locked: level < 1,
              child: level >= 2
                  ? null
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('NIC number', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nicController,
                          decoration: const InputDecoration(hintText: '199012345678'),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Document photo upload comes in a later step. A placeholder URL is sent for now.',
                          style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton(
                          onPressed: _activeStep == 'nic'
                              ? null
                              : () {
                                  final nic = _nicController.text.trim();
                                  if (nic.isEmpty) {
                                    setState(() {
                                      _error = 'Enter your NIC number';
                                      _success = null;
                                    });
                                    return;
                                  }
                                  _runStep('nic', () async {
                                    await ref.read(verificationApiProvider).submitNic(
                                          nicNumber: nic,
                                          documentUrl: 'mock://nic-pending',
                                        );
                                  });
                                },
                          child: Text(_activeStep == 'nic' ? 'Submitting...' : 'Submit NIC'),
                        ),
                      ],
                    ),
            ),
            
            _StepCard(
              title: '4. Face verification',
              subtitle: 'Complete trusted-member face check (mock)',
              done: level >= 3,
              locked: level < 2,
              child: level >= 3
                  ? null
                  : FilledButton(
                      onPressed: _activeStep == 'face'
                          ? null
                          : () => _runStep('face', () async {
                                await ref.read(verificationApiProvider).verifyFace(
                                      'mock-biometric-${DateTime.now().millisecondsSinceEpoch}',
                                    );
                              }),
                      child: Text(_activeStep == 'face' ? 'Scanning...' : 'Simulate face scan'),
                    ),
            ),
            
            if (user.isTrustedUser) ...[
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.shieldCheck, color: theme.colorScheme.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'You are a trusted member',
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool done;
  final bool locked;
  final Widget? child;

  const _StepCard({
    required this.title,
    required this.subtitle,
    required this.done,
    this.locked = false,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  done
                      ? LucideIcons.checkCircle
                      : locked
                          ? LucideIcons.lock
                          : LucideIcons.circle,
                  color: done
                      ? theme.colorScheme.primary
                      : locked
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text(subtitle, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            if (locked && !done) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Complete the previous step first.',
                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            if (!done && !locked && child != null) ...[
              const SizedBox(height: AppSpacing.md),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}
