class Song {
  final String id;
  final String title;
  final String composer;
  final String key;
  final Map<String, String> voicePartKeys; // Tonalité par pupitre
  final Map<String, String> lyrics;
  final Map<String, String>? phonetics;
  final Map<String, String>? translation;
  final Map<String, String> audioUrls; // URL audio par pupitre
  final Map<String, String> maestroNotes; // Notes par pupitre
  final Duration duration; // Durée du chant
  final DateTime createdAt;
  
  // Nouvelles propriétés pour la synchronisation
  final SongAvailability availability;
  final int? version;
  final String? localPath;
  final DateTime? lastSync;
  
  const Song({
    required this.id,
    required this.title,
    required this.composer,
    required this.key,
    required this.voicePartKeys,
    required this.lyrics,
    this.phonetics,
    this.translation,
    required this.audioUrls,
    required this.maestroNotes,
    required this.duration,
    required this.createdAt,
    this.availability = SongAvailability.localOnly,
    this.version,
    this.localPath,
    this.lastSync,
  });
  
  factory Song.fromJson(Map<String, dynamic> json, {
    SongAvailability? availability,
    int? version,
    String? localPath,
    DateTime? lastSync,
  }) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      composer: json['composer'] as String,
      key: json['key'] as String,
      voicePartKeys: Map<String, String>.from(json['voicePartKeys']),
      lyrics: Map<String, String>.from(json['lyrics']),
      phonetics: json['phonetics'] != null 
          ? Map<String, String>.from(json['phonetics']) 
          : null,
      translation: json['translation'] != null 
          ? Map<String, String>.from(json['translation']) 
          : null,
      audioUrls: Map<String, String>.from(json['audioUrls']),
      maestroNotes: Map<String, String>.from(json['maestroNotes']),
      duration: Duration(seconds: json['duration'] as int),
      createdAt: DateTime.parse(json['createdAt']),
      availability: availability ?? SongAvailability.localOnly,
      version: version,
      localPath: localPath,
      lastSync: lastSync,
    );
  }
  
  // Factory pour les données Firebase (manifeste)
  factory Song.fromManifest(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      composer: json['composer'] as String,
      key: '', // Sera rempli lors du téléchargement
      voicePartKeys: {},
      lyrics: {},
      audioUrls: {},
      maestroNotes: {},
      duration: Duration(seconds: json['duration'] as int? ?? 0),
      createdAt: DateTime.parse(json['last_updated']),
      availability: SongAvailability.availableForDownload,
      version: json['version'] as int?,
    );
  }
}

enum SongAvailability {
  downloadedAndReady,     // ✅ Téléchargé, prêt à jouer
  availableForDownload,   // ☁️ Visible mais pas téléchargé
  updateAvailable,        // 🔄 Nouvelle version disponible
  downloading,            // ⬇️ En cours de téléchargement
  localOnly,             // 📱 Seulement en local (pas de réseau)
  syncError,             // ❌ Erreur de synchronisation
}

