import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/api/file_api.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/api/verification_api.dart';
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_radius.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/features/profile/screens/face_camera_screen.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  UserProfile? _user;
  bool _loading = true;

  final _emailTokenController = TextEditingController();
  final _nicController = TextEditingController();

  final _picker = ImagePicker();
  File? _nicFrontImage;
  File? _nicBackImage;
  File? _faceCaptureImage;
  bool _submittingKyc = false;

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
          if (user.nicNumber != null) {
            _nicController.text = user.nicNumber!;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickNicImage(bool isFront) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          if (isFront) {
            _nicFrontImage = File(picked.path);
          } else {
            _nicBackImage = File(picked.path);
          }
        });
      }
    } catch (e) {
      setState(() => _error = 'Failed to pick image: $e');
    }
  }

  Future<void> _launchFaceCamera() async {
    final resultPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const FaceCameraScreen()),
    );
    if (resultPath != null) {
      setState(() {
        _faceCaptureImage = File(resultPath);
      });
    }
  }

  Future<void> _submitKycData() async {
    final nic = _nicController.text.trim();
    if (nic.isEmpty) {
      setState(() => _error = 'Please enter your NIC number');
      return;
    }
    if (_nicFrontImage == null || _nicBackImage == null) {
      setState(() => _error = 'Please upload both front and back photos of your NIC');
      return;
    }
    if (_faceCaptureImage == null) {
      setState(() => _error = 'Please perform the face scan step');
      return;
    }

    setState(() {
      _submittingKyc = true;
      _error = null;
      _success = null;
    });

    try {
      final fileApi = ref.read(fileApiProvider);
      final verificationApi = ref.read(verificationApiProvider);

      final frontUrl = await fileApi.uploadKycDocument(_nicFrontImage!.path);
      final backUrl = await fileApi.uploadKycDocument(_nicBackImage!.path);
      final faceUrl = await fileApi.uploadKycDocument(_faceCaptureImage!.path);

      await verificationApi.submitKyc(
        nicNumber: nic,
        nicFrontUrl: frontUrl,
        nicBackUrl: backUrl,
        faceCaptureUrl: faceUrl,
      );

      await _loadUser();
      setState(() {
        _success = 'KYC Verification submitted successfully. Pending Admin review.';
      });
    } on DioException catch (e) {
      setState(() => _error = extractError(e));
    } finally {
      setState(() => _submittingKyc = false);
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
          setState(() => _success = 'Sent. Check your inbox.');
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

    final emailVerified = user.verificationLevel >= 0;
    final isPendingReview = user.kycStatus == 'PendingApproval';
    final isApproved = user.kycStatus == 'Approved' || user.verificationLevel >= 3;
    final isRejected = user.kycStatus == 'Rejected';

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
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            if (_success != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_success!, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: AppSpacing.lg),

            // 1. Email step
            _StepCard(
              title: '1. Email verification',
              subtitle: 'Confirm your email address',
              done: emailVerified,
              child: emailVerified
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

            // KYC Status Boxes
            if (isPendingReview) ...[
              Card(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      Icon(LucideIcons.hourglass, color: theme.colorScheme.primary, size: 36),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Verification Pending Approval',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your documents and face capture have been submitted for admin verification. You will be updated once reviewed.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (isApproved) ...[
              Card(
                color: Colors.green.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  side: BorderSide(color: Colors.green.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      const Icon(LucideIcons.shieldCheck, color: Colors.green, size: 36),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'You are a Trusted Member',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your identity has been fully verified. You can now rent items or list equipment on RentLanka.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              if (isRejected) ...[
                Card(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    side: BorderSide(color: theme.colorScheme.error.withOpacity(0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        Icon(LucideIcons.xCircle, color: theme.colorScheme.error, size: 36),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'KYC Verification Rejected',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.error),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.kycRejectionReason ?? 'Submitted documents do not match.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // 2. Identity submission (NIC + Face Capture combined)
              _StepCard(
                title: '2. Identity & Biometric Verification',
                subtitle: 'Submit NIC and Face biometric capture for Admin review',
                done: false,
                locked: !emailVerified,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('NIC Number', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nicController,
                      decoration: const InputDecoration(hintText: 'e.g. 199012345678'),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // NIC Front Image Button
                    Text('NIC Front Side', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () => _pickNicImage(true),
                      icon: const Icon(LucideIcons.image),
                      label: Text(_nicFrontImage != null ? 'NIC Front Selected (Change)' : 'Upload NIC Front Image'),
                    ),
                    if (_nicFrontImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'File: ${_nicFrontImage!.path.split('/').last}',
                          style: theme.textTheme.labelMedium?.copyWith(color: Colors.green),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),

                    // NIC Back Image Button
                    Text('NIC Back Side', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () => _pickNicImage(false),
                      icon: const Icon(LucideIcons.image),
                      label: Text(_nicBackImage != null ? 'NIC Back Selected (Change)' : 'Upload NIC Back Image'),
                    ),
                    if (_nicBackImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'File: ${_nicBackImage!.path.split('/').last}',
                          style: theme.textTheme.labelMedium?.copyWith(color: Colors.green),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),

                    // Biometric Face Capture Button
                    Text('Biometric Face Scan', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: _launchFaceCamera,
                      icon: const Icon(LucideIcons.scanFace),
                      label: Text(_faceCaptureImage != null ? 'Face Capture Completed (Retake)' : 'Capture Live Face'),
                    ),
                    if (_faceCaptureImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Captured Face Image Saved',
                          style: theme.textTheme.labelMedium?.copyWith(color: Colors.green),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xl),

                    // Final Submission Button
                    FilledButton.icon(
                      onPressed: _submittingKyc ? null : _submitKycData,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                      ),
                      icon: _submittingKyc
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(LucideIcons.uploadCloud),
                      label: Text(_submittingKyc ? 'Uploading Documents...' : 'Submit Verification'),
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
