import 'storage_service.dart';
import 'github_storage_service.dart';

/// Factory pour créer le service de stockage approprié
/// Permet de changer facilement de source de données
class StorageServiceFactory {
  // Configuration centralisée - peut venir d'un config file plus tard
  static const String _currentProvider = 'github';

  /// Crée une instance du service de stockage configuré
  static StorageService create() {
    switch (_currentProvider.toLowerCase()) {
      case 'github':
        return GitHubStorageService();
      // Futurs providers :
      // case 'firebase':
      //   return FirebaseStorageService();
      // case 's3':
      //   return S3StorageService();
      default:
        return GitHubStorageService(); // Par défaut
    }
  }

  /// Retourne le nom du provider actuel
  static String get currentProvider => _currentProvider;

  /// Retourne la liste des providers disponibles
  static List<String> get availableProviders => ['github'];
}