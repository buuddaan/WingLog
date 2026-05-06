import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraScreen extends StatelessWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("Laddar kameran...")));
  }
}