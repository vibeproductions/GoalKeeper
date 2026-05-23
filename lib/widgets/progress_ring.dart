// lib/widgets/progress_ring.dart
// Activity-ring progress indicators — Flutter CustomPainter equivalent of ProgressRingView.swift

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:goalkeeper_flutter/models/models.dart';
import 'package:goalkeeper_flutter/theme/app_theme.dart';

// ─── Single Ring ──────────────────────────────────────────────────────────────

class ProgressRing extends StatelessWidget {
  final double progress;   // 0.0 – 1.0
  final Color color;
  final double strokeWidth;
  final double size;

  const ProgressRing({
    super.key,
    required this.progress,
    required this.color,
    this.strokeWidth = 10,
    this.size = 70,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(progress: clamped, color: color, strokeWidth: strokeWidth),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _RingPainter({required this.progress, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Progress arc with gradient
    final rect   = Rect.fromCircle(center: center, radius: radius);
    final shader = SweepGradient(
      startAngle: -pi / 2,
      endAngle:   -pi / 2 + 2 * pi * progress,
      colors:     [color, color.withOpacity(0.55)],
    ).createShader(rect);

    final arcPaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, arcPaint);

    // Glow dot at tip
    final angle = -pi / 2 + 2 * pi * progress;
    final tipX  = center.dx + radius * cos(angle);
    final tipY  = center.dy + radius * sin(angle);
    final dotPaint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(tipX, tipY), strokeWidth * 0.4, dotPaint);
    canvas.drawCircle(Offset(tipX, tipY), strokeWidth * 0.38,
        Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── Triple Activity Rings (Fitness-style) ────────────────────────────────────

class ActivityRingsView extends StatelessWidget {
  final Goal goal;
  final double size;

  const ActivityRingsView({super.key, required this.goal, this.size = 90});

  @override
  Widget build(BuildContext context) {
    const lw  = 9.0;
    const gap = 5.0;

    final stepsTotal     = goal.steps.length;
    final stepsDone      = goal.steps.where((s) => s.isCompleted).length;
    final stepsProgress  = stepsTotal == 0 ? 0.0 : stepsDone / stepsTotal;

    final urgency = () {
      if (goal.dueDate == null) return 0.0;
      final total   = goal.dueDate!.difference(goal.createdDate).inSeconds.toDouble();
      final elapsed = DateTime.now().difference(goal.createdDate).inSeconds.toDouble();
      return (elapsed / total).clamp(0.0, 1.0);
    }();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring — overall progress
          ProgressRing(
            progress: goal.progress,
            color: goal.type.color,
            strokeWidth: lw,
            size: size,
          ),
          // Middle ring — steps completed
          ProgressRing(
            progress: stepsProgress,
            color: goal.type.color.withOpacity(0.7),
            strokeWidth: lw,
            size: size - (lw + gap) * 2,
          ),
          // Inner ring — time urgency
          ProgressRing(
            progress: urgency,
            color: goal.isOverdue ? AppColors.danger : goal.type.color.withOpacity(0.45),
            strokeWidth: lw,
            size: size - (lw + gap) * 4,
          ),
          // Center label
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${goal.progressPercent}%',
                style: AppText.mono(size * 0.165, weight: FontWeight.w700),
              ),
              Text(
                'done',
                style: AppText.body(size * 0.095,
                    weight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Mini Ring (sidebar) ──────────────────────────────────────────────────────

class MiniRingView extends StatelessWidget {
  final double progress;
  final Color color;
  final double size;

  const MiniRingView({
    super.key,
    required this.progress,
    required this.color,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ProgressRing(progress: progress, color: color, strokeWidth: 3, size: size),
          Text(
            '${(progress * 100).toInt()}',
            style: AppText.mono(size * 0.3, weight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
