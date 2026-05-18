import 'package:flutter/material.dart';
import 'package:frontend/design_system/atoms/neutral_button.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_radius.dart';
import 'package:frontend/core/theme/app_spacing.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/design_system/atoms/media_thumb.dart';

class CollectionCard extends StatelessWidget {
  const CollectionCard({
    super.key,
    required this.title,
    required this.imagePaths,
    required this.imageUrls,
    required this.onViewPressed,
    this.onIdentifyPressed,
  });

  final String title;
  final List<String> imagePaths;
  final VoidCallback onViewPressed;
  final VoidCallback? onIdentifyPressed;
  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    final previewImages = imagePaths.take(3).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.softUi,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.borderPrimary,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.header4,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (int i = 0; i < previewImages.length; i++) ...[
                MediaThumb.network(
                  imageUrl: previewImages[i],
                  size: MediaThumbSize.small,
                ),
                if (i != previewImages.length - 1)
                  const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              NeutralButton.small(
                text: 'Visa',
                onPressed: onViewPressed,
              ),
              if (onIdentifyPressed != null) ...[
                const SizedBox(width: AppSpacing.sm),
                NeutralButton.small(
                  text: 'Identifiera',
                  onPressed: onIdentifyPressed!,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}