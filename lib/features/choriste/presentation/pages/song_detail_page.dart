import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../i18n/strings.g.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../audio/widgets/audio_player_widget.dart';
import '../../providers/songs_provider.dart';
import '../../models/song_model.dart';
import '../widgets/voice_part_tabs.dart';
import '../widgets/song_content_section.dart';

class SongDetailPage extends ConsumerStatefulWidget {
  final String songId;

  const SongDetailPage({
    super.key,
    required this.songId,
  });

  @override
  ConsumerState<SongDetailPage> createState() => _SongDetailPageState();
}

class _SongDetailPageState extends ConsumerState<SongDetailPage> {
  String? _selectedVoicePart;

  @override
  void initState() {
    super.initState();
    // Initialiser avec le pupitre de l'utilisateur
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user?.voicePart != null) {
        setState(() {
          _selectedVoicePart = user!.voicePart;
        }); 
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user!;
    final songs = ref.watch(songsProvider);
    final songsList = songs.valueOrNull ?? [];
    final song = songsList.firstWhere(
      (s) => s.id == widget.songId,
      orElse: () => throw Exception('Chant non trouvé'),
    );
    final t = Translations.of(context);

    // Utiliser le pupitre de l'utilisateur par défaut
    final currentVoicePart = _selectedVoicePart ?? user.voicePart!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(song.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/choriste'),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Breadcrumb navigation
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.go('/choriste'),
                  child: Text(
                    t.dashboard.repertoire,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  ' > ',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
                Expanded(
                  child: Text(
                    song.title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Onglets des pupitres
          VoicePartTabs(
            selectedVoicePart: currentVoicePart,
            userVoicePart: user.voicePart!,
            onVoicePartChanged: (voicePart) {
              setState(() {
                _selectedVoicePart = voicePart;
              });
            },
          ),

          // Contenu principal
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sélecteur de statut personnel
                 

                  const SizedBox(height: 24),

                  // Informations du chant
                  _buildSongInfo(context, song, currentVoicePart, t),

                  const SizedBox(height: 24),

                  // Lecteur audio complet
                  AudioPlayerWidget(
                    audioUrls: song.audioUrls,
                    primaryVoicePart: currentVoicePart,
                  ),

                  const SizedBox(height: 24),

                  // Contenu du chant (paroles, phonétique, traduction)
                  SongContentSection(
                    song: song,
                    voicePart: currentVoicePart,
                  ),

                  const SizedBox(height: 24),

                  // Notes du maestro
                  _buildMaestroNotes(context, song, currentVoicePart, t),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongInfo(
      BuildContext context, Song song, String voicePart, Translations t) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(t.song.composer, song.composer),
            const SizedBox(height: 8),
            _buildInfoRow('${t.song.key} générale', song.key),
            const SizedBox(height: 8),
            _buildInfoRow(
              '${t.song.key} ${_getVoicePartLabel(voicePart)}',
              song.voicePartKeys[voicePart] ?? song.key,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaestroNotes(
      BuildContext context, Song song, String voicePart, Translations t) {
    final notes = song.maestroNotes[voicePart];

    if (notes == null || notes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.music_video_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  t.song.maestroNotes,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                notes,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getVoicePartLabel(String voicePart) {
    switch (voicePart) {
      case 'soprano':
        return 'Soprano';
      case 'alto':
        return 'Alto';
      case 'tenor':
        return 'Ténor';
      case 'bass':
        return 'Basse';
      default:
        return voicePart;
    }
  }
}
