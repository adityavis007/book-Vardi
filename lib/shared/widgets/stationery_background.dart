import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Rich School Doodle Pattern Background matching the user's uploaded notebook doodle image.
class StationeryBackground extends StatelessWidget {
  final Widget child;

  const StationeryBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF9FAFC), // Light notebook paper tint
      child: Stack(
        children: [
          // Lined paper + rich stationery doodle canvas
          Positioned.fill(
            child: CustomPaint(
              painter: NotebookDoodlePainter(),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class NotebookDoodlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw subtle horizontal notebook lines
    final linePaint = Paint()
      ..color = const Color(0xFFCBD5E1).withValues(alpha: 0.35)
      ..strokeWidth = 0.8;

    const double lineSpacing = 24.0;
    for (double y = lineSpacing; y < size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // 2. Draw colorful pastel school doodles (backpack, bus, clock, scissors, etc.)
    final doodleColors = [
      const Color(0xFF8B5CF6).withValues(alpha: 0.22), // Purple tint
      const Color(0xFF0EA5E9).withValues(alpha: 0.22), // Blue tint
      const Color(0xFFEC4899).withValues(alpha: 0.22), // Pink tint
      const Color(0xFFF59E0B).withValues(alpha: 0.22), // Amber tint
      const Color(0xFF10B981).withValues(alpha: 0.22), // Emerald tint
    ];

    const double colSpacing = 140.0;
    const double rowSpacing = 160.0;
    int colorIdx = 0;

    for (double x = 10; x < size.width + colSpacing; x += colSpacing) {
      for (double y = 20; y < size.height + rowSpacing; y += rowSpacing) {
        final strokePaint = Paint()
          ..color = doodleColors[colorIdx % doodleColors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3;

        final fillPaint = Paint()
          ..color = doodleColors[colorIdx % doodleColors.length].withValues(alpha: 0.08)
          ..style = PaintingStyle.fill;

        canvas.save();
        canvas.translate(x, y);

        final int doodleType = (colorIdx) % 6;
        switch (doodleType) {
          case 0:
            // Backpack
            _drawBackpack(canvas, strokePaint, fillPaint);
            break;
          case 1:
            // School Bus
            _drawSchoolBus(canvas, strokePaint, fillPaint);
            break;
          case 2:
            // Alarm Clock
            _drawAlarmClock(canvas, strokePaint);
            break;
          case 3:
            // Scissors & Glasses
            _drawScissorsAndGlasses(canvas, strokePaint);
            break;
          case 4:
            // Books & Pencil
            _drawBooksAndPencil(canvas, strokePaint, fillPaint);
            break;
          case 5:
            // Calculator & Star
            _drawCalculatorAndStar(canvas, strokePaint, fillPaint);
            break;
        }

        canvas.restore();
        colorIdx++;
      }
    }
  }

  void _drawBackpack(Canvas canvas, Paint stroke, Paint fill) {
    const rect = Rect.fromLTWH(0, 10, 32, 38);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), stroke);
    // Top handle loop
    canvas.drawArc(const Rect.fromLTWH(8, 0, 16, 14), math.pi, math.pi, false, stroke);
    // Front pocket
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6, 26, 20, 16), const Radius.circular(4)), stroke);
  }

  void _drawSchoolBus(Canvas canvas, Paint stroke, Paint fill) {
    const busRect = Rect.fromLTWH(0, 0, 48, 26);
    canvas.drawRRect(RRect.fromRectAndRadius(busRect, const Radius.circular(5)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(busRect, const Radius.circular(5)), stroke);
    // Windows
    for (double wx = 6; wx <= 34; wx += 10) {
      canvas.drawRect(Rect.fromLTWH(wx, 5, 7, 8), stroke);
    }
    // Wheels
    canvas.drawCircle(const Offset(10, 26), 5, stroke);
    canvas.drawCircle(const Offset(38, 26), 5, stroke);
  }

  void _drawAlarmClock(Canvas canvas, Paint stroke) {
    canvas.drawCircle(const Offset(18, 18), 14, stroke);
    // Ears
    canvas.drawArc(const Rect.fromLTWH(2, 0, 10, 10), math.pi, math.pi, false, stroke);
    canvas.drawArc(const Rect.fromLTWH(24, 0, 10, 10), math.pi, math.pi, false, stroke);
    // Clock hands
    canvas.drawLine(const Offset(18, 18), const Offset(18, 10), stroke);
    canvas.drawLine(const Offset(18, 18), const Offset(24, 18), stroke);
  }

  void _drawScissorsAndGlasses(Canvas canvas, Paint stroke) {
    // Glasses
    canvas.drawCircle(const Offset(10, 10), 8, stroke);
    canvas.drawCircle(const Offset(28, 10), 8, stroke);
    canvas.drawLine(const Offset(18, 10), const Offset(20, 10), stroke);
    // Scissors
    canvas.drawLine(const Offset(5, 30), const Offset(25, 45), stroke);
    canvas.drawLine(const Offset(25, 30), const Offset(5, 45), stroke);
    canvas.drawCircle(const Offset(5, 30), 4, stroke);
    canvas.drawCircle(const Offset(5, 45), 4, stroke);
  }

  void _drawBooksAndPencil(Canvas canvas, Paint stroke, Paint fill) {
    // Stacked books
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 36, 10), const Radius.circular(2)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 36, 10), const Radius.circular(2)), stroke);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, 12, 32, 10), const Radius.circular(2)), stroke);
    // Pencil
    canvas.drawLine(const Offset(0, 30), const Offset(30, 30), stroke);
    canvas.drawLine(const Offset(30, 30), const Offset(36, 33), stroke);
    canvas.drawLine(const Offset(36, 33), const Offset(30, 36), stroke);
    canvas.drawLine(const Offset(30, 36), const Offset(0, 36), stroke);
  }

  void _drawCalculatorAndStar(Canvas canvas, Paint stroke, Paint fill) {
    // Calculator
    const calcRect = Rect.fromLTWH(0, 0, 24, 32);
    canvas.drawRRect(RRect.fromRectAndRadius(calcRect, const Radius.circular(4)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(calcRect, const Radius.circular(4)), stroke);
    // Display screen
    canvas.drawRect(const Rect.fromLTWH(4, 4, 16, 7), stroke);
    // Buttons grid
    canvas.drawCircle(const Offset(7, 16), 1.5, stroke);
    canvas.drawCircle(const Offset(12, 16), 1.5, stroke);
    canvas.drawCircle(const Offset(17, 16), 1.5, stroke);
    canvas.drawCircle(const Offset(7, 23), 1.5, stroke);
    canvas.drawCircle(const Offset(12, 23), 1.5, stroke);
    canvas.drawCircle(const Offset(17, 23), 1.5, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
