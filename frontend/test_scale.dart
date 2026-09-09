import 'package:flame/events.dart';
import 'package:flame/game.dart';

class TestGame extends FlameGame with ScaleDetector {
  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    print(info.scale.global.x);
    print(info.delta.global.x);
  }
}

void main() {}
