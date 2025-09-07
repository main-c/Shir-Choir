import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class VoicePartTabs extends StatelessWidget {
  final String selectedVoicePart;
  final String userVoicePart;
  final Function(String) onVoicePartChanged;

  const VoicePartTabs({
    super.key,
    required this.selectedVoicePart,
    required this.userVoicePart,
    required this.onVoicePartChanged,
  });

  @override
  Widget build(BuildContext context) {
    final voiceParts = [
      {'key': 'soprano', 'label': 'Soprano'},
      {'key': 'alto', 'label': 'Alto'},
      {'key': 'tenor', 'label': 'Ténor'},
      {'key': 'bass', 'label': 'Basse'},
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: voiceParts.map((voicePart) {
            final key = voicePart['key'] as String;
            final label = voicePart['label'] as String;
            final isSelected = selectedVoicePart == key;
            final isUserVoicePart = userVoicePart == key;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onVoicePartChanged(key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isUserVoicePart)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.person,
                            size: 14,
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      Text(
                        label,
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
