import 'dart:typed_data';

/// Interface abstraite pour les services de stockage
/// Permet de changer facilement la source de données (GitHub, Firebase, S3, etc.)
abstract class StorageService {
  /// Télécharge le manifeste des chants disponibles
  Future<Map<String, dynamic>> downloadManifest();

  /// Télécharge un package de chant (fichier ZIP)
  Future<Uint8List> downloadSongPackage(String songId, int version);

  /// Vérifie si un chant existe sur la source distante
  Future<bool> songExists(String songId, int version);

  /// Stream du progrès de téléchargement (0.0 à 1.0)
  Stream<double> getDownloadProgress(String songId, int version);

  /// Teste la connectivité avec la source
  Future<bool> testConnection();

  /// Nom du service pour le debug/logs
  String get serviceName;
}