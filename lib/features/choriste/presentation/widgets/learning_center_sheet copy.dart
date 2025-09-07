import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  // État des voix sélectionnées pour le mélange
  Set<String> selectedVoices = {};
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
    const threshold = 100.0; // Seuil de scroll pour réduire le lecteur
    final shouldCollapse = _scrollController.offset > threshold;

    if (shouldCollapse != _isPlayerCollapsed) {
      setState(() {
        _isPlayerCollapsed = shouldCollapse;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
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
    final song = songs.firstWhere((s) => s.id == widget.songId);

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
              0, MediaQuery.of(context).size.height * _slideAnimation.value),
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Header fixe
                SliverToBoxAdapter(
                  child: _buildHeader(context, song),
                ),
                // Lecteur audio qui se réduit
                SliverToBoxAdapter(
                  child: _buildExpandablePlayer(context, song),
                ),
                // Onglets
                SliverToBoxAdapter(
                  child: _buildTabBar(context),
                ),
                // Contenu des onglets
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPartitionTab(context, song),
                      _buildLyricsTab(context, song),
                      _buildMaestroNotesTab(context, song),
                      _buildResourcesTab(context, song),
                    ],
                  ),
                ),
              ],
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
            // Visualisation audio en forme d'onde
            Container(
              height: 80,
              width: double.infinity,
              child: CustomPaint(
                painter: WaveformPainter(
                  progress:
                      ref.watch(audioPlayerProvider).duration.inMilliseconds > 0
                          ? (ref
                                      .watch(audioPlayerProvider)
                                      .position
                                      .inMilliseconds /
                                  ref
                                      .watch(audioPlayerProvider)
                                      .duration
                                      .inMilliseconds)
                              .clamp(0.0, 1.0)
                          : 0.0,
                  primaryColor: Theme.of(context).colorScheme.onSurface,
                  backgroundColor:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                ),
              ),
            ),

            const SizedBox(height: 16),

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
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor:
                            Theme.of(context).colorScheme.onSurface,
                        inactiveTrackColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.2),
                        thumbColor: Theme.of(context).colorScheme.onSurface,
                        overlayColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.1),
                        trackHeight: 3,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: progress,
                        onChanged: (value) {
                          final newPosition = Duration(
                            milliseconds:
                                (value * audioState.duration.inMilliseconds)
                                    .round(),
                          );
                          ref
                              .read(audioPlayerProvider.notifier)
                              .seek(newPosition);
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(audioState.position),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                        ),
                        Text(
                          _formatDuration(audioState.duration),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                        ),
                      ],
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
                      final audioState = ref.read(audioPlayerProvider);
                      ref.read(audioPlayerProvider.notifier).seek(
                            Duration(
                              milliseconds: (audioState
                                          .position.inMilliseconds -
                                      10000)
                                  .clamp(0, audioState.duration.inMilliseconds),
                            ),
                          );
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
                      final audioState = ref.read(audioPlayerProvider);
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
                        icon: Icon(
                          audioState.isPlaying ? Icons.pause : Icons.play_arrow,
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
                      final audioState = ref.read(audioPlayerProvider);
                      ref.read(audioPlayerProvider.notifier).seek(
                            Duration(
                              milliseconds: (audioState
                                          .position.inMilliseconds +
                                      10000)
                                  .clamp(0, audioState.duration.inMilliseconds),
                            ),
                          );
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

                // Speed control
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
                      _showSpeedControl(context);
                    },
                    icon: Icon(
                      Icons.speed,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                      size: 20,
                    ),
                  ),
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
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Contrôles de la partition
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Partition interactive',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      // TODO: Zoom out
                    },
                    icon: const Icon(Icons.zoom_out),
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: Zoom in
                    },
                    icon: const Icon(Icons.zoom_in),
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Placeholder pour partition interactive
          Expanded(
            child: Container(
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
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
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsTab(BuildContext context, Song song) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
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
          Expanded(
            child: SingleChildScrollView(
              child: _buildLyricsContent(context, song),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsContent(BuildContext context, Song song) {
    final userVoicePart = ref.read(authProvider).user?.voicePart ?? 'soprano';
    final lyrics = song.lyrics[userVoicePart] ?? song.lyrics.values.first;
    final phonetics = song.phonetics?[userVoicePart];
    final translation = song.translation?[userVoicePart];

    // Simuler des lignes de paroles
    final lyricsLines = lyrics.split('...');
    final phoneticLines = phonetics?.split('...') ?? [];
    final translationLines = translation?.split('...') ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lyricsLines.asMap().entries.map((entry) {
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
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.1),
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
      }).toList(),
    );
  }

  Widget _buildMaestroNotesTab(BuildContext context, Song song) {
    final userVoicePart = ref.read(authProvider).user?.voicePart ?? 'soprano';
    final notes = song.maestroNotes[userVoicePart] ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
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
      ),
    );
  }

  Widget _buildResourcesTab(BuildContext context, Song song) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                _buildResourceItem(
                    'Date d\'ajout', _formatDate(song.createdAt)),
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
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2),
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
        ),
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
    final availableVoices = song.audioUrls.keys.toList();

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
                _isVoiceSelectorExpanded ? Icons.expand_less : Icons.expand_more,
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
              // Puces de catégories de voix
              Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ['Soprano', 'Alto', 'Tenor', 'Bass'].map((voice) {
            final isSelected = selectedVoices.contains(voice.toLowerCase());
            final hasAudio = song.audioUrls.containsKey(voice.toLowerCase());

            return GestureDetector(
              onTap: hasAudio
                  ? () {
                      setState(() {
                        if (isSelected) {
                          selectedVoices.remove(voice.toLowerCase());
                        } else {
                          selectedVoices.add(voice.toLowerCase());
                        }
                        if (selectedVoices.isEmpty) {
                          // Au moins une voix doit être sélectionnée
                          selectedVoices.add(voice.toLowerCase());
                        }
                        if (selectedVoices.length == 1) {
                          primaryVoice = selectedVoices.first;
                        }
                      });
                    }
                  : null,
              child: Container(
                width: 70,
                height: 35,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onSurface
                      : hasAudio
                          ? Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.1)
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.05),
                  borderRadius: BorderRadius.circular(18),
                  border: hasAudio
                      ? null
                      : Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.2),
                        ),
                ),
                child: Center(
                  child: Text(
                    voice,
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.surface
                          : hasAudio
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.4),
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Section sélections détaillées
        Text(
          'Selections',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
        const SizedBox(height: 12),

        // Liste des pistes audio spécifiques
        ...selectedVoices.map((voice) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: voice == primaryVoice
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: voice == primaryVoice ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: voice == primaryVoice
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
                    '${voice.capitalize()} ${voice.capitalize()} 2 (MIDI)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    // TODO: Handle audio type selection
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'midi', child: Text('MIDI')),
                    const PopupMenuItem(value: 'mp3', child: Text('MP3')),
                    const PopupMenuItem(
                        value: 'maestro', child: Text('Maestro Rec.')),
                  ],
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        }).toList(),

        // Si on a seulement une voix sélectionnée, afficher l'option Maestro
        if (selectedVoices.length == 1) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${selectedVoices.first.capitalize()} (Maestro Rec.)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    // TODO: Handle maestro recording
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'maestro', child: Text('Maestro Rec.')),
                  ],
                  child: Icon(
                    Icons.keyboard_arrow_down,
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

        const SizedBox(height: 16),

        // Bouton Full Choir
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: selectedVoices.length == availableVoices.length
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              ),
            ),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (selectedVoices.length == availableVoices.length) {
                    // Si toutes sont sélectionnées, revenir à la voix principale
                    selectedVoices.clear();
                    if (primaryVoice != null) {
                      selectedVoices.add(primaryVoice!);
                    }
                  } else {
                    // Sélectionner toutes les voix
                    selectedVoices = Set.from(availableVoices);
                  }
                });
              },
              child: Text(
                'Full Choir',
                style: TextStyle(
                  color: selectedVoices.length == availableVoices.length
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
            ],
          ),
          // Version réduite quand c'est collapsed
          secondChild: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '${selectedVoices.length} voix sélectionnée${selectedVoices.length > 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSpeedControl(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vitesse de lecture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('0.5x'),
              onTap: () {
                // TODO: Set speed to 0.5x
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('0.75x'),
              onTap: () {
                // TODO: Set speed to 0.75x
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('1.0x (Normal)'),
              onTap: () {
                // TODO: Set speed to 1.0x
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('1.25x'),
              onTap: () {
                // TODO: Set speed to 1.25x
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('1.5x'),
              onTap: () {
                // TODO: Set speed to 1.5x
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// CustomPainter pour la visualisation en forme d'onde
class WaveformPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color backgroundColor;

  WaveformPainter({
    required this.progress,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final progressPoint = size.width * progress;
    final barCount = 60;
    final barWidth = size.width / barCount;

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth + barWidth / 2;
      final isActive = x <= progressPoint;

      // Générer une hauteur aléatoire mais cohérente pour chaque barre
      final heightFactor = _generateHeight(i, barCount);
      final barHeight = size.height * heightFactor;

      paint.color = isActive ? primaryColor : backgroundColor;

      canvas.drawLine(
        Offset(x, (size.height - barHeight) / 2),
        Offset(x, (size.height + barHeight) / 2),
        paint,
      );
    }
  }

  double _generateHeight(int index, int total) {
    // Générer une forme d'onde réaliste basée sur l'index
    final normalizedIndex = index / total;

    // Créer une courbe qui ressemble à une forme d'onde audio
    final base = (0.3 + 0.7 * (1 - (normalizedIndex - 0.5).abs() * 2));
    final variation = 0.3 * ((index * 37) % 100) / 100; // Pseudo-aléatoire

    return (base + variation).clamp(0.1, 1.0);
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
