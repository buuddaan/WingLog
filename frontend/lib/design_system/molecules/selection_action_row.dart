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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          label: const Text('Tillbaka', style: TextStyle(color: Colors.white)),
        ),
        TextButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete, color: Colors.red),
          label: Text('Radera ($selectedCount)', style: const TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}