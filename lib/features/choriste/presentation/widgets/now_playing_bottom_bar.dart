import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';

import '../../../../i18n/strings.g.dart';
import '../../../audio/providers/audio_player_provider.dart';
import 'learning_center_sheet.dart';

class NowPlayingBottomBar extends ConsumerWidget {
  const NowPlayingBottomBar({super.key});

  void _showNowPlayingSheet(BuildContext context, String songId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      useSafeArea: true,
      builder: (context) => LearningCenterSheet(songId: songId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerProvider);
    final t = Translations.of(context);

    // Ne pas afficher si aucun chant n'est chargé
    if (audioState.currentSongTitle == null) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer(
              builder: (context, ref, child) {
                final audioState = ref.watch(audioPlayerProvider);

                final progress = audioState.duration.inMilliseconds > 0
                    ? (audioState.position.inMilliseconds /
                            audioState.duration.inMilliseconds)
                        .clamp(0.0, 1.0)
                    : 0.0;

                return Container(
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.15), // Couleur du fond vide
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Stack(
                    children: [
                      // Couleur de "buffer" (fixe)
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 1.0, // Toute la largeur
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.3), // Couleur "chargée"
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      // Progression réelle
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Contrôles principaux
            Row(
              children: [
                // Artwork/Icon (cliquable)
                GestureDetector(
                  onTap: () {
                    if (audioState.currentSongId != null) {
                      _showNowPlayingSheet(context, audioState.currentSongId!);
                    }
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.music_note,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Infos chanson (cliquable)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (audioState.currentSongId != null) {
                        _showNowPlayingSheet(
                            context, audioState.currentSongId!);
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          audioState.currentSongTitle!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Consumer(
                          builder: (context, ref, child) {
                            final audioState = ref.watch(audioPlayerProvider);

                            // ✅ Afficher l'erreur si elle existe
                            if (audioState.error != null) {
                              return Text(
                                audioState.error!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            }

                            return Text(
                              '${_formatDuration(audioState.position)} / ${_formatDuration(audioState.duration)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Contrôles audio
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bouton rewind (-10s)
                    IconButton(
                      onPressed: () {
                        ref.read(audioPlayerProvider.notifier).seekBackward();
                      },
                      icon: Icon(
                        Icons.replay_10,
                        size: 24,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),

                    // Bouton play/pause principal
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          if (audioState.isPlaying) {
                            ref.read(audioPlayerProvider.notifier).pause();
                          } else {
                            ref.read(audioPlayerProvider.notifier).play();
                          }
                        },
                        icon: audioState.isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              )
                            : Icon(
                                audioState.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 24,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                      ),
                    ),

                    // Bouton fast-forward (+10s)
                    IconButton(
                      onPressed: () {
                        ref.read(audioPlayerProvider.notifier).seekForward();
                      },
                      icon: Icon(
                        Icons.forward_10,
                        size: 24,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                  ],
                ),

                // Bouton pour ouvrir les détails
                IconButton(
                  onPressed: () {
                    if (audioState.currentSongId != null) {
                      _showNowPlayingSheet(context, audioState.currentSongId!);
                    }
                  },
                  icon: Icon(
                    Icons.keyboard_arrow_up,
                    size: 24,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}
