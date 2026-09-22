import 'package:flutter/material.dart';

/// Procedural stationery doodle background painter mimicking the Book Vardi website background pattern.
class StationeryBackground extends StatelessWidget {
  final Widget child;

  const StationeryBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAFBFD),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: StationeryDoodlePainter(),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class StationeryDoodlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final fillPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    // Draw repeating subtle stationery doodles (books, stars, pencils, rulers) across screen
    const double spacing = 130.0;
    for (double x = 20; x < size.width; x += spacing) {
      for (double y = 40; y < size.height; y += spacing) {
        canvas.save();
        canvas.translate(x, y);

        // Draw a small book icon
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 22, 16), const Radius.circular(3)),
          paint,
        );
        canvas.drawLine(const Offset(11, 0), const Offset(11, 16), paint);

        // Draw a star nearby
        canvas.drawCircle(const Offset(50, 10), 5, fillPaint);
        canvas.drawCircle(const Offset(50, 10), 5, paint);

        // Draw a pencil/ruler line
        canvas.drawLine(const Offset(5, 50), const Offset(45, 50), paint);
        canvas.drawRect(const Rect.fromLTWH(12, 65, 25, 7), fillPaint);

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
