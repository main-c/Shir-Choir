import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

import '../../choriste/models/song_model.dart';

class AudioPlayerState {
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final double tempo;
  final double masterVolume;
  final Map<String, double> voiceVolumes;
  final String? currentVoicePart;
  final String? error;
  final String? currentSongId;
  final String? currentSongTitle;

  const AudioPlayerState({
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.tempo = 1.0,
    this.masterVolume = 1.0,
    this.voiceVolumes = const {},
    this.currentVoicePart,
    this.error,
    this.currentSongId,
    this.currentSongTitle,
  });

  AudioPlayerState copyWith({
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    double? tempo,
    double? masterVolume,
    Map<String, double>? voiceVolumes,
    String? currentVoicePart,
    String? error,
    String? currentSongId,
    String? currentSongTitle,
  }) {
    return AudioPlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      tempo: tempo ?? this.tempo,
      masterVolume: masterVolume ?? this.masterVolume,
      voiceVolumes: voiceVolumes ?? this.voiceVolumes,
      currentVoicePart: currentVoicePart ?? this.currentVoicePart,
      error: error ?? this.error,
      currentSongId: currentSongId ?? this.currentSongId,
      currentSongTitle: currentSongTitle ?? this.currentSongTitle,
    );
  }
}

class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  final Map<String, AudioPlayer> _players = {};
  final List<StreamSubscription> _subscriptions = [];

  AudioPlayerNotifier() : super(const AudioPlayerState()) {
    _initializeVoiceVolumes();
  }

  void _initializeVoiceVolumes() {
    const voiceParts = ['soprano', 'alto', 'tenor', 'bass'];
    final volumes = <String, double>{};
    for (final part in voiceParts) {
      volumes[part] = 1.0;
    }
    state = state.copyWith(voiceVolumes: volumes);
  }

  Future<void> loadSong(Map<String, String> audioUrls, String primaryVoicePart,
      {String? songId, String? songTitle}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Nettoyer les anciens players avec gestion d'erreur
      try {
        await _disposeAllPlayers();
      } catch (e) {
        print('Warning: Error during player cleanup: $e');
      }

      // Créer les nouveaux players pour chaque voix
      for (final entry in audioUrls.entries) {
        final voicePart = entry.key;
        final audioUrl = entry.value;

        final player = AudioPlayer();
        _players[voicePart] = player;

        // Configurer le player avec le bon chemin
        print('🎵 Chargement audio: $audioUrl');
        
        if (audioUrl.startsWith('assets/')) {
          // Fichier asset du bundle
          await player.setAsset(audioUrl);
        } else if (audioUrl.startsWith('/') || audioUrl.contains('/')) {
          // Chemin absolu de fichier système
          await player.setFilePath(audioUrl);
        } else {
          // Chemin relatif - il faut le localPath du chant
          print('⚠️ Chemin relatif détecté: $audioUrl - besoin du localPath');
          throw Exception('Chemin relatif non supporté - utilisez playSong() avec Song complet');
        }

        // Forcer la récupération de duration après le chargement
        if (voicePart == primaryVoicePart) {
          // Attendre un peu que le fichier soit analysé
          await Future.delayed(const Duration(milliseconds: 500));

          final duration = player.duration;
          if (duration != null) {
            state = state.copyWith(duration: duration);
            print('DEBUG: Duration récupérée = $duration');
          } else {
            print('DEBUG: Duration toujours null après 500ms');
          }
        }

        await player.setSpeed(state.tempo);
        await player.setVolume(state.voiceVolumes[voicePart] ?? 1.0);

        // Écouter les changements de position du player principal
        if (voicePart == primaryVoicePart) {
          _subscriptions.add(
            player.positionStream.listen((position) {
              state = state.copyWith(position: position);
              // Forcer la récupération de duration si elle n'est pas définie
              if (state.duration == Duration.zero && player.duration != null) {
                state = state.copyWith(duration: player.duration);
              }
            }),
          );

          _subscriptions.add(
            player.durationStream.listen((duration) {
              if (duration != null) {
                state = state.copyWith(duration: duration);
              }
            }),
          );

          _subscriptions.add(
            player.playerStateStream.listen((playerState) {
              state = state.copyWith(
                isPlaying: playerState.playing,
                isLoading:
                    playerState.processingState == ProcessingState.loading,
              );
            }),
          );
        }
      }

      state = state.copyWith(
        currentVoicePart: primaryVoicePart,
        isLoading: false,
        currentSongId: songId,
        currentSongTitle: songTitle,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> play() async {
    try {
      // Jouer tous les players en même temps
      final futures = _players.values.map((player) => player.play());
      await Future.wait(futures);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> pause() async {
    try {
      final futures = _players.values.map((player) => player.pause());
      await Future.wait(futures);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> seek(Duration position) async {
    try {
      final futures = _players.values.map((player) => player.seek(position));
      await Future.wait(futures);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> setTempo(double tempo) async {
    try {
      state = state.copyWith(tempo: tempo);
      final futures = _players.values.map((player) => player.setSpeed(tempo));
      await Future.wait(futures);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> setMasterVolume(double volume) async {
    try {
      state = state.copyWith(masterVolume: volume);
      // Appliquer le volume maître à tous les players
      for (final entry in _players.entries) {
        final voicePart = entry.key;
        final player = entry.value;
        final voiceVolume = state.voiceVolumes[voicePart] ?? 1.0;
        await player.setVolume(volume * voiceVolume);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> setVoiceVolume(String voicePart, double volume) async {
    try {
      final newVolumes = Map<String, double>.from(state.voiceVolumes);
      newVolumes[voicePart] = volume;
      state = state.copyWith(voiceVolumes: newVolumes);

      final player = _players[voicePart];
      if (player != null) {
        await player.setVolume(state.masterVolume * volume);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Nouvelle méthode pour jouer directement depuis une Song
  Future<void> playSong(Song song, String userVoicePart) async {
    if (song.audioUrls.isNotEmpty && song.localPath != null) {
      // Construire les chemins absolus à partir du localPath
      final absoluteAudioUrls = <String, String>{};
      
      for (final entry in song.audioUrls.entries) {
        final voicePart = entry.key;
        final relativePath = entry.value;
        
        // Essayer différentes combinaisons de chemins
        final possiblePaths = [
          '${song.localPath}/$relativePath',                    // Normal
          '${song.localPath}/${song.id}/$relativePath',         // Avec sous-dossier songId
        ];
        
        String? validPath;
        for (final path in possiblePaths) {
          if (await File(path).exists()) {
            validPath = path;
            print('✅ Fichier trouvé: $path');
            break;
          } else {
            print('❌ Fichier non trouvé: $path');
          }
        }
        
        if (validPath == null) {
          // Dernier recours : scanner le dossier pour trouver le fichier audio
          validPath = await _findAudioFileInDirectory('${song.localPath}');
          if (validPath != null) {
            print('🔍 Fichier audio trouvé par scan: $validPath');
          }
        }
        
        absoluteAudioUrls[voicePart] = validPath ?? possiblePaths.first;
      }
      
      print('🎵 Chemins audio absolus: $absoluteAudioUrls');
      
      await loadSong(
        absoluteAudioUrls,
        userVoicePart,
        songId: song.id,
        songTitle: song.title,
      );
      await play();
    } else {
      print('❌ Impossible de jouer: audioUrls vides ou localPath manquant');
    }
  }

  // Helper pour trouver un fichier audio dans un dossier
  Future<String?> _findAudioFileInDirectory(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) return null;
      
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
          return entity.path;
        }
      }
      return null;
    } catch (e) {
      print('❌ Erreur scan dossier: $e');
      return null;
    }
  }

  // Méthode pour arrêter et nettoyer
  Future<void> stop() async {
    try {
      final futures = _players.values.map((player) => player.stop());
      await Future.wait(futures);
      state = state.copyWith(
        isPlaying: false,
        position: Duration.zero,
        currentSongId: null,
        currentSongTitle: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void resetSettings() {
    setTempo(1.0);
    setMasterVolume(1.0);
    _initializeVoiceVolumes();
  }

  Future<void> _disposeAllPlayers() async {
    // Cancel subscriptions first
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    // Stop all players before disposing
    final stopFutures = _players.values.map((player) async {
      try {
        await player.stop();
      } catch (e) {
        // Ignore errors during stop
      }
    });
    await Future.wait(stopFutures);

    // Dispose players with delay to allow cleanup
    for (final player in _players.values) {
      try {
        await player.dispose();
      } catch (e) {
        // Ignore disposal errors
      }
    }
    _players.clear();

    // Add small delay for native cleanup
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  void dispose() {
    // Fire and forget - StateNotifier dispose must be sync
    _disposeAllPlayers().then((_) {
      // Cleanup completed
    }).catchError((e) {
      // Ignore cleanup errors
    });
    super.dispose();
  }
}

final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
  return AudioPlayerNotifier();
});
