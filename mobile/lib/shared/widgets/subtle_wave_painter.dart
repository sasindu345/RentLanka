import 'package:flutter/material.dart';

class SubtleWavePainter extends CustomPainter {
  final Color color;

  SubtleWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Position wave decoration in the bottom 30% area
    final startY = size.height * 0.72;
    path.moveTo(0, startY);

    // Single smooth quadratic Bezier wave
    path.quadraticBezierTo(
      size.width * 0.5,
      startY - 35,
      size.width,
      startY - 8,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
