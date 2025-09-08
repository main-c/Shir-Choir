import 'song_model.dart';

extension SongExtensions on Song {
  Song copyWith({
    String? id,
    String? title,
    String? composer,
    String? key,
    Map<String, String>? voicePartKeys,
    Map<String, String>? lyrics,
    Map<String, String>? phonetics,
    Map<String, String>? translation,
    Map<String, String>? audioUrls,
    Map<String, String>? maestroNotes,
    Duration? duration,
    DateTime? createdAt,
    SongAvailability? availability,
    int? version,
    String? localPath,
    DateTime? lastSync,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      composer: composer ?? this.composer,
      key: key ?? this.key,
      voicePartKeys: voicePartKeys ?? this.voicePartKeys,
      lyrics: lyrics ?? this.lyrics,
      phonetics: phonetics ?? this.phonetics,
      translation: translation ?? this.translation,
      audioUrls: audioUrls ?? this.audioUrls,
      maestroNotes: maestroNotes ?? this.maestroNotes,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      availability: availability ?? this.availability,
      version: version ?? this.version,
      localPath: localPath ?? this.localPath,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}