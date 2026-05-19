import 'package:flutter/material.dart';

class AnimatedMicButton extends StatefulWidget {
  const AnimatedMicButton({
    super.key,
    required this.onTap,
    this.isListening = false,
    this.size = 200,
  });

  final VoidCallback onTap;
  final bool isListening;
  final double size;

  @override
  State<AnimatedMicButton> createState() => _AnimatedMicButtonState();
}

class _AnimatedMicButtonState extends State<AnimatedMicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    if (widget.isListening) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isListening && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isListening && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildWave({
    required double start,
    required double end,
    required double maxScale,
    required double strokeWidth,
    required Color color,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (!widget.isListening) {
          return const SizedBox.shrink();
        }

        final t = _controller.value;
        double progress;

        if (t < start) {
          progress = 0;
        } else if(t > end) {
          progress = 1;
        } else {
          progress = (t - start) / (end - start);
        }

        final scale = 1.0 + ((maxScale - 1.0) * progress);
        final opacity = (1.0 - progress) * 1.0;

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: strokeWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.20),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canvasSize = widget.size * 2.6;

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: canvasSize,
        height: canvasSize,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            _buildWave(
              start: 0.00,
              end: 0.70,
              maxScale: 1.45,
              strokeWidth: 3,
              color: const Color(0x55FFFFFF),
            ),
            _buildWave(
              start: 0.15,
              end: 0.70,
              maxScale: 1.45,
              strokeWidth: 3,
              color: const Color(0x66FFFFFF),
            ),
            _buildWave(
              start: 0.30,
              end: 1.00,
              maxScale: 1.35,
              strokeWidth: 3,
              color: const Color(0x88FFFFFF),
            ),
            AnimatedScale(
              scale: widget.isListening ? 1.03 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: const Color(0x66F1F3FB),
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 2,
                    color: const Color(0x26081145),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33081145),
                      blurRadius: 6,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.mic_none_rounded,
                    size: 84,
                    color: Color(0xFF081145),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}