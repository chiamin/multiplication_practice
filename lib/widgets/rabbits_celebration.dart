import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/image_loader.dart';

/// 慶祝畫面小元件：
/// - 顯示跳跳兔圖片
/// - 播放 cheer.mp3
/// - ❗不自己關閉 dialog，由外面負責關
class RabbitsCelebration extends StatefulWidget {
  final bool isTablet;

  const RabbitsCelebration({
    super.key,
    required this.isTablet,
  });

  @override
  State<RabbitsCelebration> createState() => _RabbitsCelebrationState();
}

class _RabbitsCelebrationState extends State<RabbitsCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offsetAnimation;
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();

    // 播放歡呼音效
    _player.play(AssetSource('sounds/cheer.mp3'));

    // 跳動動畫
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _offsetAnimation = Tween<double>(begin: 0, end: -20)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 不加任何背景，完全透明，只顯示跳跳兔
    return Center(
      child: AnimatedBuilder(
        animation: _offsetAnimation,
        builder: (context, child) {
          final dy = _offsetAnimation.value;
          final scale = 1.03 + (dy / -200);

          return Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          );
        },
        child: ImageLoader.loadPicture(
          pictureName: 'rabbits.png',
          width: widget.isTablet ? 500 : 300,
        ),
      ),
    );
  }
}

