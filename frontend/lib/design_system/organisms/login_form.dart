import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_spacing.dart';
import 'package:frontend/design_system/atoms/app_button.dart';
import 'package:frontend/design_system/atoms/app_text_field.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 220),

          AppTextField(
            label: 'E-postadress',
            hintText: 'namn@email.com',
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: AppSpacing.md),

          AppTextField(
            label: 'Lösenord',
            obscureText: true,
          ),

          const SizedBox(height: AppSpacing.md),

          const Align(
            alignment: Alignment.center,
            child: Text(
              'Har du glömt lösenord?',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          AppButton.primaryLogin(
            text: 'Logga in',
            onPressed: () {},
          ),

          const SizedBox(height: AppSpacing.lg),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'Har du inget konto?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4),
              Text(
                'Skapa konto',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          AppButton.googleLogin(
            text: 'Fortsätt Med Google',
            onPressed: () {},
          ),
        ],
      ),
      ),
    );
  }
}