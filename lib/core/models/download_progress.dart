class DownloadProgress {
  final int downloaded;
  final int total;
  final double percentage;

  const DownloadProgress({
    required this.downloaded,
    required this.total,
    required this.percentage,
  });

  /// Taille téléchargée formatée (ex: "1.2 MB")
  String get downloadedFormatted => _formatBytes(downloaded);

  /// Taille totale formatée (ex: "5.8 MB") 
  String get totalFormatted => _formatBytes(total);

  /// Pourcentage formaté (ex: "25%")
  String get percentageFormatted => '${(percentage * 100).round()}%';

  /// Vitesse estimée (nécessite un timestamp)
  String get speedFormatted {
    // TODO: Implémenter le calcul de vitesse si nécessaire
    return '';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  String toString() {
    return 'DownloadProgress(downloaded: $downloadedFormatted, total: $totalFormatted, percentage: $percentageFormatted)';
  }
}