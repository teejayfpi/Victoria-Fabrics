import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Drifting dot field used behind the branded splash screens.
class ParticlesPainter extends CustomPainter {
  ParticlesPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Seeded so the particle field is stable across repaints.
    final random = math.Random(42);

    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 3 + 1;
      final speed = random.nextDouble() * 0.5 + 0.1;
      final angle = random.nextDouble() * math.pi * 2;

      final offset = Offset(
        x + math.sin(angle + progress * 2) * 20 * speed,
        y -
            progress * size.height * speed * 0.3 +
            math.cos(angle + progress * 2) * 15 * speed,
      );

      paint.color = color.withOpacity(0.3 + random.nextDouble() * 0.4);
      canvas.drawCircle(offset, radius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
