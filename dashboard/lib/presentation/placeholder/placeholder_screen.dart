import 'package:flutter/material.dart';
import '../widgets/coming_soon_view.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.module, required this.icon});

  final String module;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ComingSoonView(module: module, icon: icon);
  }
}
