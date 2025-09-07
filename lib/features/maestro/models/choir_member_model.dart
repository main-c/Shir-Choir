import '../../choriste/models/song_model.dart';

class ChoirMember {
  final String id;
  final String name;
  final String voicePart;
  final DateTime joinedAt;
  final Map<String, LearningStatus> songProgress;

  const ChoirMember({
    required this.id,
    required this.name,
    required this.voicePart,
    required this.joinedAt,
    required this.songProgress,
  });

  factory ChoirMember.fromJson(Map<String, dynamic> json) {
    final progressMap = <String, LearningStatus>{};
    if (json['songProgress'] != null) {
      final progress = json['songProgress'] as Map<String, dynamic>;
      progress.forEach((songId, statusKey) {
        progressMap[songId] = LearningStatus.values.firstWhere(
          (s) => s.key == statusKey,
          orElse: () => LearningStatus.notStarted,
        );
      });
    }

    return ChoirMember(
      id: json['id'] as String,
      name: json['name'] as String,
      voicePart: json['voicePart'] as String,
      joinedAt: DateTime.parse(json['joinedAt']),
      songProgress: progressMap,
    );
  }

  Map<String, dynamic> toJson() {
    final progressMap = <String, String>{};
    songProgress.forEach((songId, status) {
      progressMap[songId] = status.key;
    });

    return {
      'id': id,
      'name': name,
      'voicePart': voicePart,
      'joinedAt': joinedAt.toIso8601String(),
      'songProgress': progressMap,
    };
  }
}

class ChoirStats {
  final int totalMembers;
  final int totalSongs;
  final Map<String, int> membersByVoicePart;
  final Map<LearningStatus, int> overallProgress;

  const ChoirStats({
    required this.totalMembers,
    required this.totalSongs,
    required this.membersByVoicePart,
    required this.overallProgress,
  });
}
