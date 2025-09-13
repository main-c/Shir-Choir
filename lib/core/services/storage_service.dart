import 'dart:typed_data';
import '../models/download_progress.dart';
import '../models/download_result.dart';

/// Interface abstraite pour les services de stockage
/// Permet de changer facilement la source de données (GitHub, Firebase, S3, etc.)
abstract class StorageService {
  /// Télécharge le manifeste des chants disponibles
  Future<Map<String, dynamic>> downloadManifest();

  /// Télécharge un package de chant (fichier ZIP) avec la taille réelle
  Future<DownloadResult> downloadSongPackage(String songId, int version);

  /// Vérifie si un chant existe sur la source distante
  Future<bool> songExists(String songId, int version);

  /// Stream du progrès de téléchargement (0.0 à 1.0)
  Stream<double> getDownloadProgress(String songId, int version);

  /// Stream du progrès détaillé avec tailles de fichiers
  Stream<DownloadProgress> getDetailedDownloadProgress(String songId, int version) {
    // Implémentation par défaut qui convertit le stream simple
    return getDownloadProgress(songId, version).map((percentage) => 
      DownloadProgress(downloaded: 0, total: 0, percentage: percentage));
  }

  /// Teste la connectivité avec la source
  Future<bool> testConnection();

  /// Nom du service pour le debug/logs
  String get serviceName;
}