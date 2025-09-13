import 'dart:typed_data';

/// Résultat d'un téléchargement avec la taille réelle du fichier
class DownloadResult {
  final Uint8List data;
  final double sizeMb;

  const DownloadResult({
    required this.data,
    required this.sizeMb,
  });
}