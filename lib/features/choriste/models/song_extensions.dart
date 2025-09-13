import 'song_model.dart';
import 'voice_models.dart';

extension SongExtensions on Song {
  Song copyWith({
    String? id,
    String? title,
    String? composer,
    String? key,
    Map<String, String>? audioUrls,
    Map<String, int>? audioDurations,
    Duration? duration,
    double? sizeMb,
    DateTime? createdAt,
    SongAvailability? availability,
    int? version,
    String? localPath,
    DateTime? lastSync,
    Map<String, VoicePart>? voiceParts,
    Map<String, Translation>? translations,
    ResourcesCollection? resources,
    MusicalInfo? musicalInfo,
    Map<String, String>? voicePartKeys,
    Map<String, String>? lyrics,
    Map<String, String>? phonetics,
    Map<String, String>? translation,
    Map<String, String>? maestroNotes,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      composer: composer ?? this.composer,
      key: key ?? this.key,
      audioUrls: audioUrls ?? this.audioUrls,
      audioDurations: audioDurations ?? this.audioDurations,
      duration: duration ?? this.duration,
      sizeMb: sizeMb ?? this.sizeMb,
      createdAt: createdAt ?? this.createdAt,
      availability: availability ?? this.availability,
      version: version ?? this.version,
      localPath: localPath ?? this.localPath,
      lastSync: lastSync ?? this.lastSync,
      voiceParts: voiceParts ?? this.voiceParts,
      translations: translations ?? this.translations,
      resources: resources ?? this.resources,
      musicalInfo: musicalInfo ?? this.musicalInfo,
      voicePartKeys: voicePartKeys ?? this.voicePartKeys,
      lyrics: lyrics ?? this.lyrics,
      phonetics: phonetics ?? this.phonetics,
      translation: translation ?? this.translation,
      maestroNotes: maestroNotes ?? this.maestroNotes,
    );
  }
}