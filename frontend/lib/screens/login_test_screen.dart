import 'package:flutter/material.dart';
import 'package:frontend/design_system/atoms/app_button.dart';

import '../design_system/atoms/app_text.dart';
import 'package:frontend/design_system/atoms/app_text_field.dart';
import 'package:frontend/core/theme/app_spacing.dart';

class LoginTypographyPreview extends StatelessWidget {
  const LoginTypographyPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),

              AppText.title('Logga in'),
              const SizedBox(height: AppSpacing.sm),

              AppText.body(
                'Välkommen tillbaka. Logga in med din e-postadress och ditt lösenord.',
              ),

              const SizedBox(height: AppSpacing.xl),

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

              const SizedBox(height: AppSpacing.lg),

              AppButton.primary(text: 'Logga in', onPressed: () {}
              ),
            ],
          ),
        ),
      ),
    );
  }
}