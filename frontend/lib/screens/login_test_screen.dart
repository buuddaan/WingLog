import 'package:flutter/material.dart';
//import 'package:frontend/design_system/atoms/app_button.dart';

//import '../design_system/atoms/app_text.dart';
//import 'package:frontend/design_system/atoms/app_text_field.dart';
//import 'package:frontend/core/theme/app_spacing.dart';
import 'package:frontend/design_system/organisms/login_background.dart';
import 'package:frontend/design_system/organisms/login_form.dart';

class LoginTypographyPreview extends StatelessWidget {
  const LoginTypographyPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const LoginBackground(),
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child:  LoginForm(),
          ),
        ],
      ),
    );
  }
}