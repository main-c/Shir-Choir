import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song_model.dart';
import '../models/song_extensions.dart';
import '../../../core/services/sync_service.dart';

// Provider pour la liste des chants avec synchronisation
final songsProvider =
    StateNotifierProvider<SongsNotifier, AsyncValue<List<Song>>>((ref) {
  return SongsNotifier();
});

class SongsNotifier extends StateNotifier<AsyncValue<List<Song>>> {
  SongsNotifier() : super(const AsyncValue.loading()) {
    loadSongs();
  }

  final SyncService _syncService = SyncService();

  /// Charge tous les chants (locaux + distants si connecté)
  Future<void> loadSongs() async {
    try {
      state = const AsyncValue.loading();
      final songs = await _syncService.loadAllSongs();
      state = AsyncValue.data(songs);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Télécharge un chant spécifique
  Future<void> downloadSong(String songId) async {
    try {
      // Trouver le chant dans la liste actuelle
      final currentSongs = state.valueOrNull ?? [];
      final songToDownload = currentSongs.firstWhere(
        (s) => s.id == songId,
        orElse: () => throw Exception('Chant non trouvé: $songId'),
      );

      if (songToDownload.version == null) {
        throw Exception('Version du chant non disponible');
      }

      // Mettre à jour le statut à "téléchargement"
      final updatedSongs = currentSongs.map((song) {
        if (song.id == songId) {
          return song.copyWith(availability: SongAvailability.downloading);
        }
        return song;
      }).toList();
      state = AsyncValue.data(updatedSongs);

      // Télécharger le chant
      final downloadedSong =
          await _syncService.downloadSong(songId, songToDownload.version!);

      // Mettre à jour la liste avec le chant téléchargé
      final finalSongs = updatedSongs.map((song) {
        if (song.id == songId) {
          return downloadedSong;
        }
        return song;
      }).toList();
      state = AsyncValue.data(finalSongs);
    } catch (e) {
      // En cas d'erreur, marquer le chant comme erreur de sync
      final currentSongs = state.valueOrNull ?? [];
      final errorSongs = currentSongs.map((song) {
        if (song.id == songId) {
          return song.copyWith(availability: SongAvailability.syncError);
        }
        return song;
      }).toList();
      state = AsyncValue.data(errorSongs);

      rethrow;
    }
  }

  /// Met à jour un chant existant
  Future<void> updateSong(String songId) async {
    try {
      final currentSongs = state.valueOrNull ?? [];
      final songToUpdate = currentSongs.firstWhere(
        (s) => s.id == songId,
        orElse: () => throw Exception('Chant non trouvé: $songId'),
      );

      if (songToUpdate.version == null) {
        throw Exception('Version du chant non disponible');
      }

      // Marquer comme en téléchargement
      final updatedSongs = currentSongs.map((song) {
        if (song.id == songId) {
          return song.copyWith(availability: SongAvailability.downloading);
        }
        return song;
      }).toList();
      state = AsyncValue.data(updatedSongs);

      // Mettre à jour le chant
      final updatedSong =
          await _syncService.updateSong(songId, songToUpdate.version!);

      // Mettre à jour la liste
      final finalSongs = updatedSongs.map((song) {
        if (song.id == songId) {
          return updatedSong;
        }
        return song;
      }).toList();
      state = AsyncValue.data(finalSongs);
    } catch (e) {
      // Gérer l'erreur
      final currentSongs = state.valueOrNull ?? [];
      final errorSongs = currentSongs.map((song) {
        if (song.id == songId) {
          return song.copyWith(availability: SongAvailability.syncError);
        }
        return song;
      }).toList();
      state = AsyncValue.data(errorSongs);

      rethrow;
    }
  }

  /// Supprime un chant téléchargé
  Future<void> deleteSong(String songId) async {
    try {
      await _syncService.deleteSong(songId);

      // Retirer le chant de la liste ou le marquer comme disponible pour téléchargement
      final currentSongs = state.valueOrNull ?? [];
      final updatedSongs = currentSongs.map((song) {
        if (song.id == songId) {
          return song.copyWith(
            availability: SongAvailability.availableForDownload,
            localPath: null,
            lastSync: null,
          );
        }
        return song;
      }).toList();

      state = AsyncValue.data(updatedSongs);
    } catch (e) {
      rethrow;
    }
  }

  /// Force la synchronisation avec le serveur
  Future<void> forceSync() async {
    await loadSongs();
  }

  /// Vérifie les mises à jour disponibles
  Future<List<Song>> checkForUpdates() async {
    return await _syncService.checkForUpdates();
  }
}

// Provider de fallback avec données mockées pour le développement
final mockSongsProvider = Provider<List<Song>>((ref) {
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

// Système de progression retiré temporairement pour le MVP
