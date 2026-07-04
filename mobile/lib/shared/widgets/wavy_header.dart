import 'dart:math' as math;
import 'package:flutter/material.dart';

class WavyHeader extends StatefulWidget {
  final double height;
  final Widget? child;

  const WavyHeader({
    super.key,
    required this.height,
    this.child,
  });

  @override
  State<WavyHeader> createState() => _WavyHeaderState();
}

class _WavyHeaderState extends State<WavyHeader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // One-shot entry animation: sweeps smoothly and stops once in its final position
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Smooth background gradient (Indigo brand base with dark navy edge, clean design without cluttering bubbles)
    final darkBlueGradStart = isDark ? const Color(0xFF13113C) : const Color(0xFF4F46E5);
    final darkBlueGradEnd = isDark ? const Color(0xFF0F172A) : const Color(0xFF1E1B4B);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: WavePainter(
            animationValue: _animation.value,
            startColor: darkBlueGradStart,
            endColor: darkBlueGradEnd,
            isDark: isDark,
          ),
          child: Container(
            height: widget.height,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;
  final Color startColor;
  final Color endColor;
  final bool isDark;

  WavePainter({
    required this.animationValue,
    required this.startColor,
    required this.endColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [startColor, endColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Draw main solid background body
    final bgPath = Path()
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(bgPath, paint);

    // Wave 1: Back subtle wave layer (glides dynamically and halts)
    final wave1Paint = Paint()
      ..color = isDark ? const Color(0xFF1E293B).withOpacity(0.2) : Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.fill;
    _drawWave(canvas, size, wave1Paint, amplitude: 14, frequency: 1.1, phaseShift: animationValue * 1.5 * math.pi, heightOffset: 45);

    // Wave 2: Foreground solid wave layer (matches scaffolding background color to split cleanly)
    final wave2Paint = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA)
      ..style = PaintingStyle.fill;
    _drawWave(canvas, size, wave2Paint, amplitude: 10, frequency: 0.85, phaseShift: -animationValue * 1.2 * math.pi + math.pi/2, heightOffset: 25);
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    Paint paint, {
    required double amplitude,
    required double frequency,
    required double phaseShift,
    required double heightOffset,
  }) {
    final path = Path();
    final baseHeight = size.height - heightOffset;
    path.moveTo(0, baseHeight);

    for (double x = 0; x <= size.width; x += 1) {
      final double normalizedX = (x / size.width) * 2 * math.pi * frequency;
      final double y = baseHeight + math.sin(normalizedX + phaseShift) * amplitude;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
