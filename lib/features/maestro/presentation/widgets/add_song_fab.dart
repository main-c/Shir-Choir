import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AddSongFab extends StatelessWidget {
  final VoidCallback onPressed;

  const AddSongFab({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: AppTheme.primaryBlue,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Ajouter un chant'),
    );
  }
}
