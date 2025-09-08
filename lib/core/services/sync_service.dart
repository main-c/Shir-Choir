import '../../features/choriste/models/song_model.dart';
import '../../features/choriste/models/song_extensions.dart';
import 'connectivity_service.dart';
import 'storage_service.dart';
import 'storage_service_factory.dart';
import 'local_storage_service.dart';
import 'download_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ConnectivityService _connectivityService = ConnectivityService();
  final StorageService _storageService = StorageServiceFactory.create();
  final LocalStorageService _localService = LocalStorageService();
  final DownloadService _downloadService = DownloadService();

  /// Charge tous les chants (locaux + distants si connecté)
  Future<List<Song>> loadAllSongs() async {
    await _localService.initialize();
    
    // 1. Charger d'abord les chants locaux (offline-first)
    final localSongs = await _localService.getStoredSongs();
    final localSongsMap = {for (var song in localSongs) song.id: song};
    
    // 2. Si connecté, récupérer le manifeste pour voir tout ce qui existe
    if (await _connectivityService.hasInternetConnection()) {
      try {
        final manifest = await _storageService.downloadManifest();
        final remoteSongs = _parseManifestSongs(manifest);
        
        // 3. Fusionner : chants locaux + chants disponibles en ligne
        final allSongs = _mergeLocalAndRemoteSongs(localSongsMap, remoteSongs);
        return allSongs;
        
      } catch (e) {
        // En cas d'erreur réseau, retourner seulement les chants locaux
        print('Erreur lors de la synchronisation: $e');
        return localSongs;
      }
    } else {
      // Mode offline : seulement les chants locaux
      return localSongs;
    }
  }

  /// Parse les chants depuis le manifeste Firebase
  List<Song> _parseManifestSongs(Map<String, dynamic> manifest) {
    final chantsList = manifest['chants'] as List<dynamic>;
    return chantsList.map((chantData) {
      return Song.fromManifest(chantData as Map<String, dynamic>);
    }).toList();
  }

  /// Fusionne les chants locaux avec ceux disponibles en ligne
  List<Song> _mergeLocalAndRemoteSongs(
    Map<String, Song> localSongs, 
    List<Song> remoteSongs
  ) {
    final mergedSongs = <Song>[];
    final processedIds = <String>{};

    // 1. Traiter les chants distants
    for (final remoteSong in remoteSongs) {
      final localSong = localSongs[remoteSong.id];
      
      if (localSong != null) {
        // Le chant existe localement, vérifier la version
        if (localSong.version != null && 
            remoteSong.version != null && 
            remoteSong.version! > localSong.version!) {
          // Mise à jour disponible
          mergedSongs.add(localSong.copyWith(
            availability: SongAvailability.updateAvailable,
          ));
        } else {
          // Version locale à jour
          mergedSongs.add(localSong);
        }
      } else {
        // Nouveau chant disponible pour téléchargement
        mergedSongs.add(remoteSong);
      }
      
      processedIds.add(remoteSong.id);
    }

    // 2. Ajouter les chants locaux qui ne sont pas sur le serveur
    for (final localSong in localSongs.values) {
      if (!processedIds.contains(localSong.id)) {
        mergedSongs.add(localSong.copyWith(
          availability: SongAvailability.localOnly,
        ));
      }
    }

    return mergedSongs;
  }

  /// Télécharge un chant spécifique
  Future<Song> downloadSong(String songId, int version) async {
    if (!await _connectivityService.hasInternetConnection()) {
      throw Exception('Aucune connexion Internet disponible');
    }

    try {
      // Mettre à jour le statut en "téléchargement"
      await _localService.updateSongStatus(songId, SongAvailability.downloading);
      
      // Télécharger et installer
      final song = await _downloadService.downloadAndInstallSong(songId, version);
      
      return song;
      
    } catch (e) {
      // En cas d'erreur, marquer comme erreur de sync
      await _localService.updateSongStatus(songId, SongAvailability.syncError);
      rethrow;
    }
  }

  /// Met à jour un chant existant
  Future<Song> updateSong(String songId, int newVersion) async {
    // Supprimer l'ancienne version
    await _downloadService.deleteSongFiles(songId);
    
    // Télécharger la nouvelle version
    return await downloadSong(songId, newVersion);
  }

  /// Vérifie s'il y a des mises à jour disponibles
  Future<List<Song>> checkForUpdates() async {
    if (!await _connectivityService.hasInternetConnection()) {
      return [];
    }

    try {
      final allSongs = await loadAllSongs();
      return allSongs.where((song) => 
        song.availability == SongAvailability.updateAvailable
      ).toList();
    } catch (e) {
      return [];
    }
  }

  /// Supprime un chant téléchargé
  Future<void> deleteSong(String songId) async {
    await _downloadService.deleteSongFiles(songId);
  }
}

