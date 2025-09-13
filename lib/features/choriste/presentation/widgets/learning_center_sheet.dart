import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';

import '../../../../i18n/strings.g.dart';
import '../../../audio/providers/audio_player_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../models/song_model.dart';
import '../../providers/songs_provider.dart';

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
  bool _isPlayerCollapsed = false;
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

    // Initialiser avec la voix de l'utilisateur une fois que ref est disponible
    if (selectedVoices.isEmpty) {
      final user = ref.read(authProvider).user;
      if (user?.voicePart != null) {
        primaryVoice = user!.voicePart;
        selectedVoices.add(user.voicePart!);
      }
    }
  }

  void _onScroll() {
    const threshold = 50.0; // Seuil de scroll plus bas pour plus de fluidité
    final shouldCollapse = _scrollController.offset > threshold;

    if (shouldCollapse != _isPlayerCollapsed) {
      if (mounted) {
        setState(() {
          _isPlayerCollapsed = shouldCollapse;
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
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverToBoxAdapter(
                    child: _buildHeader(context, song),
                  ),
                  SliverToBoxAdapter(
                    child: _buildExpandablePlayer(context, song),
                  ),
                  SliverToBoxAdapter(
                    child: _buildTabBar(context),
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

  Widget _buildExpandablePlayer(BuildContext context, Song song) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isPlayerCollapsed ? 60 : null,
      child: _isPlayerCollapsed
          ? _buildMiniPlayer(context, song)
          : _buildCompactPlayer(context, song),
    );
  }

  Widget _buildMiniPlayer(BuildContext context, Song song) {
    return Container(
      height: 60,
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
      child: Row(
        children: [
          // Progress bar verticale
          Consumer(
            builder: (context, ref, child) {
              final audioState = ref.watch(audioPlayerProvider);
              final progress = audioState.duration.inMilliseconds > 0
                  ? (audioState.position.inMilliseconds /
                          audioState.duration.inMilliseconds)
                      .clamp(0.0, 1.0)
                  : 0.0;

              return Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.bottomCenter,
                  heightFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 12),

          // Play/Pause button
          Consumer(
            builder: (context, ref, child) {
              final audioState = ref.watch(audioPlayerProvider);
              return Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: IconButton(
                  onPressed: () {
                    if (audioState.isPlaying) {
                      ref.read(audioPlayerProvider.notifier).pause();
                    } else {
                      ref.read(audioPlayerProvider.notifier).play();
                    }
                  },
                  icon: Icon(
                    audioState.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 12),

          // Song info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  song.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final audioState = ref.watch(audioPlayerProvider);
                    return Text(
                      '${_formatDuration(audioState.position)} / ${_formatDuration(audioState.duration)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

          // Expand button
          IconButton(
            onPressed: () {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
            icon: Icon(
              Icons.keyboard_arrow_up,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPlayer(BuildContext context, Song song) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Barre de progression avec curseur
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
                    const SizedBox(height: 16),
                    // 🎵 Equalizer Animation
                    Container(
                      height: 80,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: AudioEqualizerAnimation(
                        isPlaying: audioState.isPlaying,
                        activeColor: Theme.of(context).colorScheme.primary,
                        inactiveColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.3),
                        height: 64,
                        barsCount: 20,
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
                          if (audioState.isPlaying) {
                            ref.read(audioPlayerProvider.notifier).pause();
                          } else {
                            ref.read(audioPlayerProvider.notifier).play();
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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Contrôles de la partition
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Partition interactive',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    // TODO: Zoom out
                  },
                  icon: const Icon(Icons.zoom_out),
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                IconButton(
                  onPressed: () {
                    // TODO: Zoom in
                  },
                  icon: const Icon(Icons.zoom_in),
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Placeholder pour partition interactive
        Container(
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
                Icons.library_music,
                size: 32,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'Partition interactive',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'La note en cours sera mise en évidence\nau fur et à mesure de la lecture',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLyricsTab(BuildContext context, Song song) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Contrôles des paroles
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paroles et phonétique',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Toggle phonétique
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Phonétique',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Switch(
                        value: showPhonetics,
                        onChanged: (value) {
                          setState(() {
                            showPhonetics = value;
                          });
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),

                // Toggle traduction
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Traduction',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Switch(
                        value: showTranslation,
                        onChanged: (value) {
                          setState(() {
                            showTranslation = value;
                          });
                        },
                        activeColor: Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Contenu des paroles
        ..._buildLyricsContent(context, song),
      ],
    );
  }

  List<Widget> _buildLyricsContent(BuildContext context, Song song) {
    final userVoicePart = ref.read(authProvider).user?.voicePart ?? 'soprano';
    
    // Vérifier si les paroles sont disponibles
    if (song.lyrics.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(20),
          child: const Center(
            child: Text(
              'Paroles non disponibles pour ce chant',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        ),
      ];
    }
    
    final lyrics = song.lyrics[userVoicePart] ?? song.lyrics.values.first;
    final phonetics = song.phonetics?[userVoicePart];
    final translation = song.translation?[userVoicePart];

    // Simuler des lignes de paroles
    final lyricsLines = lyrics.split('...');
    final phoneticLines = phonetics?.split('...') ?? [];
    final translationLines = translation?.split('...') ?? [];

    return lyricsLines.asMap().entries.map((entry) {
      final index = entry.key;
      final line = entry.value.trim();

      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Paroles originales
            Text(
              line.isEmpty ? '[Instrumental]' : line,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
            ),

            // Phonétique
            if (showPhonetics &&
                phoneticLines.length > index &&
                phoneticLines[index].trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                phoneticLines[index].trim(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontStyle: FontStyle.italic,
                      height: 1.3,
                    ),
              ),
            ],

            // Traduction
            if (showTranslation &&
                translationLines.length > index &&
                translationLines[index].trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  translationLines[index].trim(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                        height: 1.3,
                      ),
                ),
              ),
            ],
          ],
        ),
      );
    }).toList();
  }

  Widget _buildMaestroNotesTab(BuildContext context, Song song) {
    final userVoicePart = ref.read(authProvider).user?.voicePart ?? 'soprano';
    final notes = song.maestroNotes[userVoicePart] ?? '';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Notes du Maestro',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        Text(
          'Pour votre voix: ${userVoicePart.capitalize()}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 20),
        if (notes.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.note_alt,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Conseils personnalisés',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  notes,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.note_alt_outlined,
                  size: 48,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune note disponible',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Le maestro n\'a pas encore ajouté\nde notes pour cette voix',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResourcesTab(BuildContext context, Song song) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Ressources',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 20),

        // Informations générales
        _buildResourceSection(
          context,
          'Informations générales',
          Icons.info_outline,
          Theme.of(context).colorScheme.primary,
          [
            _buildResourceItem('Tonalité', song.key),
            _buildResourceItem('Durée', _formatDuration(song.duration)),
            _buildResourceItem('Compositeur', song.composer),
            _buildResourceItem('Date d\'ajout', _formatDate(song.createdAt)),
          ],
        ),

        const SizedBox(height: 24),

        // Fichiers audio disponibles
        _buildResourceSection(
          context,
          'Fichiers audio',
          Icons.audiotrack,
          Theme.of(context).colorScheme.secondary,
          song.audioUrls.entries.map((entry) {
            return _buildResourceItem(
              '${entry.key.capitalize()} (MP3)',
              'Disponible',
              trailing: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 16,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Placeholder pour ressources supplémentaires
        _buildResourceSection(
          context,
          'Ressources supplémentaires',
          Icons.folder_outlined,
          Theme.of(context).colorScheme.tertiary,
          [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 32,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aucune ressource supplémentaire',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                  Text(
                    'Le maestro peut ajouter des PDF, enregistrements, etc.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
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
    // Utiliser la nouvelle structure hiérarchique ou fallback vers l'ancienne
    final availableVoices = song.allAvailableVoices.keys.toList();

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

  /// Affichage hiérarchique des voix (nouvelle structure)
  Widget _buildHierarchicalVoiceChips(BuildContext context, Song song) {
    if (song.voiceParts == null) return Container();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: song.voiceParts!.entries.map((partEntry) {
        final partId = partEntry.key;
        final voicePart = partEntry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre du pupitre
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                voicePart.key,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            // Voix du pupitre
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: voicePart.voices.entries.map((voiceEntry) {
                final voiceId = voiceEntry.key;
                final voice = voiceEntry.value;
                final isSelected = selectedVoices.contains(voiceId);

                return GestureDetector(
                  onTap: () async {
                    setState(() {
                      if (isSelected) {
                        selectedVoices.remove(voiceId);
                      } else {
                        selectedVoices.add(voiceId);
                      }
                      if (selectedVoices.isEmpty) {
                        selectedVoices.add(voiceId);
                      }
                      if (selectedVoices.length == 1) {
                        primaryVoice = selectedVoices.first;
                      }
                    });

                    if (selectedVoices.length == 1) {
                      await ref
                          .read(audioPlayerProvider.notifier)
                          .playSong(song, selectedVoices.first);
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      voice.label,
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  /// Affichage simple des voix (ancienne structure)
  Widget _buildSimpleVoiceChips(
      BuildContext context, Song song, List<String> availableVoices) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: availableVoices.map((voiceKey) {
        final voiceLabels = {
          'soprano': 'Soprano',
          'alto': 'Alto',
          'tenor': 'Ténor',
          'bass': 'Basse',
        };
        final voice = voiceLabels[voiceKey.toLowerCase()] ??
            voiceKey[0].toUpperCase() + voiceKey.substring(1);
        final isSelected = selectedVoices.contains(voiceKey.toLowerCase());

        return GestureDetector(
          onTap: () async {
            setState(() {
              if (isSelected) {
                selectedVoices.remove(voiceKey.toLowerCase());
              } else {
                selectedVoices.add(voiceKey.toLowerCase());
              }
              if (selectedVoices.isEmpty) {
                selectedVoices.add(voiceKey.toLowerCase());
              }
              if (selectedVoices.length == 1) {
                primaryVoice = selectedVoices.first;
              }
            });

            if (selectedVoices.length == 1) {
              final newVoicePart = selectedVoices.first;
              await ref
                  .read(audioPlayerProvider.notifier)
                  .playSong(song, newVoicePart);
            }
          },
          child: Container(
            width: 70,
            height: 35,
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                voice,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.surface
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<double> _generateFallbackWaveform() {
    // Fallback simple si pas de données de waveform disponibles
    return List.generate(50, (index) => 0.3 + 0.4 * ((index * 7) % 10 / 10));
  }

  /// Barre de progression fallback si pas de waveform
  Widget _buildFallbackProgressBar(BuildContext context, double progress) {
    return Container(
      width: double.infinity,
      height: 3,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
        borderRadius: BorderRadius.circular(1.5),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
      ),
    );
  }
}

// CustomPainter pour la visualisation en forme d'onde style spectrogramme
class SpectrogramWaveformPainter extends CustomPainter {
  final List<double> samples;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final double scrollOffset;
  final double viewportWidth;

  SpectrogramWaveformPainter({
    required this.samples,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    this.scrollOffset = 0.0,
    this.viewportWidth = 300.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final paint = Paint()
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.butt;

    // Calculer la position du curseur de lecture qui suit le scroll
    final totalWidth = size.width;
    final barWidth = totalWidth / samples.length;

    // Position absolue du curseur de lecture dans le spectrogramme complet
    final absoluteProgressPosition = totalWidth * progress;

    // Position relative du curseur par rapport au viewport visible
    final relativeProgressPosition = absoluteProgressPosition - scrollOffset;

    for (int i = 0; i < samples.length; i++) {
      final x = i * barWidth;

      // Une barre est active si elle est avant la position de lecture
      final isActive = x <= absoluteProgressPosition;

      // Effet de highlight pour la barre actuellement en cours de lecture
      final isCurrentlyPlaying =
          (x - barWidth / 2) <= relativeProgressPosition &&
              relativeProgressPosition <= (x + barWidth / 2) &&
              relativeProgressPosition >= 0 &&
              relativeProgressPosition <= viewportWidth;

      // Normaliser la hauteur entre 0.1 et 1.0 pour éviter les barres trop petites
      final normalizedHeight = (samples[i] * 0.9 + 0.1).clamp(0.1, 1.0);
      final barHeight = size.height * normalizedHeight;

      // Choisir la couleur appropriée
      if (isCurrentlyPlaying) {
        // Couleur de highlight pour la barre en cours de lecture
        paint.color = activeColor.withOpacity(1.0);
      } else if (isActive) {
        // Couleur active pour les barres déjà lues
        paint.color = activeColor.withOpacity(0.7);
      } else {
        // Couleur inactive pour les barres pas encore lues
        paint.color = inactiveColor;
      }

      // Dessiner des barres verticales fines comme un spectrogramme
      canvas.drawLine(
        Offset(x + barWidth / 2, (size.height - barHeight) / 2),
        Offset(x + barWidth / 2, (size.height + barHeight) / 2),
        paint,
      );
    }

    // Dessiner un curseur de lecture vertical fin
    if (relativeProgressPosition >= 0 &&
        relativeProgressPosition <= viewportWidth) {
      final cursorPaint = Paint()
        ..color = activeColor
        ..strokeWidth = 2.0;

      canvas.drawLine(
        Offset(relativeProgressPosition, 0),
        Offset(relativeProgressPosition, size.height),
        cursorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(SpectrogramWaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.samples != samples ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.viewportWidth != viewportWidth;
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
  State<AudioEqualizerAnimation> createState() => _AudioEqualizerAnimationState();
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
      (index) => 0.2 + Random().nextDouble() * 0.8,
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
            (index) => 0.1 + Random().nextDouble() * 0.9,
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
              color: widget.isPlaying 
                  ? widget.activeColor
                  : widget.inactiveColor,
              borderRadius: BorderRadius.circular(1.5),
            ),
          );
        }),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
