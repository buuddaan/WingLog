import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import'package:frontend/core/theme/app_gradients.dart';
import 'package:frontend/core/theme/app_images.dart';
import 'package:frontend/core/theme/app_sizes.dart';
import 'package:frontend/core/theme/app_spacing.dart';



class LoginBackground extends StatelessWidget {
  const LoginBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      color: AppColors.surface,
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: 390, // ändra på himlens placering
          width: double.infinity,
          child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.loginBackground,
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.loginLogoTop),
              child: Image.asset(
                AppImages.logo,
                width: AppSizes.loginLogoWidth,
              ),
            ),
          ),

          const SizedBox(height: 290),

          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 220, //ändra på när vita delen börjar
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
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;

    final path = Path()  //justera vågens waves
      ..moveTo(0, size.height * 0.6)
      ..cubicTo(
        size.width * 0.15,
        size.height * 0.2,
        size.width * 0.35,
        size.height * 0.9,
        size.width * 0.55,
        size.height * 0.5,
      )
      ..cubicTo(
        size.width * 0.75, //andra kullen
        size.height * 0.15, //andra kullen
        size.width * 0.8,  //andra kullen neråt
        size.height * 0.8,
        size.width,
        size.height * 0.6, //vågens slut
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}