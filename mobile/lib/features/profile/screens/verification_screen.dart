import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/api/verification_api.dart';
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/core/theme/app_theme.dart';

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
    if (_loading && _user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = _user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Unable to load profile')));
    }

    final level = user.verificationLevel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(true),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadUser,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dev mode: tap Send — the code appears here and auto-fills the field below.',
                      style: TextStyle(fontSize: 13, color: AppTheme.muted),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            if (_success != null) ...[
              const SizedBox(height: 12),
              Text(_success!, style: const TextStyle(color: AppTheme.primary)),
            ],
            const SizedBox(height: 16),
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
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailTokenController,
                          decoration: const InputDecoration(
                            labelText: 'Verification token',
                          ),
                        ),
                        const SizedBox(height: 12),
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
                        TextField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                            hintText: '+94771234567',
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
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
                        const SizedBox(height: 12),
                        TextField(
                          controller: _otpController,
                          decoration: const InputDecoration(
                            labelText: 'SMS OTP',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
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
                        TextField(
                          controller: _nicController,
                          decoration: const InputDecoration(
                            labelText: 'NIC number',
                            hintText: '199012345678',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Document photo upload comes in a later step. A placeholder URL is sent for now.',
                          style: TextStyle(fontSize: 12, color: AppTheme.muted),
                        ),
                        const SizedBox(height: 12),
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
              const SizedBox(height: 16),
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Text('You are a trusted member', style: TextStyle(fontWeight: FontWeight.bold)),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  done
                      ? Icons.check_circle
                      : locked
                          ? Icons.lock
                          : Icons.radio_button_unchecked,
                  color: done
                      ? AppTheme.primary
                      : locked
                          ? AppTheme.muted
                          : AppTheme.accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                    ],
                  ),
                ),
              ],
            ),
            if (locked && !done) ...[
              const SizedBox(height: 8),
              const Text('Complete the previous step first.', style: TextStyle(fontSize: 12, color: AppTheme.muted)),
            ],
            if (!done && !locked && child != null) ...[
              const SizedBox(height: 16),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}
