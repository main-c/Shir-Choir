import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/choir_member_model.dart';
import '../../choriste/models/song_model.dart';
import '../../choriste/providers/songs_provider.dart';

// Mock data pour la démonstration
final choirMembersProvider = Provider<List<ChoirMember>>((ref) {
  return [
    ChoirMember(
      id: '1',
      name: 'Marie Dubois',
      voicePart: 'soprano',
      joinedAt: DateTime.now().subtract(const Duration(days: 30)),
      songProgress: {
        '1': LearningStatus.mastered,
        '2': LearningStatus.inProgress,
        '3': LearningStatus.notStarted,
      },
    ),
    ChoirMember(
      id: '2',
      name: 'Sophie Martin',
      voicePart: 'soprano',
      joinedAt: DateTime.now().subtract(const Duration(days: 25)),
      songProgress: {
        '1': LearningStatus.inProgress,
        '2': LearningStatus.mastered,
        '3': LearningStatus.notStarted,
      },
    ),
    ChoirMember(
      id: '3',
      name: 'Claire Leroy',
      voicePart: 'alto',
      joinedAt: DateTime.now().subtract(const Duration(days: 20)),
      songProgress: {
        '1': LearningStatus.mastered,
        '2': LearningStatus.inProgress,
        '3': LearningStatus.inProgress,
      },
    ),
    ChoirMember(
      id: '4',
      name: 'Anne Moreau',
      voicePart: 'alto',
      joinedAt: DateTime.now().subtract(const Duration(days: 15)),
      songProgress: {
        '1': LearningStatus.inProgress,
        '2': LearningStatus.notStarted,
        '3': LearningStatus.notStarted,
      },
    ),
    ChoirMember(
      id: '5',
      name: 'Pierre Durand',
      voicePart: 'tenor',
      joinedAt: DateTime.now().subtract(const Duration(days: 35)),
      songProgress: {
        '1': LearningStatus.mastered,
        '2': LearningStatus.mastered,
        '3': LearningStatus.inProgress,
      },
    ),
    ChoirMember(
      id: '6',
      name: 'Jean Petit',
      voicePart: 'tenor',
      joinedAt: DateTime.now().subtract(const Duration(days: 10)),
      songProgress: {
        '1': LearningStatus.inProgress,
        '2': LearningStatus.notStarted,
        '3': LearningStatus.notStarted,
      },
    ),
    ChoirMember(
      id: '7',
      name: 'Michel Bernard',
      voicePart: 'bass',
      joinedAt: DateTime.now().subtract(const Duration(days: 40)),
      songProgress: {
        '1': LearningStatus.mastered,
        '2': LearningStatus.inProgress,
        '3': LearningStatus.mastered,
      },
    ),
    ChoirMember(
      id: '8',
      name: 'Paul Roux',
      voicePart: 'bass',
      joinedAt: DateTime.now().subtract(const Duration(days: 5)),
      songProgress: {
        '1': LearningStatus.notStarted,
        '2': LearningStatus.notStarted,
        '3': LearningStatus.notStarted,
      },
    ),
  ];
});

final choirStatsProvider = Provider<ChoirStats>((ref) {
  final members = ref.watch(choirMembersProvider);
  final songs = ref.watch(songsProvider);

  // Calculer les statistiques
  final membersByVoicePart = <String, int>{};
  final overallProgress = <LearningStatus, int>{
    LearningStatus.notStarted: 0,
    LearningStatus.inProgress: 0,
    LearningStatus.mastered: 0,
  };

  for (final member in members) {
    membersByVoicePart[member.voicePart] = 
        (membersByVoicePart[member.voicePart] ?? 0) + 1;

    for (final status in member.songProgress.values) {
      overallProgress[status] = (overallProgress[status] ?? 0) + 1;
    }
  }

  return ChoirStats(
    totalMembers: members.length,
    totalSongs: songs.length,
    membersByVoicePart: membersByVoicePart,
    overallProgress: overallProgress,
  );
});
