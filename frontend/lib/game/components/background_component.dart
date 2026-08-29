import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import 'dart:math';

class BackgroundComponent extends Component {
  final AppState state;
  final Random _rnd = Random(42);
  final List<List<_BgStar>> _bgStars = [];

  BackgroundComponent(this.state) {
    _generateStars();
  }

  void _generateStars() {
    const starCounts = [140, 90, 50];
    for (int i = 0; i < starCounts.length; i++) {
      final depth = (i + 1) / starCounts.length;
      final layer = <_BgStar>[];
      for (int s = 0; s < starCounts[i]; s++) {
        layer.add(_BgStar(
          x: _rnd.nextDouble() * 2000, // Roughly a screen size for parallax
          y: _rnd.nextDouble() * 2000,
          r: 0.4 + depth * 1.6 * _rnd.nextDouble(),
          a: 0.15 + depth * 0.7 * _rnd.nextDouble(),
          tw: _rnd.nextDouble() * pi * 2,
          depth: depth,
        ));
      }
      _bgStars.add(layer);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final time = DateTime.now().millisecondsSinceEpoch;

    // Draw Parallax Stars
    // Note: Since this is attached to the world, they will move with the camera automatically.
    // To make them parallax, we would normally draw them on a HUD layer.
    // For now, we'll draw them statically in the world or let the camera move them.
    // Real parallax requires subtracting camera position.
    
    // Draw Sectors
    final gridPaint = Paint()
      ..color = const Color(0x3878b4dc)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;

    final n = max(1, (state.users.length / 10).ceil());
    for (int i = 0; i < n; i++) {
      final col = i % 4;
      final row = i ~/ 4;
      final x = col * 560.0;
      final y = row * 560.0;
      canvas.drawRect(Rect.fromLTWH(x, y, 560, 560), gridPaint);
    }
  }
}

class _BgStar {
  final double x, y, r, a, tw, depth;
  _BgStar({required this.x, required this.y, required this.r, required this.a, required this.tw, required this.depth});
}
