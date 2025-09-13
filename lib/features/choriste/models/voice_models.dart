/// Modèles pour la nouvelle structure hiérarchique des voix

/// Représente une voix individuelle (soprano1, soprano2, etc.)
class Voice {
  final String id;
  final String label;
  final String audioUrl;
  final String? startNote;
  final String? maestroNotes;

  const Voice({
    required this.id,
    required this.label,
    required this.audioUrl,
    this.startNote,
    this.maestroNotes,
  });

  factory Voice.fromJson(String id, Map<String, dynamic> json) {
    return Voice(
      id: id,
      label: json['label'] as String,
      audioUrl: json['audioUrl'] as String,
      startNote: json['startNote'] as String?,
      maestroNotes: json['maestroNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'audioUrl': audioUrl,
      if (startNote != null) 'startNote': startNote,
      if (maestroNotes != null) 'maestroNotes': maestroNotes,
    };
  }
}

/// Représente un pupitre (soprano, alto, tenor, bass)
class VoicePart {
  final String id;
  final String key;
  final Map<String, Voice> voices;

  const VoicePart({
    required this.id,
    required this.key,
    required this.voices,
  });

  factory VoicePart.fromJson(String id, Map<String, dynamic> json) {
    final voicesMap = <String, Voice>{};
    final voicesData = json['voices'] as Map<String, dynamic>;

    voicesData.forEach((voiceId, voiceData) {
      voicesMap[voiceId] = Voice.fromJson(voiceId, voiceData);
    });

    return VoicePart(
      id: id,
      key: json['key'] as String,
      voices: voicesMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'voices': voices.map((id, voice) => MapEntry(id, voice.toJson())),
    };
  }

  /// Retourne toutes les voix disponibles dans ce pupitre
  List<Voice> get allVoices => voices.values.toList();

  /// Retourne la première voix (principale) du pupitre
  Voice? get primaryVoice =>
      voices.values.isNotEmpty ? voices.values.first : null;
}

/// Représente une traduction
class Translation {
  final String title;
  final String lyrics;
  final String? phonetics;

  const Translation({
    required this.title,
    required this.lyrics,
    this.phonetics,
  });

  factory Translation.fromJson(Map<String, dynamic> json) {
    return Translation(
      title: json['title'] as String,
      lyrics: json['lyrics'] as String,
      phonetics: json['phonetics'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'lyrics': lyrics,
      if (phonetics != null) 'phonetics': phonetics,
    };
  }
}

/// Représente une ressource externe
class ExternalResource {
  final String type; // pdf, youtube, website, accompaniment, full_mix
  final String label;
  final String url;
  final String? description;

  const ExternalResource({
    required this.type,
    required this.label,
    required this.url,
    this.description,
  });

  factory ExternalResource.fromJson(Map<String, dynamic> json) {
    return ExternalResource(
      type: json['type'] as String,
      label: json['label'] as String,
      url: json['url'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'label': label,
      'url': url,
      if (description != null) 'description': description,
    };
  }

  /// Retourne l'icône appropriée selon le type
  String get iconName {
    switch (type) {
      case 'pdf':
        return 'picture_as_pdf';
      case 'youtube':
        return 'video_library';
      case 'website':
        return 'link';
      case 'accompaniment':
        return 'piano';
      case 'full_mix':
        return 'library_music';
      default:
        return 'insert_drive_file';
    }
  }
}

/// Collection de ressources externes
class ResourcesCollection {
  final List<ExternalResource> scores;
  final List<ExternalResource> videos;
  final List<ExternalResource> links;
  final List<ExternalResource> audioExtras;

  const ResourcesCollection({
    this.scores = const [],
    this.videos = const [],
    this.links = const [],
    this.audioExtras = const [],
  });

  factory ResourcesCollection.fromJson(Map<String, dynamic> json) {
    return ResourcesCollection(
      scores: _parseResourcesList(json['scores']),
      videos: _parseResourcesList(json['videos']),
      links: _parseResourcesList(json['links']),
      audioExtras: _parseResourcesList(json['audio_extras']),
    );
  }

  static List<ExternalResource> _parseResourcesList(dynamic data) {
    if (data == null) return [];
    return (data as List)
        .map((item) => ExternalResource.fromJson(item))
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'scores': scores.map((r) => r.toJson()).toList(),
      'videos': videos.map((r) => r.toJson()).toList(),
      'links': links.map((r) => r.toJson()).toList(),
      'audio_extras': audioExtras.map((r) => r.toJson()).toList(),
    };
  }

  /// Retourne toutes les ressources dans une liste plate
  List<ExternalResource> get allResources => [
        ...scores,
        ...videos,
        ...links,
        ...audioExtras,
      ];

  /// Vérifie si des ressources existent
  bool get hasResources => allResources.isNotEmpty;
}

/// Métadonnées musicales
class MusicalInfo {
  final String timeSignature;
  final int tempoBpm;
  final String difficulty;
  final List<String> tags;
  final String? originalArtist;
  final String? arrangement;

  const MusicalInfo({
    required this.timeSignature,
    required this.tempoBpm,
    required this.difficulty,
    this.tags = const [],
    this.originalArtist,
    this.arrangement,
  });

  factory MusicalInfo.fromJson(Map<String, dynamic> json) {
    return MusicalInfo(
      timeSignature: json['time_signature'] as String,
      tempoBpm: json['tempo_bpm'] ?? 0,
      difficulty: json['difficulty'] as String,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      originalArtist: json['original_artist'] as String?,
      arrangement: json['arrangement'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time_signature': timeSignature,
      'tempo_bpm': tempoBpm,
      'difficulty': difficulty,
      'tags': tags,
      if (originalArtist != null) 'original_artist': originalArtist,
      if (arrangement != null) 'arrangement': arrangement,
    };
  }
}
