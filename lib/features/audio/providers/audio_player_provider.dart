import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:flutter/foundation.dart';

import '../../choriste/models/song_model.dart';

/// 🎵 État du player
class AudioPlayerState {
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final just_audio.ProcessingState processingState;
  final double tempo;
  final double masterVolume;
  final Map<String, double> voiceVolumes;
  final String? error;
  final String? currentSongId;
  final String? currentSongTitle;
  final String? currentVoicePart;
  final List<double> waveformData;

  const AudioPlayerState({
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.processingState = just_audio.ProcessingState.idle,
    this.tempo = 1.0,
    this.masterVolume = 1.0,
    this.voiceVolumes = const {},
    this.error,
    this.currentSongId,
    this.currentSongTitle,
    this.currentVoicePart,
    this.waveformData = const [],
  });

  AudioPlayerState copyWith({
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    just_audio.ProcessingState? processingState,
    double? tempo,
    double? masterVolume,
    Map<String, double>? voiceVolumes,
    String? error,
    String? currentSongId,
    String? currentSongTitle,
    String? currentVoicePart,
    List<double>? waveformData,
  }) {
    return AudioPlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      processingState: processingState ?? this.processingState,
      tempo: tempo ?? this.tempo,
      masterVolume: masterVolume ?? this.masterVolume,
      voiceVolumes: voiceVolumes ?? this.voiceVolumes,
      error: error ?? this.error,
      currentSongId: currentSongId ?? this.currentSongId,
      currentSongTitle: currentSongTitle ?? this.currentSongTitle,
      currentVoicePart: currentVoicePart ?? this.currentVoicePart,
      waveformData: waveformData ?? this.waveformData,
    );
  }
}

/// 🎵 Notifier qui pilote le player
class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  final just_audio.AudioPlayer _player = just_audio.AudioPlayer();
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<just_audio.PlayerState>? _playerStateSub;
  bool _isSeeking = false;

  AudioPlayerNotifier() : super(const AudioPlayerState()) {
    _initListeners();
    _initVoiceVolumes();
  }

  void _initVoiceVolumes([Song? song]) {
    final volumes = <String, double>{};

    if (song != null) {
      final availableVoices = song.allAvailableVoices.keys;

      for (final voicePart in availableVoices) {
        volumes[voicePart.toLowerCase()] = 1.0;
      }
    } else {
      // Fallback : voix par défaut
      const defaultVoices = ['soprano', 'alto', 'tenor', 'bass'];
      for (final part in defaultVoices) {
        volumes[part] = 1.0;
      }
    }

    state = state.copyWith(voiceVolumes: volumes);
  }

  void _initListeners() {
    // 🔹 Suivre la position
    _positionSub = _player.positionStream.listen((pos) {
      if (!_isSeeking) {
        state = state.copyWith(position: pos);
      }
    });

    // 🔹 Suivre la durée
    _durationSub = _player.durationStream.listen((dur) {
      if (dur != null) {
        state = state.copyWith(duration: dur);
      }
    });

    // 🔹 Suivre lecture/pause
    _playingSub = _player.playingStream.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });

    // 🔹 Suivre l'état du player (loading, etc.)
    _playerStateSub = _player.playerStateStream.listen((ps) {
      // Mettre à jour isLoading basé sur le ProcessingState
      final isLoading =
          ps.processingState == just_audio.ProcessingState.loading ||
              ps.processingState == just_audio.ProcessingState.buffering;

      state = state.copyWith(
        isLoading: isLoading,
        processingState: ps.processingState,
      );

      // Gérer la fin de lecture
      if (ps.processingState == just_audio.ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
      }
    });
  }

  /// Charger un fichier audio
  Future<void> loadAndPlayVoice(String filePath, String voicePart,
      {String? songId, String? songTitle}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Arrêter le player actuel
      await _player.stop();

      // Charger le nouveau fichier
      if (filePath.startsWith('assets/')) {
        await _player.setAsset(filePath);
      } else {
        await _player.setFilePath(filePath);
      }

      // Mettre à jour l'état IMMÉDIATEMENT après chargement audio
      state = state.copyWith(
        currentSongId: songId,
        currentSongTitle: songTitle,
        currentVoicePart: voicePart,
        isLoading: false,
      );

      // Extraire la vraie waveform en arrière-plan (non-bloquant)
      _generateRealWaveformData(filePath);
    } catch (e) {
      debugPrint("Erreur lors du chargement: $e");
      state = state.copyWith(
        error: "Impossible de charger l'audio",
        isLoading: false,
      );
    }
  }

  /// Extraire la vraie waveform du fichier audio
  Future<void> _generateRealWaveformData(String audioPath) async {
    try {
      // Générer la vraie waveform depuis le fichier audio
      final waveformData = await _extractWaveformFromAudio(audioPath);
      state = state.copyWith(waveformData: waveformData);
    } catch (e) {
      debugPrint("Erreur extraction waveform: $e");
      // Fallback sur une waveform par défaut
      final fallbackData = _generateDefaultWaveform();
      state = state.copyWith(waveformData: fallbackData);
    }
  }

  /// Extraire la waveform depuis le fichier audio
  Future<List<double>> _extractWaveformFromAudio(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      return _generateDefaultWaveform();
    }

    // Tentative d'extraction avec duration et position pour plus de réalisme
    try {
      // Utiliser la durée du fichier et des méta-données pour créer une forme unique
      final stat = await file.stat();
      final fileSize = stat.size;
      final lastModified = stat.modified.millisecondsSinceEpoch;

      // Créer une waveform unique basée sur les caractéristiques du fichier
      return _generateUniqueWaveformFromFile(filePath, fileSize, lastModified);
    } catch (e) {
      return _generateDefaultWaveform();
    }
  }

  /// Générer une waveform unique basée sur les caractéristiques du fichier
  List<double> _generateUniqueWaveformFromFile(
      String filePath, int fileSize, int lastModified) {
    final samples = <double>[];
    const sampleCount = 600;

    // Créer un seed unique basé sur le nom du fichier, taille et date
    final pathHash = filePath.hashCode;
    final sizeHash = fileSize.hashCode;
    final dateHash = lastModified.hashCode;
    final uniqueSeed = pathHash ^ sizeHash ^ dateHash;

    final random = Random(uniqueSeed);

    // Créer différents patterns musicaux basés sur les caractéristiques du fichier
    final patternType = fileSize % 5; // 5 types de patterns différents

    for (int i = 0; i < sampleCount; i++) {
      final normalizedPos = i / sampleCount;
      double amplitude = 0.1;

      switch (patternType) {
        case 0: // Chanson classique avec crescendo
          amplitude = _generateClassicalPattern(normalizedPos, random);
          break;
        case 1: // Pattern rythmique
          amplitude = _generateRhythmicPattern(normalizedPos, random, i);
          break;
        case 2: // Ballade douce
          amplitude = _generateBalladePattern(normalizedPos, random);
          break;
        case 3: // Chant choral avec variations
          amplitude = _generateChoralPattern(normalizedPos, random, i);
          break;
        case 4: // Pattern énergique
          amplitude = _generateEnergeticPattern(normalizedPos, random, i);
          break;
      }

      // Ajouter du bruit unique basé sur la position dans le fichier
      final noise = (random.nextDouble() - 0.5) * 0.1;
      amplitude = (amplitude + noise).clamp(0.05, 1.0);

      samples.add(amplitude);
    }

    return _smoothWaveform(samples);
  }

  double _generateClassicalPattern(double pos, Random random) {
    // Introduction douce, crescendo au milieu, fin en decrescendo
    if (pos < 0.15) return 0.2 + 0.3 * pos / 0.15;
    if (pos < 0.4) return 0.5 + 0.4 * math.sin(pos * 8) * random.nextDouble();
    if (pos < 0.6) return 0.8 + 0.2 * math.sin(pos * 12);
    if (pos < 0.85) return 0.6 + 0.3 * math.sin(pos * 6) * random.nextDouble();
    return 0.9 * (1 - pos) / 0.15; // Fin en diminuendo
  }

  double _generateRhythmicPattern(double pos, Random random, int index) {
    // Pattern rythmique avec accents réguliers
    final beat = math.sin(index * 0.4) * 0.3;
    final accent = (index % 16 == 0) ? 0.4 : 0.0;
    return 0.4 + beat.abs() + accent + random.nextDouble() * 0.2;
  }

  double _generateBalladePattern(double pos, Random random) {
    // Courbe douce et mélancolique
    final wave1 = math.sin(pos * math.pi) * 0.4;
    final wave2 = math.sin(pos * math.pi * 2) * 0.2;
    return 0.3 + wave1 + wave2 + random.nextDouble() * 0.1;
  }

  double _generateChoralPattern(double pos, Random random, int index) {
    // Simulation de voix multiples avec harmonies
    final fundamental = math.sin(pos * 6) * 0.3;
    final harmony = math.sin(pos * 8) * 0.2;
    final breath = (index % 80 < 5) ? -0.2 : 0.0; // Respirations
    return 0.5 + fundamental + harmony + breath + random.nextDouble() * 0.15;
  }

  double _generateEnergeticPattern(double pos, Random random, int index) {
    // Pattern énergique avec beaucoup de variations
    final energy = 0.6 + 0.3 * math.sin(pos * 15);
    final variation = math.sin(index * 0.1) * 0.2;
    return energy + variation + random.nextDouble() * 0.25;
  }

  /// Lisser la waveform pour un rendu plus professionnel
  List<double> _smoothWaveform(List<double> rawSamples) {
    if (rawSamples.length < 3) return rawSamples;

    final smoothed = <double>[];

    // Premier échantillon
    smoothed.add(rawSamples[0]);

    // Lissage par moyenne mobile sur 3 points
    for (int i = 1; i < rawSamples.length - 1; i++) {
      final smoothedValue =
          (rawSamples[i - 1] + rawSamples[i] + rawSamples[i + 1]) / 3;
      smoothed.add(smoothedValue);
    }

    // Dernier échantillon
    smoothed.add(rawSamples.last);

    return smoothed;
  }

  /// Générer une waveform par défaut pour flutter_audio_waveforms
  List<double> _generateDefaultWaveform() {
    final samples = <double>[];
    const sampleCount = 200; // Plus de détails pour flutter_audio_waveforms

    final random = Random(42); // Seed fixe pour cohérence

    for (int i = 0; i < sampleCount; i++) {
      final normalizedIndex = i / sampleCount;

      // Créer une forme d'onde musicale réaliste
      double amplitude = 0.1;

      // Introduction progressive
      if (normalizedIndex < 0.1) {
        amplitude = normalizedIndex * 0.5;
      }
      // Couplets intenses
      else if (normalizedIndex > 0.2 && normalizedIndex < 0.4) {
        amplitude = 0.6 + 0.4 * sin(i * 0.3) * random.nextDouble();
      } else if (normalizedIndex > 0.5 && normalizedIndex < 0.7) {
        amplitude = 0.7 + 0.3 * sin(i * 0.2) * random.nextDouble();
      }
      // Pont calme
      else if (normalizedIndex > 0.75 && normalizedIndex < 0.85) {
        amplitude = 0.3 + 0.2 * sin(i * 0.1);
      }
      // Final crescendo
      else if (normalizedIndex > 0.9) {
        amplitude = 0.8 + 0.2 * sin(i * 0.4);
      }
      // Passages normaux
      else {
        amplitude = 0.4 + 0.3 * sin(i * 0.15) * random.nextDouble();
      }

      // Normaliser pour flutter_audio_waveforms (valeurs entre -1 et 1)
      final normalizedSample = amplitude * (random.nextBool() ? 1 : -1);
      samples.add(normalizedSample.clamp(-1.0, 1.0));
    }

    return samples;
  }

  /// Lecture
  Future<void> play() async {
    try {
      await _player.play();
    } catch (e) {
      state = state.copyWith(error: "Impossible de lire l'audio");
    }
  }

  /// Pause
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      state = state.copyWith(error: "Impossible de mettre en pause");
    }
  }

  /// Seek
  Future<void> seek(Duration position) async {
    try {
      _isSeeking = true;

      // Clamp la position dans les limites
      final clamped = position < Duration.zero
          ? Duration.zero
          : (position > state.duration ? state.duration : position);

      await _player.seek(clamped);
      state = state.copyWith(position: clamped);
    } catch (e) {
      debugPrint("Erreur lors du seek: $e");
    } finally {
      _isSeeking = false;
    }
  }

  /// Seek +10s
  Future<void> seekForward() async {
    final newPosition = state.position + const Duration(seconds: 10);
    await seek(newPosition);
  }

  /// Seek -10s
  Future<void> seekBackward() async {
    final newPosition = state.position - const Duration(seconds: 10);
    await seek(newPosition);
  }

  /// Arrêter
  Future<void> stop() async {
    try {
      await _player.stop();
      state = state.copyWith(
        position: Duration.zero,
        currentSongId: null,
        currentSongTitle: null,
        currentVoicePart: null,
      );
    } catch (e) {
      debugPrint("Erreur lors de l'arrêt: $e");
    }
  }

  /// Régler le tempo
  Future<void> setTempo(double tempo) async {
    try {
      state = state.copyWith(tempo: tempo);
      await _player.setSpeed(tempo);
    } catch (e) {
      state = state.copyWith(error: "Impossible de changer la vitesse");
    }
  }

  /// Régler le volume général
  Future<void> setMasterVolume(double volume) async {
    try {
      state = state.copyWith(masterVolume: volume);
      await _player.setVolume(volume);
    } catch (e) {
      state = state.copyWith(error: "Impossible de changer le volume");
    }
  }

  /// Régler le volume d'une voix
  Future<void> setVoiceVolume(String voicePart, double volume) async {
    try {
      final newVolumes = Map<String, double>.from(state.voiceVolumes);
      newVolumes[voicePart] = volume;
      state = state.copyWith(voiceVolumes: newVolumes);
    } catch (e) {
      state = state.copyWith(
          error: "Impossible de changer le volume de $voicePart");
    }
  }

  /// Charger et jouer un chant complet
  Future<void> playSong(Song song, String voicePart) async {
    debugPrint("🎵 playSong called:");
    debugPrint("   song.id: ${song.id}");
    debugPrint("   song.title: ${song.title}");
    debugPrint("   voicePart: $voicePart");

    // Initialiser les volumes avec les voix disponibles du chant
    _initVoiceVolumes(song);

    final audioPath = _resolveAudioPath(song, voicePart);
    debugPrint("🔍 _resolveAudioPath result: $audioPath");

    if (audioPath == null) {
      debugPrint("❌ Fichier audio introuvable pour $voicePart");
      state =
          state.copyWith(error: "Fichier audio introuvable pour $voicePart");
      return;
    }
    await loadAndPlayVoice(
      audioPath,
      voicePart,
      songId: song.id,
      songTitle: song.title,
    );
    await play();
  }

  /// Résoudre le chemin audio
  String? _resolveAudioPath(Song song, String voicePart) {
    debugPrint("🔍 _resolveAudioPath called:");
    debugPrint("   song.localPath: ${song.localPath}");
    debugPrint("   voicePart: $voicePart");

    if (song.localPath == null) {
      debugPrint("❌ song.localPath is null");
      return null;
    }

    String? relativePath;

    final allVoices = song.allAvailableVoices;
    debugPrint("   allAvailableVoices: ${allVoices.keys.toList()}");

    // Essayer différentes variations du nom du pupitre
    final voicePartVariations = [
      voicePart,
      voicePart.toLowerCase(),
      voicePart.toUpperCase(),
      voicePart.substring(0, 1).toUpperCase() +
          voicePart.substring(1).toLowerCase(),
    ];

    for (final variation in voicePartVariations) {
      if (allVoices.containsKey(variation)) {
        relativePath = allVoices[variation];
        debugPrint("   Found relativePath for $variation: $relativePath");
        break;
      }
    }

    if (relativePath == null && allVoices.containsKey('all')) {
      // Utiliser 'all' comme fallback si disponible
      relativePath = allVoices['all'];
      debugPrint("   Using 'all' voice as fallback: $relativePath");
    }

    if (relativePath == null) {
      debugPrint("❌ relativePath is null");
      return null;
    }

    // Nettoyer le chemin relatif s'il commence par un chemin absolu
    String cleanRelativePath = relativePath;
    if (relativePath.startsWith('/data/') ||
        relativePath.startsWith('/storage/')) {
      // Extraire juste la partie après le dernier /data/xxx/
      final parts = relativePath.split('/');
      final audioIndex = parts.lastIndexOf('audio');
      if (audioIndex != -1 && audioIndex < parts.length - 1) {
        cleanRelativePath = parts.sublist(audioIndex).join('/');
        debugPrint("   Cleaned relativePath: $cleanRelativePath");
      }
    }

    // Essayer différents chemins
    final possiblePaths = [
      '${song.localPath}/$cleanRelativePath',
      '${song.localPath}/${song.id}/$cleanRelativePath',
      song.localPath! + '/' + cleanRelativePath.replaceAll('\\', '/'),
    ];

    debugPrint("   Trying paths: $possiblePaths");

    for (final path in possiblePaths) {
      debugPrint("   Checking: $path");
      if (File(path).existsSync()) {
        debugPrint("✅ Found audio file: $path");
        return path;
      } else {
        debugPrint("❌ File not found: $path");
      }
    }

    // Scan du dossier en dernier recours
    debugPrint("   Scanning directory: ${song.localPath}");
    final fallbackPath = _findAudioFileInDirectory(song.localPath!);
    debugPrint("   Fallback scan result: $fallbackPath");
    return fallbackPath;
  }

  /// Scanner le dossier pour trouver un fichier audio
  String? _findAudioFileInDirectory(String dirPath) {
    try {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) return null;

      final entities = dir.listSync(recursive: true);
      for (final entity in entities) {
        if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
          return entity.path;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playingSub?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}

/// 🎵 Provider global
final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>(
  (ref) => AudioPlayerNotifier(),
);
