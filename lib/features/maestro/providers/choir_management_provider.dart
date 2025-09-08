import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/choir_member_model.dart';
import '../../choriste/providers/songs_provider.dart';

// Mock data pour la démonstration - simplifié sans LearningStatus
final choirMembersProvider = Provider<List<ChoirMember>>((ref) {
  return [
    ChoirMember(
      id: '1',
      name: 'Marie Dubois',
      voicePart: 'soprano',
      joinedAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    ChoirMember(
      id: '2',
      name: 'Sophie Martin',
      voicePart: 'soprano',
      joinedAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
    ChoirMember(
      id: '3',
      name: 'Claire Leroy',
      voicePart: 'alto',
      joinedAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    ChoirMember(
      id: '4',
      name: 'Anne Moreau',
      voicePart: 'alto',
      joinedAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    ChoirMember(
      id: '5',
      name: 'Pierre Durand',
      voicePart: 'tenor',
      joinedAt: DateTime.now().subtract(const Duration(days: 35)),
    ),
    ChoirMember(
      id: '6',
      name: 'Jean Petit',
      voicePart: 'tenor',
      joinedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    ChoirMember(
      id: '7',
      name: 'Michel Bernard',
      voicePart: 'bass',
      joinedAt: DateTime.now().subtract(const Duration(days: 40)),
    ),
    ChoirMember(
      id: '8',
      name: 'Paul Roux',
      voicePart: 'bass',
      joinedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];
});

// Statistiques simplifiées sans système de progression
final choirStatsProvider = Provider<ChoirStats>((ref) {
  final members = ref.watch(choirMembersProvider);
  final songsAsync = ref.watch(songsProvider);

  // Calculer seulement la répartition par pupitre
  final membersByVoicePart = <String, int>{};

  for (final member in members) {
    membersByVoicePart[member.voicePart] = 
        (membersByVoicePart[member.voicePart] ?? 0) + 1;
  }

  final songs = songsAsync.valueOrNull ?? [];

  return ChoirStats(
    totalMembers: members.length,
    totalSongs: songs.length,
    membersByVoicePart: membersByVoicePart,
  );
});
