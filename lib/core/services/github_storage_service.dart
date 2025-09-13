import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import '../models/download_progress.dart';
import '../models/download_result.dart';

class GitHubStorageService implements StorageService {
  static final GitHubStorageService _instance =
      GitHubStorageService._internal();
  factory GitHubStorageService() => _instance;
  GitHubStorageService._internal();

  @override
  String get serviceName => 'GitHub Raw';

  // URL de base du repo GitHub (raw content)
  static const String _baseUrl =
      'https://raw.githubusercontent.com/main-c/shir-choir-data/main';

  // Variables pour le suivi du progrès
  final Map<String, StreamController<DownloadProgress>> _progressControllers =
      {};

  @override
  Future<Map<String, dynamic>> downloadManifest() async {
    try {
      final url = '$_baseUrl/data/manifest.json';
      print('🐙 [$serviceName] Téléchargement du manifeste: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'ShirChoir/1.0',
        },
      );

      if (response.statusCode == 200) {
        final manifest = jsonDecode(response.body) as Map<String, dynamic>;
        print(
            '✅ [$serviceName] Manifeste téléchargé: ${manifest['chants']?.length ?? 0} chants');
        return manifest;
      } else {
        throw Exception(
            'Erreur HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ [$serviceName] Erreur téléchargement manifeste: $e');
      rethrow;
    }
  }

  @override
  Future<DownloadResult> downloadSongPackage(String songId, int version) async {
    final fileName = '$songId.zip';
    final url = '$_baseUrl/data/$fileName';
    final progressKey = '${songId}_$version';

    try {
      print('📦 [$serviceName] Téléchargement du package: $url');

      // Créer un stream controller pour ce téléchargement (si pas déjà créé)
      if (!_progressControllers.containsKey(progressKey)) {
        _progressControllers[progressKey] =
            StreamController<DownloadProgress>();
      }

      // Première requête HEAD pour obtenir la taille du fichier
      final headResponse = await http.head(Uri.parse(url));
      if (headResponse.statusCode != 200) {
        throw Exception(
            'Erreur HTTP ${headResponse.statusCode}: ${headResponse.reasonPhrase}');
      }

      final contentLength =
          int.tryParse(headResponse.headers['content-length'] ?? '0') ?? 0;
      final sizeFormatted =
          contentLength > 0 ? _formatBytes(contentLength) : 'Taille inconnue';
      final sizeMb = contentLength > 0 ? (contentLength / (1024 * 1024)) : 0.0;

      print('📦 [$serviceName] Taille du fichier: $sizeFormatted');

      // Envoyer la taille initiale
      _progressControllers[progressKey]?.add(DownloadProgress(
        downloaded: 0,
        total: contentLength,
        percentage: 0.0,
      ));

      // Téléchargement avec streaming
      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll({
        'Accept': 'application/zip',
        'User-Agent': 'ShirChoir/1.0',
      });

      final client = http.Client();
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Erreur HTTP ${response.statusCode}');
      }

      final bytes = <int>[];
      int downloadedBytes = 0;

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        downloadedBytes += chunk.length;

        final percentage =
            contentLength > 0 ? (downloadedBytes / contentLength) : 0.0;

        // Mettre à jour le progrès
        _progressControllers[progressKey]?.add(DownloadProgress(
          downloaded: downloadedBytes,
          total: contentLength,
          percentage: percentage,
        ));
      }

      // Téléchargement terminé
      _progressControllers[progressKey]?.add(DownloadProgress(
        downloaded: downloadedBytes,
        total: contentLength,
        percentage: 1.0,
      ));

      // Fermer le stream
      await _progressControllers[progressKey]?.close();
      _progressControllers.remove(progressKey);

      final actualSize = _formatBytes(bytes.length);
      print('✅ [$serviceName] Package téléchargé: $actualSize');

      client.close();
      return DownloadResult(
        data: Uint8List.fromList(bytes),
        sizeMb: sizeMb,
      );
    } catch (e) {
      print('❌ [$serviceName] Erreur téléchargement package $songId: $e');
      // Nettoyer en cas d'erreur
      await _progressControllers[progressKey]?.close();
      _progressControllers.remove(progressKey);
      rethrow;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Stream<double> getDownloadProgress(String songId, int version) {
    final progressKey = '${songId}_$version';
    final controller = _progressControllers[progressKey];

    if (controller == null) {
      // Pas de téléchargement en cours, retourner un stream vide
      return Stream.empty();
    }

    return controller.stream.map((progress) => progress.percentage);
  }

  /// Obtenir le progrès détaillé avec tailles de fichiers
  Stream<DownloadProgress> getDetailedDownloadProgress(
      String songId, int version) {
    final progressKey = '${songId}_$version';
    final controller = _progressControllers[progressKey];

    if (controller == null) {
      return Stream.empty();
    }

    return controller.stream;
  }

  /// Récupère la taille du fichier sans le télécharger (requête HEAD)
  Future<double> getSongPackageSize(String songId, [int? version]) async {
    final progressKey = version != null ? '${songId}_$version' : null;

    try {
      // Feedback: Connexion au serveur
      if (progressKey != null) {
        _progressControllers[progressKey]?.add(DownloadProgress(
          downloaded: 0,
          total: 0,
          percentage: 0.0, // 5% - Connexion...
        ));
      }

      final fileName = '$songId.zip';
      final url = '$_baseUrl/data/$fileName';

      final headResponse = await http.head(Uri.parse(url));

      // Feedback: Récupération des informations
      if (progressKey != null) {
        _progressControllers[progressKey]?.add(DownloadProgress(
          downloaded: 0,
          total: 0,
          percentage: 0.0, // 10% - Calcul de la taille...
        ));
      }

      if (headResponse.statusCode == 200) {
        final contentLength =
            int.tryParse(headResponse.headers['content-length'] ?? '0') ?? 0;
        final sizeMb =
            contentLength > 0 ? (contentLength / (1024 * 1024)) : 0.0;
        print(
            '📦 [$serviceName] Taille récupérée pour $songId: ${sizeMb.toStringAsFixed(1)}MB');

        // Feedback: Taille récupérée, prêt pour téléchargement
        if (progressKey != null) {
          _progressControllers[progressKey]?.add(DownloadProgress(
            downloaded: 0,
            total: contentLength,
            percentage: 0.0, // 15% - Prêt pour téléchargement...
          ));
        }

        return sizeMb;
      }
      return 0.0;
    } catch (e) {
      print('❌ [$serviceName] Erreur récupération taille $songId: $e');
      return 0.0;
    }
  }

  /// Initialise le stream de progression avec feedback immédiat
  void initializeDownloadProgress(String songId, int version) {
    final progressKey = '${songId}_$version';

    // Si déjà en cours, ne pas recréer
    if (_progressControllers.containsKey(progressKey)) {
      return;
    }

    print('🚀 [$serviceName] Initialisation téléchargement $songId...');

    // Créer le stream controller immédiatement
    _progressControllers[progressKey] = StreamController<DownloadProgress>();

    // Émettre le premier état immédiatement
    _progressControllers[progressKey]?.add(DownloadProgress(
      downloaded: 0,
      total: 0,
      percentage: 0.0,
    ));
  }

  @override
  Future<bool> songExists(String songId, int version) async {
    try {
      final fileName = '$songId.zip';
      final url = '$_baseUrl/data/$fileName';

      final response = await http.head(
        Uri.parse(url),
        headers: {'User-Agent': 'ShirChoir/1.0'},
      );

      final exists = response.statusCode == 200;
      print('🔍 [$serviceName] Chant $fileName existe: $exists');
      return exists;
    } catch (e) {
      print('❌ [$serviceName] Erreur vérification existence $songId: $e');
      return false;
    }
  }

  @override
  Future<bool> testConnection() async {
    try {
      print('🔗 [$serviceName] Test de connectivité...');

      final response = await http.head(
        Uri.parse(_baseUrl),
        headers: {'User-Agent': 'ShirChoir/1.0'},
      ).timeout(const Duration(seconds: 10));

      final connected = response.statusCode == 200;
      print('${connected ? '✅' : '❌'} [$serviceName] Connectivité: $connected');
      return connected;
    } catch (e) {
      print('❌ [$serviceName] Erreur test connectivité: $e');
      return false;
    }
  }
}
