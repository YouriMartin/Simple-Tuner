import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/ui_constants.dart';
import '../../core/constants/audio_constants.dart';

/// Widget displaying LEDs in a circular arrangement for tuning feedback
class TunerLedCircle extends StatefulWidget {
  final double centsOffset;
  final bool isInTune;
  final bool hasValidNote;
  final double amplitude;

  const TunerLedCircle({
    super.key,
    required this.centsOffset,
    required this.isInTune,
    required this.hasValidNote,
    required this.amplitude,
  });

  @override
  State<TunerLedCircle> createState() => _TunerLedCircleState();
}

class _TunerLedCircleState extends State<TunerLedCircle>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(TunerLedCircle oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Start pulsing animation when in tune
    if (widget.isInTune && widget.hasValidNote) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: UIConstants.tunerRadius * 2,
      height: UIConstants.tunerRadius * 2,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isInTune ? _pulseAnimation.value : 1.0,
            child: CustomPaint(
              painter: _TunerLedPainter(
                centsOffset: widget.centsOffset,
                isInTune: widget.isInTune,
                hasValidNote: widget.hasValidNote,
                amplitude: widget.amplitude,
              ),
              size: Size(UIConstants.tunerRadius * 2, UIConstants.tunerRadius * 2),
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for the LED circle
class _TunerLedPainter extends CustomPainter {
  final double centsOffset;
  final bool isInTune;
  final bool hasValidNote;
  final double amplitude;

  _TunerLedPainter({
    required this.centsOffset,
    required this.isInTune,
    required this.hasValidNote,
    required this.amplitude,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = UIConstants.tunerRadius;

    // Draw center circle (note indicator)
    _drawCenterCircle(canvas, center, radius);

    // Draw LED arc
    _drawLedArc(canvas, center, radius);

    // Draw target indicator (vertical line at top)
    _drawTargetIndicator(canvas, center, radius);
  }

  void _drawCenterCircle(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = hasValidNote 
          ? (isInTune ? UIConstants.ledInTune : UIConstants.ledSlightlyOff)
          : UIConstants.ledInactive
      ..style = PaintingStyle.fill;

    // Outer ring
    canvas.drawCircle(center, 30, paint);

    // Inner ring (darker)
    paint.color = paint.color.withOpacity(0.7);
    canvas.drawCircle(center, 20, paint);
  }

  void _drawLedArc(Canvas canvas, Offset center, double radius) {
    const totalLeds = AudioConstants.ledsPerSide * 2;
    const arcAngle = math.pi * 0.8; // 144 degrees total arc
    const startAngle = (math.pi - arcAngle) / 2; // Start from left side

    for (int i = 0; i < totalLeds; i++) {
      final ledAngle = startAngle + (i * arcAngle / (totalLeds - 1));
      final ledOffset = Offset(
        center.dx + radius * 0.8 * math.cos(ledAngle - math.pi / 2),
        center.dy + radius * 0.8 * math.sin(ledAngle - math.pi / 2),
      );

      final ledColor = _getLedColor(i, totalLeds);
      final paint = Paint()
        ..color = ledColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(ledOffset, UIConstants.ledRadius, paint);

      // Add glow effect for active LEDs
      if (ledColor != UIConstants.ledInactive) {
        final glowPaint = Paint()
          ..color = ledColor.withOpacity(0.3)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

        canvas.drawCircle(ledOffset, UIConstants.ledRadius * 1.5, glowPaint);
      }
    }
  }

  void _drawTargetIndicator(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const indicatorHeight = 15.0;
    final topPoint = Offset(center.dx, center.dy - radius * 0.9);

    canvas.drawLine(
      Offset(topPoint.dx, topPoint.dy - indicatorHeight / 2),
      Offset(topPoint.dx, topPoint.dy + indicatorHeight / 2),
      paint,
    );
  }

  Color _getLedColor(int ledIndex, int totalLeds) {
    if (!hasValidNote || amplitude < 0.01) {
      return UIConstants.ledInactive;
    }

    const centerIndex = AudioConstants.ledsPerSide;
    final maxCentsRange = 50.0; // ±50 cents range

    // Calculate which LED should be active based on cents offset
    final normalizedOffset = centsOffset / maxCentsRange; // -1 to 1
    final activeIndex = centerIndex + (normalizedOffset * AudioConstants.ledsPerSide);

    // Light up LEDs in a gradient around the active position
    final distance = (ledIndex - activeIndex).abs();

    if (distance <= 1) {
      // Main active LED(s)
      if (isInTune) {
        return UIConstants.ledInTune;
      } else if (centsOffset.abs() < 20) {
        return UIConstants.ledSlightlyOff;
      } else {
        return UIConstants.ledVeryOff;
      }
    } else if (distance <= 2) {
      // Adjacent LEDs with reduced brightness
      final color = isInTune 
          ? UIConstants.ledInTune
          : (centsOffset.abs() < 20 ? UIConstants.ledSlightlyOff : UIConstants.ledVeryOff);
      return color.withOpacity(0.5);
    }

    return UIConstants.ledInactive;
  }

  @override
  bool shouldRepaint(_TunerLedPainter oldDelegate) {
    return oldDelegate.centsOffset != centsOffset ||
           oldDelegate.isInTune != isInTune ||
           oldDelegate.hasValidNote != hasValidNote ||
           oldDelegate.amplitude != amplitude;
  }
}
