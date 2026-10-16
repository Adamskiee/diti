import 'dart:math' as math;
import 'package:flutter/material.dart';

class CircularTimerDial extends StatelessWidget {
  final double progress;
  final String formattedTime;
  final Color primaryColor;
  final Color backgroundColor;

  const CircularTimerDial({
    super.key,
    required this.progress,
    required this.formattedTime,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(260, 260),
            painter: _DialPainter(
              progress: progress,
              primaryColor: primaryColor,
              backgroundColor: backgroundColor,
            ),
          ),
          Text(
            formattedTime,
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color backgroundColor;

  _DialPainter({
    required this.progress,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 14;

    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_DialPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.backgroundColor != backgroundColor;
}
