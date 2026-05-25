import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // För Uint8List
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_radius.dart';
import 'package:frontend/design_system/atoms/app_icon.dart';
import 'package:frontend/core/resources/app_icons.dart';
import 'dart:io';

enum MediaThumbSize { small, medium, large }

class MediaThumb extends StatelessWidget {
  final String? imagePath;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final MediaThumbSize size;
  final bool isSelected;

  const MediaThumb.network({super.key, required this.imageUrl, this.size = MediaThumbSize.small, this.isSelected = false})
      : imagePath = null, imageBytes = null;

  const MediaThumb.asset({super.key, required this.imagePath, this.size = MediaThumbSize.small, this.isSelected = false})
      : imageUrl = null, imageBytes = null;

  // NY: För webb!
  const MediaThumb.memory({super.key, required this.imageBytes, this.size = MediaThumbSize.small, this.isSelected = false})
      : imageUrl = null, imagePath = null;

  // NY: För Native (iPhone)!
  const MediaThumb.file({super.key, required this.imagePath, this.size = MediaThumbSize.small, this.isSelected = false})
      : imageUrl = null, imageBytes = null;

  double get _dimension {
    switch (size) {
      case MediaThumbSize.small: return 48;
      case MediaThumbSize.medium: return 72;
      case MediaThumbSize.large: return 128;
    }
  }

  double get _borderRadius {
    switch (size) {
      case MediaThumbSize.small: return AppRadius.sm;
      case MediaThumbSize.medium: return AppRadius.md;
      case MediaThumbSize.large: return AppRadius.lg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _dimension,
      height: _dimension,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.white,
          width: isSelected ? 3 : 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_borderRadius - 2),
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    if (imageBytes != null) return Image.memory(imageBytes!, fit: BoxFit.cover, errorBuilder: (_, _, _) => _fallback());
    if (imageUrl != null) return Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => _fallback());
    if (imagePath != null && !imagePath!.startsWith('assets')) return Image.file(File(imagePath!), fit: BoxFit.cover, errorBuilder: (_, _, _) => _fallback());
    if (imagePath != null) return Image.asset(imagePath!, fit: BoxFit.cover, errorBuilder: (_, _, _) => _fallback());
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      color: AppColors.softUi,
      alignment: Alignment.center,
      child: AppIcon.data(AppIcons.imageSearch, size: 20, color: AppColors.textPrimary),
    );
  }
}