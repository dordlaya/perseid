import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import 'dart:math';
import 'package:flame/events.dart';

class StarComponent extends Component with TapCallbacks {
  UserSnap user;
  final AppState state;
  
  StarComponent(this.user, this.state);

  @override
  bool containsLocalPoint(Vector2 point) {
    final d = (point.x - user.x) * (point.x - user.x) + (point.y - user.y) * (point.y - user.y);
    final tapR = max(user.r + 6, 16.0);
    return d <= tapR * tapR;
  }

  @override
  void onTapDown(TapDownEvent event) {
    state.selectedUserId = user.id;
    state.notifyListeners();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final pulse = user.pulse;
    final vis = 0.2 + 0.8 * user.pull;
    
    // Draw Glow
    final glowColor = const Color(0xFFFFD696).withOpacity(vis * (0.45 + pulse * 0.5));
    final glowPaint = Paint()
      ..color = glowColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, user.r + 12)
      ..blendMode = BlendMode.plus;
    canvas.drawCircle(Offset(user.x, user.y), user.r + 12, glowPaint);

    // Draw Pulse Ring
    if (pulse > 0) {
      final pulsePaint = Paint()
        ..color = const Color(0xFFFFD282).withOpacity(pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset(user.x, user.y), user.r + 6 + (1 - pulse) * 16, pulsePaint);
    }

    // Draw Star Shape
    _drawStarShape(canvas, user.x, user.y, user.r, pulse, vis);
    
    // Draw Selected Ring
    if (state.selectedUserId == user.id) {
      final selectedPaint = Paint()
        ..color = const Color(0x9FE7FF).withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(user.x, user.y), user.r + 12, selectedPaint);
    }
  }

  void _drawStarShape(Canvas canvas, double x, double y, double r, double pulse, double vis) {
    const spikes = 4;
    final outer = r + pulse * 3;
    final inner = outer * 0.4;
    final path = Path();
    
    for (int i = 0; i < spikes * 2; i++) {
      final rad = i % 2 == 0 ? outer : inner;
      final a = (pi / spikes) * i - pi / 2;
      final px = x + cos(a) * rad;
      final py = y + sin(a) * rad;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    
    final shapePaint = Paint()
      ..color = const Color(0xFFFFF0D2).withOpacity(0.9 * vis)
      ..blendMode = BlendMode.plus;
    canvas.drawPath(path, shapePaint);
  }
}
