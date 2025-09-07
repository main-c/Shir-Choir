class User {
  final String id;
  final String name;
  final String role; // 'choriste' ou 'maestro'
  final String? voicePart; // Pour les choristes: 'soprano', 'alto', 'tenor', 'bass'
  
  const User({
    required this.id,
    required this.name,
    required this.role,
    this.voicePart,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      voicePart: json['voicePart'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'voicePart': voicePart,
    };
  }
  
  User copyWith({
    String? id,
    String? name,
    String? role,
    String? voicePart,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      voicePart: voicePart ?? this.voicePart,
    );
  }
}
