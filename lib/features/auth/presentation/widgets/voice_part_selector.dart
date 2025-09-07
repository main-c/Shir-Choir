import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../i18n/strings.g.dart';

class VoicePartSelector extends StatelessWidget {
  final String? selectedVoicePart;
  final Function(String) onVoicePartSelected;

  const VoicePartSelector({
    super.key,
    required this.selectedVoicePart,
    required this.onVoicePartSelected,
  });

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    
    final voiceParts = [
      {'key': 'soprano', 'label': t.auth.soprano, 'icon': Icons.music_note},
      {'key': 'alto', 'label': t.auth.alto, 'icon': Icons.music_note},
      {'key': 'tenor', 'label': t.auth.tenor, 'icon': Icons.music_note},
      {'key': 'bass', 'label': t.auth.bass, 'icon': Icons.music_note},
    ];

    return Column(
      children: voiceParts.map((voicePart) {
        final isSelected = selectedVoicePart == voicePart['key'];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: GestureDetector(
            onTap: () => onVoicePartSelected(voicePart['key'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.secondaryBlue : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppTheme.secondaryBlue : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    voicePart['icon'] as IconData,
                    color: isSelected ? Colors.white : AppTheme.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    voicePart['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
