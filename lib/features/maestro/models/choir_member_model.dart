class ChoirMember {
  final String id;
  final String name;
  final String voicePart;
  final DateTime joinedAt;

  const ChoirMember({
    required this.id,
    required this.name,
    required this.voicePart,
    required this.joinedAt,
  });

  factory ChoirMember.fromJson(Map<String, dynamic> json) {
    return ChoirMember(
      id: json['id'] as String,
      name: json['name'] as String,
      voicePart: json['voicePart'] as String,
      joinedAt: DateTime.parse(json['joinedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'voicePart': voicePart,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }
}

class ChoirStats {
  final int totalMembers;
  final int totalSongs;
  final Map<String, int> membersByVoicePart;

  const ChoirStats({
    required this.totalMembers,
    required this.totalSongs,
    required this.membersByVoicePart,
  });
}
