import 'package:flutter/material.dart';

class SelectionActionRow extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onDelete;
  final int selectedCount;

  const SelectionActionRow({
    super.key,
    required this.onBack,
    required this.onDelete,
    required this.selectedCount,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xCC111111),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 16,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ActionItem(
              onTap: onBack,
              icon: Icons.arrow_back,
              iconColor: Colors.white,
              label: 'Tillbaka',
              textColor: Colors.white,
            ),
            _ActionItem(
              onTap: onDelete,
              icon: Icons.delete,
              iconColor: const Color(0xFFD03F3F),
              label: 'Radera ($selectedCount)',
              textColor: const Color(0xFFD03F3F),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color textColor;

  const _ActionItem({
    required this.onTap,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}