import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../../features/choriste/models/song_model.dart';
import 'storage_service.dart';
import 'storage_service_factory.dart';
import 'local_storage_service.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final StorageService _storageService = StorageServiceFactory.create();
  final LocalStorageService _localService = LocalStorageService();

  /// Télécharge et installe un chant complet
  Future<Song> downloadAndInstallSong(String songId, int version) async {
    try {
      // 1. Télécharger le fichier ZIP depuis Firebase
      final zipData = await _storageService.downloadSongPackage(songId, version);
      
      // 2. Créer le répertoire local pour ce chant
      final songPath = '${_localService.songsDirectory}/$songId';
      final songDir = Directory(songPath);
      await songDir.create(recursive: true);
      
      // 3. Extraire le ZIP
      await _extractZipFiles(zipData, songPath);
      
      // Debug: Lister les fichiers extraits APRÈS réorganisation
      print('📂 Contenu final dans $songPath:');
      await for (final entity in songDir.list(recursive: true)) {
        print('  - ${entity.path}');
      }
      
      // 4. Lire les métadonnées (gérer structure imbriquée)
      File metadataFile = File('$songPath/metadata.json');
      
      // Si pas trouvé directement, chercher dans sous-dossier du même nom
      if (!await metadataFile.exists()) {
        metadataFile = File('$songPath/$songId/metadata.json');
        if (!await metadataFile.exists()) {
          throw Exception('Fichier metadata.json introuvable dans le ZIP extrait');
        }
        
        // Si trouvé dans sous-dossier, déplacer tout vers la racine
        print('📦 Déplacement des fichiers depuis le sous-dossier...');
        final subDir = Directory('$songPath/$songId');
        await for (final entity in subDir.list()) {
          if (entity is File) {
            final newPath = '$songPath/${entity.path.split('/').last}';
            await entity.copy(newPath);
          } else if (entity is Directory) {
            final dirName = entity.path.split('/').last;
            final newDir = Directory('$songPath/$dirName');
            if (!await newDir.exists()) await newDir.create();
            
            await for (final subEntity in entity.list(recursive: true)) {
              if (subEntity is File) {
                final relativePath = subEntity.path.replaceFirst('${entity.path}/', '');
                final newFilePath = '${newDir.path}/$relativePath';
                await Directory(newFilePath.substring(0, newFilePath.lastIndexOf('/'))).create(recursive: true);
                await subEntity.copy(newFilePath);
              }
            }
          }
        }
        
        // Supprimer l'ancien sous-dossier
        await subDir.delete(recursive: true);
        
        // Mettre à jour la référence du fichier metadata
        metadataFile = File('$songPath/metadata.json');
      }
      final metadataContent = await metadataFile.readAsString();
      final metadata = json.decode(metadataContent) as Map<String, dynamic>;
      
      // Corriger les URLs audio avec les vrais fichiers présents
      await _fixAudioPaths(metadata, songPath);
      
      // 5. Créer l'objet Song avec les chemins locaux
      final song = Song.fromJson(
        metadata,
        availability: SongAvailability.downloadedAndReady,
        version: version,
        localPath: songPath,
        lastSync: DateTime.now(),
      );
      
      // 6. Sauvegarder en base de données
      await _localService.storeSong(song);
      
      return song;
      
    } catch (e) {
      throw Exception('Erreur lors du téléchargement de $songId: $e');
    }
  }

  /// Extrait les fichiers d'un ZIP vers un répertoire
  Future<List<String>> _extractZipFiles(Uint8List zipData, String extractPath) async {
    final extractedFiles = <String>[];
    
    try {
      // Décoder l'archive ZIP
      final archive = ZipDecoder().decodeBytes(zipData);
      
      // Extraire chaque fichier
      for (final file in archive) {
        if (file.isFile) {
          final filePath = '$extractPath/${file.name}';
          final outputFile = File(filePath);
          
          // Créer les répertoires parent si nécessaire
          await outputFile.parent.create(recursive: true);
          
          // Écrire le contenu du fichier
          await outputFile.writeAsBytes(file.content as List<int>);
          extractedFiles.add(filePath);
        }
      }
      
      return extractedFiles;
      
    } catch (e) {
      throw Exception('Erreur lors de l\'extraction du ZIP: $e');
    }
  }

  /// Supprime tous les fichiers d'un chant téléchargé
  Future<void> deleteSongFiles(String songId) async {
    final songPath = '${_localService.songsDirectory}/$songId';
    final songDir = Directory(songPath);
    
    if (await songDir.exists()) {
      await songDir.delete(recursive: true);
    }
    
    await _localService.deleteSong(songId);
  }

  /// Vérifie l'espace disque disponible
  Future<int> getAvailableSpace() async {
    try {
      // Retourner une estimation (simplifié pour MVP)
      return 1024 * 1024 * 100; // 100MB simulé
    } catch (e) {
      return 0;
    }
  }

  /// Calcule l'espace utilisé par les chants téléchargés
  Future<int> getUsedSpace() async {
    try {
      final songsDir = Directory(_localService.songsDirectory);
      if (!await songsDir.exists()) return 0;
      
      int totalSize = 0;
      await for (final entity in songsDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Corrige les chemins audio avec les vrais fichiers présents
  Future<void> _fixAudioPaths(Map<String, dynamic> metadata, String songPath) async {
    try {
      final audioDir = Directory('$songPath/audio');
      if (!await audioDir.exists()) return;

      // Lister tous les fichiers audio disponibles
      final audioFiles = <String>[];
      await for (final entity in audioDir.list()) {
        if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
          audioFiles.add(entity.path.split('/').last);
        }
      }

      print('🎵 Fichiers audio trouvés: $audioFiles');

      // Si il y a un seul fichier audio, l'utiliser pour tous les pupitres
      if (audioFiles.length == 1) {
        final audioFile = audioFiles.first;
        metadata['audioUrls'] = {
          'soprano': 'audio/$audioFile',
          'alto': 'audio/$audioFile',
          'tenor': 'audio/$audioFile',
          'bass': 'audio/$audioFile',
          'all': 'audio/$audioFile',
        };
        print('✅ Chemins audio mis à jour avec: $audioFile');
      } else if (audioFiles.isNotEmpty) {
        // S'il y a plusieurs fichiers, essayer de mapper intelligemment
        final audioUrls = <String, String>{};
        
        for (final file in audioFiles) {
          final fileName = file.toLowerCase();
          if (fileName.contains('soprano') || fileName.contains('sop')) {
            audioUrls['soprano'] = 'audio/$file';
          } else if (fileName.contains('alto')) {
            audioUrls['alto'] = 'audio/$file';
          } else if (fileName.contains('tenor') || fileName.contains('ten')) {
            audioUrls['tenor'] = 'audio/$file';
          } else if (fileName.contains('bass') || fileName.contains('basse')) {
            audioUrls['bass'] = 'audio/$file';
          } else if (fileName.contains('all') || fileName.contains('full')) {
            audioUrls['all'] = 'audio/$file';
          } else {
            // Par défaut, utiliser le premier fichier pour tous
            audioUrls['all'] = 'audio/$file';
            audioUrls['soprano'] = 'audio/$file';
            audioUrls['alto'] = 'audio/$file';
            audioUrls['tenor'] = 'audio/$file';
            audioUrls['bass'] = 'audio/$file';
            break;
          }
        }
        
        metadata['audioUrls'] = audioUrls;
        print('✅ Chemins audio mappés: $audioUrls');
      }
    } catch (e) {
      print('❌ Erreur lors de la correction des chemins audio: $e');
    }
  }
}