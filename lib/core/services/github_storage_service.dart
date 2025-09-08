import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

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
  Future<Uint8List> downloadSongPackage(String songId, int version) async {
    try {
      final fileName = '$songId.zip';
      final url = '$_baseUrl/data/$fileName';
      print('📦 [$serviceName] Téléchargement du package: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/zip',
          'User-Agent': 'ShirChoir/1.0',
        },
      );

      if (response.statusCode == 200) {
        final sizeKB = (response.bodyBytes.length / 1024).round();
        print('✅ [$serviceName] Package téléchargé: $sizeKB KB');
        return response.bodyBytes;
      } else {
        throw Exception(
            'Erreur HTTP ${response.statusCode} pour $fileName: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ [$serviceName] Erreur téléchargement package $songId: $e');
      rethrow;
    }
  }

  @override
  Stream<double> getDownloadProgress(String songId, int version) {
    // GitHub n'a pas de stream de progrès natif
    // Simulation d'un progrès fluide
    return Stream.periodic(const Duration(milliseconds: 200), (count) {
      final progress = (count + 1) / 8; // 8 étapes = 100%
      return progress > 1.0 ? 1.0 : progress;
    }).take(8);
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
