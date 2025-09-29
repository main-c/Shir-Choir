import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../audio/providers/audio_player_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../models/song_model.dart';
import '../../providers/songs_provider.dart';

// Classe pour représenter une note du Maestro avec catégorie
class MaestroNote {
  final String category;
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  MaestroNote({
    required this.category,
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
  });
}

class LearningCenterSheet extends ConsumerStatefulWidget {
  final String songId;

  const LearningCenterSheet({
    super.key,
    required this.songId,
  });

  @override
  ConsumerState<LearningCenterSheet> createState() =>
      _LearningCenterSheetState();
}

class _LearningCenterSheetState extends ConsumerState<LearningCenterSheet>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late TabController _tabController;
  late Animation<double> _slideAnimation;
  late ScrollController _scrollController;
  late ScrollController _waveformScrollController;

  // État des voix sélectionnées pour le mélange
  Set<String> selectedVoices = {};
  String? selectedVoicePart; // Pupitre sélectionné (soprano, alto, tenor, bass)
  String? primaryVoice; // Voix principale sélectionnée
  bool showTranslation = false;
  bool showPhonetics = true;
  bool _showMiniPlayer = false; // Mini-player en bas quand on scroll
  bool _isVoiceSelectorExpanded = true;

  @override
  void initState() {
    super.initState();

    // Animation d'entrée
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Contrôleur de scroll pour détecter le collapse du player
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Contrôleur d'onglets
    _tabController = TabController(length: 4, vsync: this);

    // Contrôleur waveform pour scrolling automatique
    _waveformScrollController = ScrollController();

    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialiser avec l'état actuel du lecteur audio
    final audioState = ref.read(audioPlayerProvider);

    if (audioState.currentSongId == widget.songId && selectedVoices.isEmpty) {
      // Une voix de ce song est déjà en train de jouer
      final currentVoicePart = audioState.currentVoicePart;

      if (currentVoicePart != null) {
        setState(() {
          selectedVoicePart = currentVoicePart;
          selectedVoices.add(currentVoicePart);
          primaryVoice = currentVoicePart;
        });
      }
    } else if (selectedVoices.isEmpty) {
      // Fallback : initialiser avec la voix de l'utilisateur
      final user = ref.read(authProvider).user;
      if (user?.voicePart != null) {
        setState(() {
          selectedVoicePart = user!.voicePart;
          primaryVoice = user.voicePart;
          selectedVoices.add(user.voicePart!);
        });
      }
    }
  }

  void _onScroll() {
    const threshold = 500.0; // Seuil pour activer le mini-player
    final shouldShowMini = _scrollController.offset > threshold;

    if (shouldShowMini != _showMiniPlayer) {
      if (mounted) {
        setState(() {
          _showMiniPlayer = shouldShowMini;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    _waveformScrollController.dispose();

    // Nettoyer le cache PDF pour éviter les fuites mémoire
    _pdfCache.clear();

    super.dispose();
  }

  void _closeSheet() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final songs = ref.watch(songsProvider);
    final songsList = songs.valueOrNull ?? [];
    final song = songsList.firstWhere(
      (s) => s.id == widget.songId,
      orElse: () => throw Exception('Chant non trouvé'),
    );

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
              0, MediaQuery.of(context).size.height * _slideAnimation.value),
          child: SafeArea(
            child: Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              body: Stack(
                children: [
                  // Contenu principal avec scroll coordonné
                  NestedScrollView(
                    controller: _scrollController,
                    physics: const ClampingScrollPhysics(),
                    headerSliverBuilder:
                        (BuildContext context, bool innerBoxIsScrolled) {
                      return <Widget>[
                        // Header qui peut scroller vers le haut
                        SliverToBoxAdapter(
                          child: _buildHeader(context, song),
                        ),
                        // Lecteur qui peut scroller vers le haut
                        SliverToBoxAdapter(
                          child: _buildCompactPlayer(context, song),
                        ),
                        // Séparation
                       const SliverToBoxAdapter(
                          child:  Column(
                            children: [
                              SizedBox(height: 24),
                            ],
                          ),
                        ),
                        // Tab Bar - reste fixé en haut quand on scroll
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _SliverTabBarDelegate(
                            child: _buildTabBar(context),
                          ),
                        ),
                      ];
                    },
                    body: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPartitionTab(context, song),
                        _buildLyricsTab(context, song),
                        _buildMaestroNotesTab(context, song),
                        _buildResourcesTab(context, song),
                      ],
                    ),
                  ),

                  // Mini-player en overlay fixe en bas (style YouTube/Spotify)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    bottom: _showMiniPlayer ? 0 : -100,
                    left: 0,
                    right: 0,
                    child: _buildMiniPlayer(context, song),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Song song) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre de fermeture
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              IconButton(
                onPressed: _closeSheet,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Titre et compositeur
          Text(
            song.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            song.composer,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),

          // Informations rapides
          Row(
            children: [
              _buildInfoChip(
                context,
                Icons.music_note,
                song.key,
                Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                context,
                Icons.schedule,
                _formatDuration(song.duration),
                Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
      BuildContext context, IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer(BuildContext context, Song song) {
    return Consumer(
      builder: (context, ref, child) {
        final audioState = ref.watch(audioPlayerProvider);
        final progress = audioState.duration.inMilliseconds > 0
            ? (audioState.position.inMilliseconds /
                    audioState.duration.inMilliseconds)
                .clamp(0.0, 1.0)
            : 0.0;

        return Container(
          height: 90,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: [
            // Progress bar fine en haut
            Container(
              height: 2,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                ),
              ),
            ),
            // Contenu principal
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    // Vignette d'album (côté gauche)
                    Container(
                      width: 44,
                      height: 44,
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
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Titre et informations (centre-gauche)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Ligne 1: Titre + Voix courante
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  song.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Indicateur de voix courante
                              Consumer(
                                builder: (context, ref, child) {
                                  final audioState =
                                      ref.watch(audioPlayerProvider);
                                  final currentVoice = audioState
                                          .currentVoicePart
                                          ?.capitalize() ??
                                      ref
                                          .read(authProvider)
                                          .user
                                          ?.voicePart
                                          ?.capitalize() ??
                                      'Soprano';
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.campaign,
                                          size: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          currentVoice,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          // Ligne 2: Compositeur + Note + Durée
                          Text(
                            '${song.composer} • ${song.key} • ${_formatDuration(song.duration)}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Bouton play avec animation douce (centre)
                    Consumer(
                      builder: (context, ref, child) {
                        final audioState = ref.watch(audioPlayerProvider);
                        final isCurrentSong =
                            audioState.currentSongId == song.id;
                        final isPlaying = isCurrentSong && audioState.isPlaying;

                        return GestureDetector(
                          onTap: () {
                            if (isCurrentSong) {
                              if (isPlaying) {
                                ref.read(audioPlayerProvider.notifier).pause();
                              } else {
                                ref.read(audioPlayerProvider.notifier).play();
                              }
                            } else {
                              final userVoicePart =
                                  ref.read(authProvider).user?.voicePart ??
                                      'soprano';
                              ref
                                  .read(audioPlayerProvider.notifier)
                                  .playSong(song, userVoicePart);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: isPlaying
                                  ? [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.4),
                                        blurRadius: 12,
                                        spreadRadius: 0,
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 12),

                    // Icône d'expansion (côté droit)
                    Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                      size: 24,
                    ),
                  ],
                ),
              ),
            )
          ]),
        );
      },
    );
  }

  Widget _buildCompactPlayer(BuildContext context, Song song) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            // Header minimal avec juste bouton fermer
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: _closeSheet,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                    size: 24,
                  ),
                ),
              ],
            ),

            // Lecteur audio optimisé avec plus d'espace
            Consumer(
              builder: (context, ref, child) {
                final audioState = ref.watch(audioPlayerProvider);
                final progress = audioState.duration.inMilliseconds > 0
                    ? (audioState.position.inMilliseconds /
                            audioState.duration.inMilliseconds)
                        .clamp(0.0, 1.0)
                    : 0.0;

                return Column(
                  children: [
                    // 🎵 Equalizer Animation plus grand
                    Container(
                      height: 60,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: AudioEqualizerAnimation(
                        isPlaying: audioState.isPlaying,
                        activeColor: Theme.of(context).colorScheme.primary,
                        inactiveColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.3),
                        height: 44,
                        barsCount: 25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 🎵 Progress Bar
                    Container(
                      width: double.infinity,
                      child: Column(
                        children: [
                          // Barre de progression
                          Container(
                            height: 4,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Temps
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(audioState.position),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                _formatDuration(audioState.duration),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // Contrôles audio
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // -10s
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: () {
                      ref.read(audioPlayerProvider.notifier).seekBackward();
                    },
                    icon: Icon(
                      Icons.replay_10,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                      size: 20,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Previous/Rewind
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: IconButton(
                    onPressed: () {
                      ref
                          .read(audioPlayerProvider.notifier)
                          .seek(Duration.zero);
                    },
                    icon: Icon(
                      Icons.skip_previous,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                      size: 22,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Play/Pause principal
                Consumer(
                  builder: (context, ref, child) {
                    final audioState = ref.watch(audioPlayerProvider);
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          final isCurrentSong = audioState.currentSongId == song.id;
                          
                          if (isCurrentSong) {
                            if (audioState.isPlaying) {
                              ref.read(audioPlayerProvider.notifier).pause();
                            } else {
                              ref.read(audioPlayerProvider.notifier).play();
                            }
                          } else {
                            final userVoicePart = ref.read(authProvider).user?.voicePart ?? 'soprano';
                            ref.read(audioPlayerProvider.notifier).playSong(song, userVoicePart);
                          }
                        },
                        icon: audioState.isLoading ||
                                audioState.processingState ==
                                    just_audio.ProcessingState.loading
                            ? SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Theme.of(context).colorScheme.surface,
                                ),
                              )
                            : Icon(
                                audioState.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Theme.of(context).colorScheme.surface,
                                size: 30,
                              ),
                      ),
                    );
                  },
                ),

                const SizedBox(width: 16),

                // Next/Fast forward
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: IconButton(
                    onPressed: () {
                      // TODO: Next track
                    },
                    icon: Icon(
                      Icons.skip_next,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                      size: 22,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // +10s
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: () {
                      ref.read(audioPlayerProvider.notifier).seekForward();
                    },
                    icon: Icon(
                      Icons.forward_10,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                      size: 20,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Speed control avec indicateur
                Consumer(
                  builder: (context, ref, child) {
                    final audioState = ref.watch(audioPlayerProvider);
                    return Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: audioState.tempo != 1.0
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2)
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(22),
                        border: audioState.tempo != 1.0
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1,
                              )
                            : null,
                      ),
                      child: Stack(
                        children: [
                          IconButton(
                            onPressed: () {
                              _cycleSpeed();
                            },
                            icon: Icon(
                              Icons.speed,
                              color: audioState.tempo != 1.0
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                              size: 20,
                            ),
                          ),
                          if (audioState.tempo != 1.0)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${audioState.tempo}x',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      fontSize: 6,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sélecteur de voix hiérarchique
            _buildHierarchicalVoiceSelector(context, song),
          ],
        ));
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Theme.of(context).colorScheme.onPrimary,
        unselectedLabelColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.library_music, size: 18),
            text: 'Partition',
          ),
          Tab(
            icon: Icon(Icons.lyrics, size: 18),
            text: 'Paroles',
          ),
          Tab(
            icon: Icon(Icons.note, size: 18),
            text: 'Notes',
          ),
          Tab(
            icon: Icon(Icons.folder, size: 18),
            text: 'Ressources',
          ),
        ],
      ),
    );
  }

  Widget _buildPartitionTab(BuildContext context, Song song) {
    // Récupérer la première partition PDF depuis les ressources
    final scoreResources = song.resources?.scores
            ?.where((resource) => resource.type == 'pdf')
            .toList() ??
        [];

    final hasPartition = scoreResources.isNotEmpty;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, _showMiniPlayer ? 110 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre principal
          Text(
            'Partition',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
          ),
          const SizedBox(height: 8),
          Text(
            hasPartition
                ? 'Balayez horizontalement pour tourner les pages'
                : 'Aucune partition disponible',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontFamily: 'Poppins',
                ),
          ),
          const SizedBox(height: 24),

          if (hasPartition) ...[
            // Viewer PDF horizontal intégré avec bouton plein écran
            Container(
              height: 600, // Hauteur fixe pour le viewer
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // PDF Viewer
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildHorizontalPdfViewer(scoreResources.first),
                  ),
                  
                  // Bouton plein écran en overlay
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _openPdfFullScreen(context, scoreResources.first),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.fullscreen,
                              size: 20,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // État vide élégant
            Container(
              height: 400,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Aucune partition disponible',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'La partition PDF sera affichée ici\navec navigation horizontale',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                          fontFamily: 'Poppins',
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHorizontalPdfViewer(dynamic resource) {
    return FutureBuilder<String?>(
      key: ValueKey('horizontal_pdf_${resource.url}'),
      future: _downloadPdfIfNeeded(resource.url),
      builder: (context, snapshot) {
        if (!mounted) return const SizedBox();

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Chargement de la partition...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                        fontFamily: 'Poppins',
                      ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontFamily: 'Poppins',
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Impossible de charger la partition PDF',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                        fontFamily: 'Poppins',
                      ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        // PDF Viewer horizontal avec Syncfusion
        return SfPdfViewer.file(
          File(snapshot.data!),
          key: ValueKey('horizontal_pdf_viewer_${resource.url}'),
          // Configuration pour scroll horizontal page par page
          pageLayoutMode: PdfPageLayoutMode.single,
          scrollDirection: PdfScrollDirection.horizontal,
          enableDoubleTapZooming: true,
          enableTextSelection:
              false, // Désactiver pour éviter les conflits avec le scroll
          canShowScrollHead: false, // Pas besoin du scroll head en horizontal
          canShowScrollStatus: true, // Afficher le statut (page X/Y)
          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
            // Optionnel : callback quand le document est chargé
            if (mounted) {
              print('PDF chargé: ${details.document.pages.count} pages');
            }
          },
          onPageChanged: (PdfPageChangedDetails details) {
            // Optionnel : callback quand la page change
            if (mounted) {
              print('Page changée: ${details.newPageNumber}/');
            }
          },
        );
      },
    );
  }

  Widget _buildNoPartitionAvailable(BuildContext context) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune partition disponible',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les partitions PDF seront affichées ici\nquand elles seront disponibles',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfViewer(dynamic resource) {
    // Utiliser un cache pour éviter les appels multiples
    return FutureBuilder<String?>(
      key: ValueKey('pdf_builder_${resource.url}'),
      future: _downloadPdfIfNeeded(resource.url),
      builder: (context, snapshot) {
        // Vérifier si le widget est toujours monté
        if (!mounted) return const SizedBox();
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Chargement de la partition...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Impossible de charger la partition PDF',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Recharger seulement si le widget est monté
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        // Afficher le PDF avec gestion du cycle de vie
        return _SafePdfViewer(
          key: ValueKey('pdf_${resource.url}'),
          filePath: snapshot.data!,
          resourceUrl: resource.url,
        );
      },
    );
  }

  // Cache pour éviter les appels multiples
  static final Map<String, Future<String?>> _pdfCache = {};

  Future<String?> _downloadPdfIfNeeded(String url) async {
    // Utiliser le cache si disponible
    if (_pdfCache.containsKey(url)) {
      return _pdfCache[url];
    }

    // Créer le Future et le mettre en cache
    final future = _resolvePdfPath(url);
    _pdfCache[url] = future;

    try {
      final result = await future;
      return result;
    } catch (e) {
      // Retirer du cache en cas d'erreur pour permettre un nouveau try
      _pdfCache.remove(url);
      return null;
    }
  }

  Future<String?> _resolvePdfPath(String url) async {
    print('🔍 PDF Path Resolution:');
    print('   Original URL: $url');

    // Si c'est un fichier file:// protocol, nettoyer le chemin
    if (url.startsWith('file://')) {
      final cleanPath = url.replaceFirst('file://', '');
      print('   File protocol path: $cleanPath');
      // Mais continuons la résolution car c'est peut-être relatif
      url = cleanPath;
    }

    // Si le chemin commence par /data/, c'est probablement un chemin relatif du manifest
    // qui doit être résolu par rapport au localPath de la song

    // Récupérer le song actuel pour connaître le localPath
    final songs = ref.read(songsProvider);
    final songsList = songs.valueOrNull ?? [];
    final song = songsList.firstWhere(
      (s) => s.id == widget.songId,
      orElse: () => throw Exception('Chant non trouvé'),
    );

    print('   Song localPath: ${song.localPath}');

    if (song.localPath != null) {
      // Nettoyer le chemin relatif (supprimer le préfixe de data)
      String relativePath = url;
      if (relativePath.startsWith('/data/')) {
        final parts = relativePath.split('/');
        print('   URL parts: $parts');
        if (parts.length > 2) {
          // Prendre tout après /data/[song-folder]/
          relativePath = parts.skip(3).join('/');
        }
      }

      print('   Relative path: $relativePath');

      // Construire le chemin complet
      final fullPath = '${song.localPath}/$relativePath';
      print('   Full path to check: $fullPath');

      // Vérifier si le fichier existe
      final file = File(fullPath);
      final exists = await file.exists();
      print('   File exists: $exists');

      if (exists) {
        return fullPath;
      }

      // Si le fichier exact n'existe pas, chercher dans les dossiers communs
      final commonDirs = ['partitions', 'scores', 'pdf', 'sheet_music'];

      for (final dir in commonDirs) {
        try {
          final dirPath = Directory('${song.localPath}/$dir');
          if (await dirPath.exists()) {
            final pdfFiles = await dirPath
                .list()
                .where((entity) => entity.path.toLowerCase().endsWith('.pdf'))
                .toList();

            if (pdfFiles.isNotEmpty) {
              final foundPath = pdfFiles.first.path;
              print('   Found PDF in $dir: $foundPath');

              // Vérifier que le fichier existe vraiment avant de le retourner
              final foundFile = File(foundPath);
              if (await foundFile.exists()) {
                return foundPath;
              }
            }
          }
        } catch (e) {
          print('   Error checking directory $dir: $e');
        }
      }

      // Dernier recours : recherche récursive dans tout le répertoire du chant
      try {
        final songDir = Directory(song.localPath!);
        final allPdfs = await songDir
            .list(recursive: true)
            .where((entity) => entity.path.toLowerCase().endsWith('.pdf'))
            .toList();

        if (allPdfs.isNotEmpty) {
          final foundPath = allPdfs.first.path;
          print('   Found PDFs via recursive search: $foundPath');

          // Vérifier que le fichier existe vraiment
          final foundFile = File(foundPath);
          if (await foundFile.exists()) {
            return foundPath;
          }
        }
      } catch (e) {
        print('   Error in recursive search: $e');
      }
    }

    print('   ❌ PDF not found locally');
    return null;
  }

  void _openPdfFullScreen(BuildContext context, dynamic resource) async {
    // Résoudre le chemin du PDF avant d'ouvrir le viewer
    final resolvedPath = await _downloadPdfIfNeeded(resource.url);

    if (!mounted) return;

    if (resolvedPath != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _FullScreenPdfViewer(
            title: resource.label,
            pdfPath: resolvedPath,
          ),
        ),
      );
    } else {
      // Afficher une erreur si le PDF n'est pas trouvé
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de charger la partition ${resource.label}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Widget _buildLyricsTab(BuildContext context, Song song) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, _showMiniPlayer ? 110 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode d'affichage des paroles
          Text(
            'Affichage des paroles',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
          ),
          const SizedBox(height: 20),
          // Sélection du mode d'affichage
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      showPhonetics = false;
                      showTranslation = false;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: !showPhonetics && !showTranslation
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Paroles',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: !showPhonetics && !showTranslation
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      showPhonetics = true;
                      showTranslation = false;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: showPhonetics && !showTranslation
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Phonétique',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: showPhonetics && !showTranslation
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      showPhonetics = false;
                      showTranslation = true;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: !showPhonetics && showTranslation
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Traduction',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: !showPhonetics && showTranslation
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 20),
          ..._buildLyricsContent(context, song),
        ],
      ),
    );
  }

  List<Widget> _buildLyricsContent(BuildContext context, Song song) {
    final userVoicePart = ref.read(authProvider).user?.voicePart ?? 'soprano';

    // Vérifier si les paroles sont disponibles
    if (song.lyrics.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Text(
              'Paroles non disponibles pour ce chant',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                    fontFamily: 'Poppins',
                  ),
            ),
          ),
        ),
      ];
    }

    final lyrics = song.lyrics[userVoicePart] ?? song.lyrics.values.first;
    final phonetics = song.phonetics?[userVoicePart];
    final translation = song.translation?[userVoicePart];

    // Parsing amélioré des lignes
    final lyricsLines = lyrics.split('...');
    final phoneticLines = phonetics?.split('...') ?? [];
    final translationLines = translation?.split('...') ?? [];

    // Déterminer le contenu à afficher selon le mode
    String getCurrentContent(int index) {
      if (showPhonetics && phoneticLines.length > index) {
        return phoneticLines[index].trim();
      } else if (showTranslation && translationLines.length > index) {
        return translationLines[index].trim();
      } else {
        return lyricsLines[index].trim();
      }
    }

    Color getCurrentColor() {
      if (showPhonetics) return Theme.of(context).colorScheme.primary;
      if (showTranslation) return Theme.of(context).colorScheme.secondary;
      return Theme.of(context).colorScheme.onSurface;
    }

    return lyricsLines.asMap().entries.map((entry) {
      final index = entry.key;
      final content = getCurrentContent(index);

      return Container(
        margin: const EdgeInsets.only(bottom: 32), // Plus d'espacement
        padding: const EdgeInsets.all(24), // Plus de padding
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16), // Plus arrondi
          border: Border.all(
            color: getCurrentColor().withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Text(
          content.isEmpty ? '[Pause instrumentale]' : content,
          textAlign: TextAlign.center, // Centré pour meilleure lisibilité
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                // Police plus grande
                color: getCurrentColor(),
                fontWeight: showPhonetics ? FontWeight.w400 : FontWeight.w600,
                fontStyle: showPhonetics ? FontStyle.italic : FontStyle.normal,
                height: 1.8, // Espacement de ligne généreux
                fontSize: 22, // Police explicitement plus grande
                fontFamily: 'Poppins', // Police élégante
                letterSpacing:
                    showPhonetics ? 0.5 : 0.2, // Espacement des lettres
              ),
        ),
      );
    }).toList();
  }

  Widget _buildMaestroNotesTab(BuildContext context, Song song) {
    // Récupérer toutes les notes du Maestro (simuler différents types de notes)
    final allMaestroNotes = _getAllMaestroNotes(song);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, _showMiniPlayer ? 110 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre principal
          Text(
            'Notes de direction',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Conseils et remarques du Maestro',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontFamily: 'Poppins',
                ),
          ),
          const SizedBox(height: 32),

          // Afficher toutes les notes
          if (allMaestroNotes.isNotEmpty) ...[
            ...allMaestroNotes
                .map((note) => _buildNoteCard(context, note))
                .toList(),
          ] else ...[
            // État vide élégant
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.note_alt_outlined,
                    size: 48,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Aucune note disponible',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Le maestro n\'a pas encore ajouté de notes\npour ce chant',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                          fontFamily: 'Poppins',
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResourcesTab(BuildContext context, Song song) {
    final audioState = ref.watch(audioPlayerProvider);
    final currentPlayingSong = audioState.currentSongId == song.id;
    final currentVoice = audioState.currentVoicePart;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, _showMiniPlayer ? 110 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre principal
          Text(
            'Ressources du chant',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
          ),
          const SizedBox(height: 32),

          // Informations générales - tout dans une seule carte élégante
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Informations générales',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInfoRow(context, Icons.music_note, 'Tonalité', song.key),
                const SizedBox(height: 16),
                _buildInfoRow(context, Icons.schedule, 'Durée',
                    _formatDuration(song.duration)),
                const SizedBox(height: 16),
                _buildInfoRow(
                    context, Icons.person, 'Compositeur', song.composer),
                const SizedBox(height: 16),
                _buildInfoRow(context, Icons.calendar_today, 'Date d\'ajout',
                    _formatDate(song.createdAt)),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Fichiers audio - liste moderne et épurée
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.audiotrack,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Fichiers audio disponibles',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...song.audioUrls.entries
                    .map((entry) => _buildAudioFileItem(context, entry.key,
                        currentPlayingSong && currentVoice == entry.key))
                    .toList(),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Ressources supplémentaires - design plus épuré
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 40,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ressources supplémentaires',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aucune ressource supplémentaire disponible pour l\'instant',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                        fontFamily: 'Poppins',
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  // Récupérer toutes les notes du Maestro depuis le modèle Song
  List<MaestroNote> _getAllMaestroNotes(Song song) {
    final notes = <MaestroNote>[];

    // Récupérer les notes depuis la structure hiérarchique du Song
    // Les notes sont dans song.maestroNotes (Map<String, String>)
    // qui extrait les notes de la première voix de chaque pupitre

    if (song.maestroNotes.isNotEmpty) {
      int index = 0;
      final categories = [
        'Général',
        'Technique',
        'Expression',
        'Interprétation'
      ];
      final icons = [
        Icons.note_alt,
        Icons.air,
        Icons.trending_up,
        Icons.psychology
      ];
      final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];

      // Parcourir toutes les notes disponibles
      song.maestroNotes.forEach((voicePart, content) {
        if (content.isNotEmpty) {
          notes.add(MaestroNote(
            category: voicePart, // Utiliser directement le nom de la voix
            title: voicePart.capitalize(),
            content: content,
            icon: icons[index % icons.length],
            color: colors[index % colors.length],
          ));
          index++;
        }
      });
    }

    return notes;
  }

  // Helper pour générer un titre approprié selon le pupitre
  String _getNoteTitleForVoicePart(String voicePart) {
    switch (voicePart.toLowerCase()) {
      case 'soprano':
        return 'Conseils pour les Sopranos';
      case 'alto':
        return 'Conseils pour les Altos';
      case 'tenor':
        return 'Conseils pour les Ténors';
      case 'bass':
        return 'Conseils pour les Basses';
      case 'general':
      case 'generale':
        return 'Conseils généraux';
      default:
        return 'Conseils pour ${voicePart.capitalize()}';
    }
  }

  // Widget simple pour afficher une note sans carte
  Widget _buildNoteCard(BuildContext context, MaestroNote note) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom de la voix
          Text(
            note.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          // Contenu de la note
          Text(
            note.content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  fontFamily: 'Poppins',
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }

  // Widget pour une ligne d'information avec icône
  Widget _buildInfoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontFamily: 'Poppins',
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ],
    );
  }

  // Widget pour un fichier audio avec indicateur de lecture
  Widget _buildAudioFileItem(
      BuildContext context, String voicePart, bool isCurrentlyPlaying) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCurrentlyPlaying
            ? Theme.of(context).colorScheme.secondary.withOpacity(0.1)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentlyPlaying
              ? Theme.of(context).colorScheme.secondary.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icône de voix ou de lecture
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCurrentlyPlaying
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCurrentlyPlaying ? Icons.volume_up : Icons.music_note,
              size: 16,
              color: isCurrentlyPlaying
                  ? Theme.of(context).colorScheme.onSecondary
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),

          // Nom de la voix
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voicePart.capitalize(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: isCurrentlyPlaying
                            ? FontWeight.w700
                            : FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: isCurrentlyPlaying
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Fichier MP3 • Disponible',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                        fontFamily: 'Poppins',
                      ),
                ),
              ],
            ),
          ),

          // Indicateur de statut
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCurrentlyPlaying
                  ? Theme.of(context).colorScheme.secondary.withOpacity(0.2)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isCurrentlyPlaying ? 'En lecture' : 'Disponible',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isCurrentlyPlaying
                        ? Theme.of(context).colorScheme.secondary
                        : Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceItem(String label, String value, {Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildHierarchicalVoiceSelector(BuildContext context, Song song) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Voice Selection',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _isVoiceSelectorExpanded = !_isVoiceSelectorExpanded;
                });
              },
              icon: Icon(
                _isVoiceSelectorExpanded
                    ? Icons.expand_less
                    : Icons.expand_more,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Contenu expansible de la sélection de voix
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _isVoiceSelectorExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Niveau 1: Sélection des pupitres (chips horizontaux)
              _buildVoicePartChips(context, song),

              const SizedBox(height: 20),

              // Niveau 2: Sélection des voix (si un pupitre est sélectionné)
              if (selectedVoicePart != null) ...[
                Text(
                  'Selections',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 12),
                _buildVoiceSelections(context, song, selectedVoicePart!),
              ]
            ],
          ),
          // Version réduite quand c'est collapsed
          secondChild: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Voix: ${selectedVoicePart ?? "Aucune"}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
          ),
        ),
      ],
    );
  }

  /// Niveau 1: Chips des pupitres (Soprano, Alto, Tenor, Bass)
  Widget _buildVoicePartChips(BuildContext context, Song song) {
    if (song.voiceParts == null) return Container();

    return Wrap(
      spacing: 8,
      children: song.voiceParts!.entries.map((partEntry) {
        final partId = partEntry.key;
        final voicePart = partEntry.value;
        final isSelected = selectedVoicePart == partId;

        return GestureDetector(
          onTap: () {
            setState(() {
              selectedVoicePart = partId;
              selectedVoices.clear(); // Clear previous voice selection
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.black
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.black
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Text(
              voicePart.key,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Niveau 2: Liste des voix disponibles pour le pupitre sélectionné
  Widget _buildVoiceSelections(
      BuildContext context, Song song, String voicePartId) {
    final voicePart = song.voiceParts?[voicePartId];
    if (voicePart == null) return Container();

    return Column(
      children: voicePart.voices.entries.map((voiceEntry) {
        final voiceId = voiceEntry.key;
        final voice = voiceEntry.value;
        final isSelected = primaryVoice == voiceId;

        return GestureDetector(
          onTap: () async {
            setState(() {
              selectedVoices.clear();
              selectedVoices.add(voiceId);
              primaryVoice = voiceId;
            });

            // Jouer immédiatement la voix sélectionnée
            await ref.read(audioPlayerProvider.notifier).playSong(
                song, voicePartId); // Utilise le partId pour l'audio player
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${voice.label} (MP3)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _cycleSpeed() {
    final currentSpeed = ref.read(audioPlayerProvider).tempo;
    const speeds = [1.0, 1.25, 1.5, 0.75, 0.5];

    final currentIndex = speeds.indexOf(currentSpeed);
    final nextIndex = (currentIndex + 1) % speeds.length;
    final nextSpeed = speeds[nextIndex];

    ref.read(audioPlayerProvider.notifier).setTempo(nextSpeed);
  }
}

// Widget d'animation equalizer classique
class AudioEqualizerAnimation extends StatefulWidget {
  final bool isPlaying;
  final Color activeColor;
  final Color inactiveColor;
  final double height;
  final int barsCount;

  const AudioEqualizerAnimation({
    super.key,
    required this.isPlaying,
    required this.activeColor,
    required this.inactiveColor,
    required this.height,
    this.barsCount = 20,
  });

  @override
  State<AudioEqualizerAnimation> createState() =>
      _AudioEqualizerAnimationState();
}

class _AudioEqualizerAnimationState extends State<AudioEqualizerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<double> _barHeights;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // Initialiser les hauteurs des barres
    _barHeights = List.generate(
      widget.barsCount,
      (index) => (0.2 + Random().nextDouble() * 0.8).clamp(0.1, 1.0),
    );

    _startAnimation();
  }

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (widget.isPlaying && mounted) {
        setState(() {
          // Générer de nouvelles hauteurs aléaoires pour chaque barre
          _barHeights = List.generate(
            widget.barsCount,
            (index) => (0.1 + Random().nextDouble() * 0.9).clamp(0.1, 1.0),
          );
        });
      }
    });
  }

  @override
  void didUpdateWidget(AudioEqualizerAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPlaying != oldWidget.isPlaying) {
      if (!widget.isPlaying) {
        // Arrêter l'animation et réduire les barres
        setState(() {
          _barHeights = List.generate(widget.barsCount, (index) => 0.1);
        });
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barsCount, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            width: 3,
            height: _barHeights[index] * widget.height,
            decoration: BoxDecoration(
              color:
                  widget.isPlaying ? widget.activeColor : widget.inactiveColor,
              borderRadius: BorderRadius.circular(1.5),
            ),
          );
        }),
      ),
    );
  }
}

// Widget PDF sécurisé avec gestion du cycle de vie
class _SafePdfViewer extends StatefulWidget {
  final String filePath;
  final String resourceUrl;

  const _SafePdfViewer({
    super.key,
    required this.filePath,
    required this.resourceUrl,
  });

  @override
  State<_SafePdfViewer> createState() => _SafePdfViewerState();
}

class _SafePdfViewerState extends State<_SafePdfViewer> {
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          if (!_isDisposed && mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => _FullScreenPdfViewer(
                  title: 'Partition',
                  pdfPath: widget.filePath,
                ),
              ),
            );
          }
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SfPdfViewer.file(
              File(widget.filePath),
              enableDoubleTapZooming: true,
              enableTextSelection: true,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              canShowPaginationDialog: true,
              onPageChanged: (PdfPageChangedDetails details) {
                // Vérifier si le widget est encore monté avant setState
                if (!_isDisposed && mounted) {
                  // Aucun setState nécessaire ici pour éviter les erreurs
                }
              },
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                if (!_isDisposed && mounted) {
                  // Aucun setState nécessaire ici pour éviter les erreurs
                }
              },
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                if (!_isDisposed && mounted) {
                  print('Erreur de chargement PDF: ${details.error}');
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Widget pour la vue plein écran du PDF
class _FullScreenPdfViewer extends StatefulWidget {
  final String title;
  final String pdfPath;

  const _FullScreenPdfViewer({
    required this.title,
    required this.pdfPath,
  });

  @override
  State<_FullScreenPdfViewer> createState() => _FullScreenPdfViewerState();
}

class _FullScreenPdfViewerState extends State<_FullScreenPdfViewer> {
  int currentPage = 0;
  int totalPages = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.7),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (totalPages > 0)
              Text(
                'Page ${currentPage + 1} sur $totalPages',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Partager le PDF
            },
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: SfPdfViewer.file(
        File(widget.pdfPath),
        enableDoubleTapZooming: true,
        enableTextSelection: true,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        onPageChanged: (PdfPageChangedDetails details) {
          setState(() {
            currentPage = details.newPageNumber - 1;
          });
        },
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          setState(() {
            totalPages = details.document.pages.count;
          });
        },
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          print('Erreur PDF plein écran: ${details.description}');
        },
      ),
    );
  }
}

// Delegate pour SliverPersistentHeader qui maintient le TabBar fixé
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverTabBarDelegate({required this.child});

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
