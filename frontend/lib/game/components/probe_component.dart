import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../state/app_state.dart';

class ProbeComponent extends Component {
  final DisplayProbe probe;
  
  ProbeComponent(this.probe);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final hue = probe.hue;
    final glowColor = HSLColor.fromAHSL(0.12, hue, 1.0, 0.6).toColor();
    final coreColor = HSLColor.fromAHSL(0.9, hue, 1.0, 0.85).toColor();

    // Draw Trail
    if (probe.trail.length > 1) {
      final glowPaint = Paint()
        ..color = glowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.plus;
        
      final corePaint = Paint()
        ..color = coreColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.plus;

      final path = Path();
      path.moveTo(probe.trail.first.dx, probe.trail.first.dy);
      for (int i = 1; i < probe.trail.length; i++) {
        path.lineTo(probe.trail[i].dx, probe.trail[i].dy);
      }
      
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, corePaint);
    }

    // Draw Probe Head
    final headGlow = Paint()
      ..color = HSLColor.fromAHSL(0.6, hue, 1.0, 0.66).toColor()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..blendMode = BlendMode.plus;
    canvas.drawCircle(Offset(probe.x, probe.y), 6, headGlow);

    final headCore = Paint()..color = coreColor;
    canvas.drawCircle(Offset(probe.x, probe.y), 3, headCore);
  }
}
