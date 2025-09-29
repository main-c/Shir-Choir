import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../models/song_extensions.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/github_storage_service.dart';
import '../../../core/services/local_storage_service.dart';

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
  final LocalStorageService _localService = LocalStorageService();

  /// Charge tous les chants (locaux + distants si connecté)
  Future<void> loadSongs() async {
    try {
      state = const AsyncValue.loading();
      final songs = await _syncService.loadAllSongs();
      state = AsyncValue.data(songs);
    } catch (e, stackTrace) {
      // En cas d'erreur, essayer de fallback sur les chants locaux
      try {
        await _localService.initialize();
        final localSongs = await _localService.getStoredSongs();
        if (localSongs.isNotEmpty) {
          // Afficher les chants locaux + toast d'erreur
          state = AsyncValue.data(localSongs);
          _showErrorToast(
            'Erreur de synchronisation', 
            'Affichage des chants téléchargés uniquement. ${_formatErrorMessage(e.toString())}'
          );
        } else {
          // Pas de chants locaux, afficher l'erreur complète
          state = AsyncValue.error(e, stackTrace);
        }
      } catch (localError) {
        // Erreur même pour récupérer les chants locaux
        state = AsyncValue.error(e, stackTrace);
      }
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

      final storageService = GitHubStorageService();

      // 1. Initialiser le stream de progression immédiatement
      storageService.initializeDownloadProgress(
          songId, songToDownload.version!);

      // 2. Mettre à jour le statut à "téléchargement" immédiatement
      final downloadingSongs = currentSongs.map((song) {
        if (song.id == songId) {
          return song.copyWith(availability: SongAvailability.downloading);
        }
        return song;
      }).toList();
      state = AsyncValue.data(downloadingSongs);

      // 3. Récupérer la taille du fichier avec feedback de progression
      final sizeMb = await storageService.getSongPackageSize(
          songId, songToDownload.version!);

      // 4. Mettre à jour avec la taille si récupérée
      if (sizeMb > 0) {
        final updatedSongs = currentSongs.map((song) {
          if (song.id == songId) {
            return song.copyWith(
              availability: SongAvailability.downloading,
              sizeMb: sizeMb,
            );
          }
          return song;
        }).toList();
        state = AsyncValue.data(updatedSongs);
      }

      // Télécharger le chant
      final downloadedSong =
          await _syncService.downloadSong(songId, songToDownload.version!);

      // Mettre à jour la liste avec le chant téléchargé
      final currentSongsAfterDownload = state.valueOrNull ?? [];
      final finalSongs = currentSongsAfterDownload.map((song) {
        if (song.id == songId) {
          return downloadedSong;
        }
        return song;
      }).toList();
      state = AsyncValue.data(finalSongs);

      // Afficher notification toast de succès
      _showSuccessToast('Téléchargement terminé',
          '${downloadedSong.title} est prêt à être joué');
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
      print('❌ Erreur téléchargement $songId: $e');
      // Afficher notification toast d'erreur
      _showErrorToast('Erreur de téléchargement', e.toString());

      //rethrow;
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

      // Afficher notification toast d'erreur
      _showErrorToast('Erreur de mise à jour', e.toString());

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
      // Afficher notification toast d'erreur
      _showErrorToast('Erreur de suppression', e.toString());
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

  /// Affiche une notification toast d'erreur
  void _showErrorToast(String title, String message) {
    toastification.show(
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      title: Text(title),
      description: Text(_formatErrorMessage(message)),
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 4),
      showProgressBar: true,
      dragToClose: true,
    );
  }

  /// Formate le message d'erreur pour l'affichage
  String _formatErrorMessage(String error) {
    if (error.contains('Connection closed')) {
      return 'Connexion interrompue. Vérifiez votre réseau.';
    } else if (error.contains('Aucune connexion Internet')) {
      return 'Aucune connexion Internet disponible.';
    } else if (error.contains('Chant non trouvé')) {
      return 'Ce chant n\'est plus disponible.';
    } else if (error.length > 100) {
      return 'Une erreur technique s\'est produite.';
    }
    return error;
  }

  /// Affiche une notification toast de succès
  void _showSuccessToast(String title, String message) {
    toastification.show(
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      title: Text(title),
      description: Text(message),
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 3),
      showProgressBar: true,
      dragToClose: true,
    );
  }
}

// Système de progression retiré temporairement pour le MVP
