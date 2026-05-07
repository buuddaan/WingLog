import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_icons.dart';
import '../atoms/app_icon.dart';

class AppBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E5E5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: AppIcons.soundSearch,
            label: 'Identifiera ljud',
            index: 0,
          ),
          _buildNavItem(
            icon: AppIcons.imageSearch,
            label: 'Identifiera bild',
            index: 1,
          ),
          _buildNavItem(
            icon: AppIcons.camera,
            label: 'Kamera',
            index: 2,
          ),
          _buildNavItem(
            icon: AppIcons.myCollection,
            label: 'Min samling',
            index: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected = selectedIndex == index;
    final Color color = isSelected ? const Color(0xFF2F6B66) : Colors.black54;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            icon: icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}