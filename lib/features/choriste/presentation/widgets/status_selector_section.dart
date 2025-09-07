import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../i18n/strings.g.dart';
import '../../models/song_model.dart';
import '../../providers/songs_provider.dart';

class StatusSelectorSection extends ConsumerWidget {
  final String songId;
  final String userId;

  const StatusSelectorSection({
    super.key,
    required this.songId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStatus =
        ref.watch(songProgressProvider.notifier).getProgress(songId);
    final t = Translations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mon statut d\'apprentissage',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),

            // Sélecteurs de statut
            Column(
              children: LearningStatus.values.map((status) {
                final isSelected = currentStatus == status;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(songProgressProvider.notifier).updateProgress(
                            songId,
                            userId,
                            status,
                          );

                      // Afficher un toast de confirmation
                      toastification.show(
                        context: context,
                        title: Text('Statut mis à jour'),
                        description: Text(
                            'Votre progression a été sauvegardée: ${status.label}'),
                        type: ToastificationType.success,
                        style: ToastificationStyle.fillColored,
                        autoCloseDuration: const Duration(seconds: 2),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getStatusColor(context, status)
                                .withValues(alpha: 0.1)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? _getStatusColor(context, status)
                              : Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getStatusIcon(status),
                            color: isSelected
                                ? _getStatusColor(context, status)
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              status.label,
                              style: TextStyle(
                                color: isSelected
                                    ? _getStatusColor(context, status)
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.8),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: _getStatusColor(context, status),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context, LearningStatus status) {
    switch (status) {
      case LearningStatus.notStarted:
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
      case LearningStatus.inProgress:
        return Colors.orange;
      case LearningStatus.mastered:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(LearningStatus status) {
    switch (status) {
      case LearningStatus.notStarted:
        return Icons.radio_button_unchecked;
      case LearningStatus.inProgress:
        return Icons.access_time;
      case LearningStatus.mastered:
        return Icons.check_circle;
    }
  }
}
