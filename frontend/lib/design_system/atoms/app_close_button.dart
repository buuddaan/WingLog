import 'package:flutter/material.dart';

class AppCloseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AppCloseButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.close, color: Colors.white, size: 32),
      onPressed: onPressed,
    );
  }
}