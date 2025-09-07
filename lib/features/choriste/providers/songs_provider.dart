import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song_model.dart';

// Mock data pour la démonstration
final songsProvider = Provider<List<Song>>((ref) {
  return [
    Song(
      id: '1',
      title: 'Ave Maria',
      composer: 'Franz Schubert',
      key: 'Bb majeur',
      voicePartKeys: {
        'soprano': 'Bb majeur',
        'alto': 'Bb majeur',
        'tenor': 'Bb majeur',
        'bass': 'Bb majeur',
      },
      lyrics: {
        'soprano': 'Ave Maria, gratia plena...',
        'alto': 'Ave Maria, gratia plena...',
        'tenor': 'Ave Maria, gratia plena...',
        'bass': 'Ave Maria, gratia plena...',
      },
      phonetics: {
        'soprano': 'Ah-veh Mah-ree-ah, grah-tsee-ah pleh-nah...',
        'alto': 'Ah-veh Mah-ree-ah, grah-tsee-ah pleh-nah...',
        'tenor': 'Ah-veh Mah-ree-ah, grah-tsee-ah pleh-nah...',
        'bass': 'Ah-veh Mah-ree-ah, grah-tsee-ah pleh-nah...',
      },
      translation: {
        'soprano': 'Je vous salue Marie, pleine de grâce...',
        'alto': 'Je vous salue Marie, pleine de grâce...',
        'tenor': 'Je vous salue Marie, pleine de grâce...',
        'bass': 'Je vous salue Marie, pleine de grâce...',
      },
      audioUrls: {
        'soprano': 'assets/audio/ave_maria_soprano.mp3',
        'alto': 'assets/audio/ave_maria_alto.mp3',
        'tenor': 'assets/audio/ave_maria_tenor.mp3',
        'bass': 'assets/audio/ave_maria_bass.mp3',
      },
      maestroNotes: {
        'soprano': 'Attention aux aigus, bien soutenir la respiration',
        'alto': 'Harmonies importantes, écouter les sopranos',
        'tenor': 'Entrée mesure 16, bien marquer le rythme',
        'bass': 'Fondation harmonique, rester stable',
      },
      duration: const Duration(minutes: 4, seconds: 30),
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    Song(
      id: '2',
      title: 'Hallelujah',
      composer: 'Leonard Cohen',
      key: 'C majeur',
      voicePartKeys: {
        'soprano': 'C majeur',
        'alto': 'C majeur',
        'tenor': 'C majeur',
        'bass': 'C majeur',
      },
      lyrics: {
        'soprano': 'I heard there was a secret chord...',
        'alto': 'I heard there was a secret chord...',
        'tenor': 'I heard there was a secret chord...',
        'bass': 'I heard there was a secret chord...',
      },
      audioUrls: {
        'soprano': 'assets/audio/kumbaya_demo.mp3',
        'alto': 'assets/audio/kumbaya_demo.mp3',
        'tenor': 'assets/audio/kumbaya_demo.mp3',
        'bass': 'assets/audio/kumbaya_demo.mp3',
      },
      maestroNotes: {
        'soprano': 'Mélodie principale, bien articuler les paroles',
        'alto': 'Harmonies en tierces, suivre les sopranos',
        'tenor': 'Contre-chant important au refrain',
        'bass': 'Ligne de basse simple mais essentielle',
      },
      duration: const Duration(minutes: 4, seconds: 45),
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Song(
      id: '3',
      title: 'Amazing Grace',
      composer: 'John Newton',
      key: 'G majeur',
      voicePartKeys: {
        'soprano': 'G majeur',
        'alto': 'G majeur',
        'tenor': 'G majeur',
        'bass': 'G majeur',
      },
      lyrics: {
        'soprano': 'Amazing grace, how sweet the sound...',
        'alto': 'Amazing grace, how sweet the sound...',
        'tenor': 'Amazing grace, how sweet the sound...',
        'bass': 'Amazing grace, how sweet the sound...',
      },
      audioUrls: {
        'soprano': 'assets/audio/amazing_grace_soprano.mp3',
        'alto': 'assets/audio/amazing_grace_alto.mp3',
        'tenor': 'assets/audio/amazing_grace_tenor.mp3',
        'bass': 'assets/audio/amazing_grace_bass.mp3',
      },
      maestroNotes: {
        'soprano': 'Mélodie expressive, attention aux nuances',
        'alto': 'Harmonisation classique, bien équilibrer',
        'tenor': 'Soutien harmonique, ne pas couvrir les sopranos',
        'bass': 'Fondamentales importantes, rester présent',
      },
      duration: const Duration(minutes: 3, seconds: 45),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
});

class SongProgressNotifier extends StateNotifier<Map<String, SongProgress>> {
  SongProgressNotifier() : super({});

  void updateProgress(String songId, String userId, LearningStatus status) {
    final progress = SongProgress(
      songId: songId,
      userId: userId,
      status: status,
      updatedAt: DateTime.now(),
    );

    state = {
      ...state,
      songId: progress,
    };
  }

  LearningStatus getProgress(String songId) {
    return state[songId]?.status ?? LearningStatus.notStarted;
  }
}

final songProgressProvider =
    StateNotifierProvider<SongProgressNotifier, Map<String, SongProgress>>(
        (ref) {
  return SongProgressNotifier();
});
