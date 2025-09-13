import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/song_model.dart';
import '../../providers/songs_provider.dart';
import '../../../audio/providers/audio_player_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/services/github_storage_service.dart';
import '../../../../core/models/download_progress.dart';

class MusicSongCard extends ConsumerWidget {
  final Song song;
  final VoidCallback onTap;

  const MusicSongCard({
    super.key,
    required this.song,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPress: () => _showSongOptions(context, ref),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.composer,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.key,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatDuration(song.duration),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.5),
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        const SizedBox(width: 8),
                        // Indicateurs de disponibilité et ressources
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.2),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                song.sizeMb != null && song.sizeMb! > 0
                                    ? '${song.sizeMb!.toStringAsFixed(1)} MB'
                                    : '--',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (song.lyrics.isNotEmpty) ...[
                              Icon(
                                Icons.library_music,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                            ],
                            if ( song.allAvailableVoices.isNotEmpty
                                ) ...[
                              Icon(
                                Icons.headphones,
                                size: 16,
                                color: Colors.green.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                            ],
                            if (song.maestroNotes.isNotEmpty) ...[
                              Icon(
                                Icons.notes,
                                size: 16,
                                color: Colors.orange.withOpacity(0.7),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildActionButtons(context, ref),
            ],
          ),
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

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerProvider);
    final user = ref.watch(authProvider).user;
    final isCurrentSong = audioState.currentSongId == song.id;
    final isPlaying = isCurrentSong && audioState.isPlaying;

    // Si le chant est téléchargé et prêt, montrer bouton play + options
    if (song.availability == SongAvailability.downloadedAndReady) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              if (isCurrentSong) {
                // Même chant : play/pause
                if (isPlaying) {
                  ref.read(audioPlayerProvider.notifier).pause();
                } else {
                  ref.read(audioPlayerProvider.notifier).play();
                }
              } else {
                // Nouveau chant : charger et jouer
                ref.read(audioPlayerProvider.notifier).playSong(
                      song,
                      user?.voicePart ?? 'soprano',
                    );
              }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCurrentSong
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: isCurrentSong
                    ? [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: isCurrentSong
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      );
    }

    // Pour les autres statuts, montrer des boutons d'action
    return _buildSyncActionButton(context, ref);
  }

  Widget _buildSyncActionButton(BuildContext context, WidgetRef ref) {
    IconData icon;
    Color color;
    VoidCallback? onTap;

    switch (song.availability) {
      case SongAvailability.availableForDownload:
        icon = Icons.cloud_download;
        color = Colors.blue;
        onTap = () => _downloadSong(ref);
        break;
      case SongAvailability.updateAvailable:
        icon = Icons.update;
        color = Colors.orange;
        onTap = () => _updateSong(ref);
        break;
      case SongAvailability.downloading:
        // Gestion spéciale pour la progression
        return _buildDownloadActionButton(context);
      case SongAvailability.syncError:
        icon = Icons.refresh;
        color = Colors.red;
        onTap = () => _retrySong(ref);
        break;
      case SongAvailability.localOnly:
        icon = Icons.phone_android;
        color = Colors.grey;
        onTap = null; // Pas d'action disponible
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
        onTap = null;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: onTap != null
              ? color.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: onTap != null ? color : Colors.grey,
          size: 24,
        ),
      ),
    );
  }

  void _downloadSong(WidgetRef ref) {
    ref.read(songsProvider.notifier).downloadSong(song.id);
  }

  void _updateSong(WidgetRef ref) {
    ref.read(songsProvider.notifier).updateSong(song.id);
  }

  void _retrySong(WidgetRef ref) {
    ref.read(songsProvider.notifier).downloadSong(song.id);
  }

  void _showSongOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.music_note,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      song.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Delete option
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Colors.red.shade600,
              ),
              title: const Text('Supprimer le téléchargement'),
              subtitle: const Text('Le chant pourra être retéléchargé'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, ref);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le téléchargement'),
        content: Text(
          'Voulez-vous supprimer le téléchargement de "${song.title}" ? '
          'Le chant restera disponible pour téléchargement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSong(ref);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _deleteSong(WidgetRef ref) {
    ref.read(songsProvider.notifier).deleteSong(song.id);
  }

  Widget _buildDownloadActionButton(BuildContext context) {
    return StreamBuilder<DownloadProgress>(
      stream: GitHubStorageService()
          .getDetailedDownloadProgress(song.id, song.version ?? 1),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Fallback avec style cohérent
          return Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.1),
                  ),
                ),
                Icon(
                  Icons.download,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ],
            ),
          );
        }

        final progress = snapshot.data!;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Progress ring autour du bouton
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                value: progress.percentage,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
                backgroundColor:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              ),
            ),
            // Bouton avec icône de téléchargement et pourcentage en overlay
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Icône de téléchargement au centre
                  Icon(
                    Icons.download,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  // Pourcentage en overlay en bas à droite
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        progress.percentageFormatted,
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDownloadProgress(BuildContext context, Song song) {
    return StreamBuilder<DownloadProgress>(
      stream: GitHubStorageService()
          .getDetailedDownloadProgress(song.id, song.version ?? 1),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Fallback au spinner simple
          return SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }

        final progress = snapshot.data!;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress.percentage,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
                backgroundColor:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              progress.percentageFormatted,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            if (progress.total > 0)
              Text(
                progress.totalFormatted,
                style: TextStyle(
                  fontSize: 6,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
          ],
        );
      },
    );
  }
}
