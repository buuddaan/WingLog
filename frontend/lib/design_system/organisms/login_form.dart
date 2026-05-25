import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_spacing.dart';
import 'package:frontend/design_system/atoms/primary_gradient_button.dart';
import 'package:frontend/design_system/atoms/app_text_field.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({
    super.key,
    required this.formKey,
    required this.isLogin,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
    required this.onGoogleSignIn,
    required this.onToggleMode,
    required this.onSkipLogin,
    required this.rememberMe,
    required this.onRememberMeChanged,
  });

  final GlobalKey<FormState> formKey;
  final bool isLogin;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onToggleMode;
  final VoidCallback onSkipLogin;
  final bool rememberMe;
  final ValueChanged<bool> onRememberMeChanged;


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
      ),
      child: Form(
        key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 220),

          AppTextField(
            controller: usernameController,
            label: 'Användarnamn',
            hintText: 'Användarnamn',
            validator: (value) =>
                value == null || value.isEmpty ? 'Ange användarnamn' : null,
          ),

          const SizedBox(height: AppSpacing.md),

          if (!isLogin) ...[
            AppTextField(
              controller: emailController,
              label: 'E-postadress',
              hintText: 'namn@email.com',
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value == null || value.isEmpty ? 'Ange email' : null,

      ),
         const SizedBox(height: AppSpacing.md),
       ],
          AppTextField(
            controller: passwordController,
            label: 'Lösenord',
            obscureText: true,
            validator : (value) {
              if (value == null || value.isEmpty) {
                return 'Ange lösenord';
              }
              if (!isLogin && value.length < 6) {
                return 'Minst 8 tecken krävs';
              }
              return null;
            },
          ),

          const SizedBox(height: AppSpacing.md),

          if (isLogin)
            Row(
              children: [
                Checkbox(
                  value: rememberMe,
                  onChanged: (val) => onRememberMeChanged(val ?? false),
                  activeColor: AppColors.brandPrimary,
                  checkColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.textPrimary, width: 1.5),
                ),
                const Text(
                  'Kom ihåg mig',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),

          if (isLogin)
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

          PrimaryGradientButton.filled(
            text: isLogin ? 'Logga in' : 'Registrera',
            onPressed: onSubmit,
          ),

          const SizedBox(height: AppSpacing.lg),

          GestureDetector(
            onTap: onToggleMode,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isLogin? 'Har du inget konto?' : ' Har du redan ett konto?',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              SizedBox(width: 4),
              Text(
                isLogin ? 'Skapa konto' : 'Logga in',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

          const SizedBox(height: AppSpacing.lg),

          PrimaryGradientButton.gradient(
            text: 'Fortsätt Med Google',
            onPressed: onGoogleSignIn,
          ),
          const SizedBox(height: AppSpacing.lg),
            ],
          ),
         ),
      ),
    );
  }
}