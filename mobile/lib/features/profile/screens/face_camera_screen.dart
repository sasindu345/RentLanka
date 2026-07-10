import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_radius.dart';

class FaceCameraScreen extends StatefulWidget {
  const FaceCameraScreen({super.key});

  @override
  State<FaceCameraScreen> createState() => _FaceCameraScreenState();
}

class _FaceCameraScreenState extends State<FaceCameraScreen> with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  File? _imageFile;
  bool _scanning = false;
  late AnimationController _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _captureFace() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 600,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
          _scanning = true;
        });

        // Simulate a sleek biometric node verification scanning animation for 1.5 seconds
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          setState(() {
            _scanning = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching camera: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Biometric Verification'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Camera View or Oval Photo display
                if (_imageFile == null)
                  Container(
                    width: double.infinity,
                    color: Colors.grey[900],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.camera, color: Colors.white.withOpacity(0.4), size: 48),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Prepare for Face Scan',
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'We will use your front camera to verify identity',
                          style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  )
                else
                  Positioned.fill(
                    child: Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                    ),
                  ),

                // 2. Custom Painted Oval Guide Frame Overlay Mask
                Positioned.fill(
                  child: CustomPaint(
                    painter: _OvalMaskPainter(
                      borderColor: _scanning
                          ? theme.colorScheme.primary
                          : (_imageFile != null ? Colors.green : Colors.white.withOpacity(0.8)),
                    ),
                  ),
                ),

                // 3. Scanning Animation Bar
                if (_scanning)
                  AnimatedBuilder(
                    animation: _scannerController,
                    builder: (context, child) {
                      final topOffset = size.height * 0.25 + (_scannerController.value * size.height * 0.35);
                      return Positioned(
                        top: topOffset,
                        left: size.width * 0.15,
                        right: size.width * 0.15,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                // 4. Instructional Banner
                Positioned(
                  top: AppSpacing.lg,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Text(
                      _scanning
                          ? 'ANALYZING FACIAL FEATURES...'
                          : (_imageFile != null ? 'SCAN COMPLETED' : 'ALIGN FACE WITHIN OVAL'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Controls Box
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
            color: Colors.black,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_imageFile == null)
                  FilledButton.icon(
                    onPressed: _captureFace,
                    icon: const Icon(LucideIcons.scan),
                    label: const Text('Start Face Scan'),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _captureFace,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white30),
                          ),
                          icon: const Icon(LucideIcons.refreshCw, size: 18),
                          label: const Text('Retake'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _scanning
                              ? null
                              : () {
                                  Navigator.pop(context, _imageFile!.path);
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          icon: const Icon(LucideIcons.check, size: 18),
                          label: const Text('Confirm'),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Make sure your face is clearly lit and visible without hats or glasses.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OvalMaskPainter extends CustomPainter {
  final Color borderColor;

  _OvalMaskPainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final maskPaint = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    final w = size.width;
    final h = size.height;

    // Build the path representing the background mask excluding the oval face frame
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, w, h));

    // The oval geometry centered
    final ovalRect = Rect.fromCenter(
      center: Offset(w / 2, h * 0.45),
      width: w * 0.65,
      height: h * 0.45,
    );
    final ovalPath = Path()..addOval(ovalRect);

    // Subtract the oval from the background rect
    final maskPath = Path.combine(PathOperation.difference, backgroundPath, ovalPath);

    canvas.drawPath(maskPath, maskPaint);
    canvas.drawOval(ovalRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
