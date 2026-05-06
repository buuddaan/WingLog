import 'package:flutter/material.dart';
import'package:frontend/core/theme/app_gradients.dart';


class LoginBackground extends StatelessWidget {
  const LoginBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      color: Colors.white,
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: 380,
          width: double.infinity,
          child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.loginBackground,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: CustomPaint(
                painter: _WhiteWavePainter(),
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _WhiteWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..cubicTo(
        size.width * 0.2,
        size.height * 0.1,
        size.width * 0.35,
        size.height * 0.7,
        size.width * 0.5,
        size.height * 0.5,
      )
      ..cubicTo(
        size.width * 0.7,
        size.height * 0.2,
        size.width * 0.85,
        size.height * 0.6,
        size.width,
        size.height * 0.4,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}