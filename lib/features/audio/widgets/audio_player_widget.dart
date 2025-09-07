import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/strings.g.dart';
import '../providers/audio_player_provider.dart';

class AudioPlayerWidget extends ConsumerStatefulWidget {
  final Map<String, String> audioUrls;
  final String primaryVoicePart;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrls,
    required this.primaryVoicePart,
  });

  @override
  ConsumerState<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends ConsumerState<AudioPlayerWidget> {
  bool _showVoiceMixer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioPlayerProvider.notifier).loadSong(
        widget.audioUrls,
        widget.primaryVoicePart,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioPlayerProvider);
    final t = Translations.of(context);

    if (audioState.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (audioState.error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Erreur de lecture audio',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                audioState.error!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlue.withOpacity(0.05),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // En-tête avec titre et contrôles
            _buildHeader(),
            const SizedBox(height: 20),

            // Barre de progression avec style amélioré
            _buildProgressSection(audioState),
            const SizedBox(height: 24),

            // Contrôles principaux avec design moderne
            _buildMainControls(audioState),
            const SizedBox(height: 20),

            // Contrôles rapides en ligne
            _buildQuickControls(audioState),

            // Mixeur de voix (collapsible) avec animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _showVoiceMixer ? null : 0,
              child: _showVoiceMixer 
                  ? Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildVoiceMixer(audioState),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildVoiceMixer(AudioPlayerState audioState) {
    final voiceParts = ['soprano', 'alto', 'tenor', 'bass'];
    final voiceLabels = {
      'soprano': 'Soprano',
      'alto': 'Alto',
      'tenor': 'Ténor',
      'bass': 'Basse',
    };
    
    final voiceIcons = {
      'soprano': Icons.music_note,
      'alto': Icons.queue_music,
      'tenor': Icons.library_music,
      'bass': Icons.speaker,
    };

    final voiceColors = {
      'soprano': const Color(0xFF9C27B0),
      'alto': const Color(0xFF2196F3),
      'tenor': const Color(0xFF4CAF50),
      'bass': const Color(0xFFFF5722),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade50,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du mixeur
          Row(
            children: [
              Icon(
                Icons.equalizer,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Mixage des Voix',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'SATB',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Contrôles de voix
          ...voiceParts.map((voicePart) {
            final volume = audioState.voiceVolumes[voicePart] ?? 1.0;
            final isCurrentVoice = voicePart == widget.primaryVoicePart;
            final voiceColor = voiceColors[voicePart]!;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrentVoice ? voiceColor.withOpacity(0.05) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrentVoice ? voiceColor.withOpacity(0.2) : Colors.grey.shade200,
                  width: isCurrentVoice ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Icône et nom de la voix
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: voiceColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      voiceIcons[voicePart],
                      color: voiceColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 60,
                    child: Text(
                      voiceLabels[voicePart]!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isCurrentVoice ? FontWeight.bold : FontWeight.w500,
                        color: isCurrentVoice ? voiceColor : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  
                  // Slider
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: voiceColor,
                        thumbColor: voiceColor,
                        inactiveTrackColor: voiceColor.withOpacity(0.2),
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      ),
                      child: Slider(
                        value: volume,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (value) {
                          ref.read(audioPlayerProvider.notifier).setVoiceVolume(voicePart, value);
                        },
                      ),
                    ),
                  ),
                  
                  // Indicateur de volume
                  Container(
                    width: 40,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${(volume * 100).round()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: voiceColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.music_note,
            color: AppTheme.primaryBlue,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lecteur Audio',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
              Text(
                'Mixage multi-pistes',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _showVoiceMixer ? AppTheme.primaryBlue : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: Icon(
              Icons.tune,
              color: _showVoiceMixer ? Colors.white : Colors.grey.shade600,
            ),
            onPressed: () {
              setState(() {
                _showVoiceMixer = !_showVoiceMixer;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(AudioPlayerState audioState) {
    return Column(
      children: [
        // Temps
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(audioState.position),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
              ),
            ),
            Text(
              _formatDuration(audioState.duration),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Barre de progression améliorée avec Slider natif
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.primaryBlue,
              inactiveTrackColor: Colors.grey.shade300,
              thumbColor: AppTheme.primaryBlue,
              overlayColor: AppTheme.primaryBlue.withOpacity(0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: audioState.duration.inMilliseconds > 0 
                  ? audioState.position.inMilliseconds / audioState.duration.inMilliseconds
                  : 0.0,
              min: 0.0,
              max: 1.0,
              onChanged: (value) {
                final newPosition = Duration(
                  milliseconds: (value * audioState.duration.inMilliseconds).round(),
                );
                ref.read(audioPlayerProvider.notifier).seek(newPosition);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainControls(AudioPlayerState audioState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Bouton Reset avec style
        _buildControlButton(
          icon: Icons.refresh,
          onPressed: () => ref.read(audioPlayerProvider.notifier).resetSettings(),
          isSecondary: true,
        ),
        // Bouton Play/Pause principal
        GestureDetector(
          onTap: () {
            if (audioState.isPlaying) {
              ref.read(audioPlayerProvider.notifier).pause();
            } else {
              ref.read(audioPlayerProvider.notifier).play();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryBlue,
                  AppTheme.primaryBlue.withOpacity(0.8),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              audioState.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        // Bouton Skip (placeholder)
        _buildControlButton(
          icon: Icons.skip_next,
          onPressed: () {}, // Placeholder
          isSecondary: true,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isSecondary = false,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isSecondary ? Colors.grey.shade100 : AppTheme.primaryBlue,
        shape: BoxShape.circle,
        border: isSecondary ? Border.all(color: Colors.grey.shade300) : null,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isSecondary ? Colors.grey.shade600 : Colors.white,
          size: 24,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildQuickControls(AudioPlayerState audioState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactControl(
              icon: Icons.speed,
              label: 'Tempo',
              value: '${(audioState.tempo * 100).round()}%',
              slider: Slider(
                value: audioState.tempo,
                min: 0.5,
                max: 1.5,
                divisions: 20,
                activeColor: AppTheme.primaryBlue,
                inactiveColor: Colors.grey.shade300,
                onChanged: (value) {
                  ref.read(audioPlayerProvider.notifier).setTempo(value);
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildCompactControl(
              icon: Icons.volume_up,
              label: 'Volume',
              value: '${(audioState.masterVolume * 100).round()}%',
              slider: Slider(
                value: audioState.masterVolume,
                min: 0.0,
                max: 1.0,
                activeColor: AppTheme.primaryBlue,
                inactiveColor: Colors.grey.shade300,
                onChanged: (value) {
                  ref.read(audioPlayerProvider.notifier).setMasterVolume(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactControl({
    required IconData icon,
    required String label,
    required String value,
    required Widget slider,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryBlue),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        slider,
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
