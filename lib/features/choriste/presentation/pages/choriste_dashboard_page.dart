import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../i18n/strings.g.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/models/user_model.dart';
import '../../providers/songs_provider.dart';
import '../../models/song_model.dart';
import '../widgets/learning_center_sheet.dart';
import '../widgets/music_song_card.dart';
import '../widgets/now_playing_bottom_bar.dart';

class ChoristeDashboardPage extends ConsumerStatefulWidget {
  const ChoristeDashboardPage({super.key});

  @override
  ConsumerState<ChoristeDashboardPage> createState() =>
      _ChoristeDashboardPageState();
}

class _ChoristeDashboardPageState extends ConsumerState<ChoristeDashboardPage> {
  String _searchQuery = '';

  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user!;
    final songs = ref.watch(songsProvider);
    final t = Translations.of(context);

    // Filtrer les chants selon la recherche et le statut
    final songsList = songs.valueOrNull ?? [];
    final filteredSongs = songsList.where((song) {
      final matchesSearch =
          song.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              song.composer.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      // Filtrage par statut retiré temporairement pour le MVP

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          _buildHeader(context, t, user, songsList.length),
          _buildModernSearchBar(context, t),
          // _buildFilterChips(context, t),
          Expanded(
            child: filteredSongs.isEmpty
                ? _buildEmptyState(context, t)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                    itemCount: filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = filteredSongs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: MusicSongCard(
                          song: song,
                          onTap: () {
                            // Ouvrir les détails seulement si le chant est téléchargé
                            if (song.availability ==
                                SongAvailability.downloadedAndReady) {
                              // Ouvrir le learning center au lieu de song detail
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) =>
                                    LearningCenterSheet(songId: song.id),
                              );
                            } else {
                              // Montrer un snackbar informatif pour les chants non disponibles
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_getAvailabilityMessage(
                                      song.availability)),
                                  action: song.availability ==
                                          SongAvailability.availableForDownload
                                      ? SnackBarAction(
                                          label: 'Télécharger',
                                          onPressed: () {
                                            ref
                                                .read(songsProvider.notifier)
                                                .downloadSong(song.id);
                                          },
                                        )
                                      : null,
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const NowPlayingBottomBar(),
    );
  }

  Widget _buildHeader(
      BuildContext context, Translations t, User user, int songCount) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const NetworkImage(
              'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.4),
            BlendMode.darken,
          ),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.9),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Clickable choir logo
                GestureDetector(
                  onTap: () {
                    context.push('/choir/profile');
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onPrimary,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1514320291840-2e0a9bf2a9ae?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Theme.of(context).colorScheme.primary,
                            child: Icon(
                              Icons.music_note,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 24,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      context.push('/choir/profile');
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.app.title, // "Shir Choir"
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Compteur de chants
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.library_music,
                                    size: 16,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$songCount chants',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Rôle utilisateur
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimary
                                      .withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 16,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    user.voicePart ?? 'Aucune voix',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    context.push('/user/settings');
                  },
                  child: Icon(
                    Icons.settings,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSearchBar(BuildContext context, Translations t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (query) {
            setState(() {
              _searchQuery = query;
            });
          },
          decoration: InputDecoration(
            hintText: 'Rechercher un chant ou compositeur...',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                size: 24,
              ),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Translations t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.music_off_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            t.dashboard.noSongsFound,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier vos filtres',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getAvailabilityMessage(SongAvailability availability) {
    switch (availability) {
      case SongAvailability.availableForDownload:
        return 'Ce chant est disponible au téléchargement';
      case SongAvailability.updateAvailable:
        return 'Une nouvelle version de ce chant est disponible';
      case SongAvailability.downloading:
        return 'Téléchargement en cours...';
      case SongAvailability.syncError:
        return 'Erreur de téléchargement. Réessayez';
      case SongAvailability.localOnly:
        return 'Ce chant n\'est disponible qu\'en local';
      case SongAvailability.downloadedAndReady:
        return 'Chant prêt à être joué';
      default:
        return 'Statut inconnu';
    }
  }
}
