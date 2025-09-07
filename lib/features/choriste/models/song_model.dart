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
  });
  
  factory Song.fromJson(Map<String, dynamic> json) {
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
    );
  }
}

enum LearningStatus {
  notStarted('not_started', 'Non commencé'),
  inProgress('in_progress', 'En cours d\'apprentissage'),
  mastered('mastered', 'Maîtrisé');
  
  const LearningStatus(this.key, this.label);
  
  final String key;
  final String label;
}

class SongProgress {
  final String songId;
  final String userId;
  final LearningStatus status;
  final DateTime updatedAt;
  
  const SongProgress({
    required this.songId,
    required this.userId,
    required this.status,
    required this.updatedAt,
  });
  
  factory SongProgress.fromJson(Map<String, dynamic> json) {
    return SongProgress(
      songId: json['songId'] as String,
      userId: json['userId'] as String,
      status: LearningStatus.values.firstWhere(
        (s) => s.key == json['status'],
        orElse: () => LearningStatus.notStarted,
      ),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'songId': songId,
      'userId': userId,
      'status': status.key,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
