import 'package:flutter/material.dart';

/// The Google "G" mark, drawn with a painter so no asset or package is needed.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    void arc(Color color, double start, double sweep) {
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          start,
          sweep,
          false,
        )
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    arc(const Color(0xFFEA4335), -1.3089, 2.0944); // red
    arc(const Color(0xFF4285F4), 0.7854, 2.0944); // blue
    arc(const Color(0xFF34A853), 2.8798, 2.0944); // green
    arc(const Color(0xFFFBBC05), -1.3089, -1.0472); // yellow

    canvas.drawCircle(center, radius * 0.6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
