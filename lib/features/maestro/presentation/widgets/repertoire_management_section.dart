import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../choriste/providers/songs_provider.dart';
import '../../../choriste/models/song_model.dart';
import '../../models/choir_member_model.dart';
import '../../providers/choir_management_provider.dart';

class RepertoireManagementSection extends ConsumerWidget {
  const RepertoireManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = ref.watch(songsProvider);
    final members = ref.watch(choirMembersProvider);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSongManagementCard(song, members),
        );
      },
    );
  }

  Widget _buildSongManagementCard(Song song, List<ChoirMember> members) {
    // Calculer les statistiques de progression pour ce chant
    final songStats = _calculateSongStats(song.id, members);

    return Card(
      child: ExpansionTile(
        title: Text(
          song.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${song.composer} - ${song.key}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistiques de progression
                Text(
                  'Progression par pupitre',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                ...songStats.entries.map((entry) {
                  final voicePart = entry.key;
                  final stats = entry.value;
                  return _buildVoicePartProgress(voicePart, stats);
                }).toList(),
                
                const SizedBox(height: 16),
                
                // Actions de gestion
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implémenter l'édition
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Modifier'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implémenter la gestion des notes
                        },
                        icon: const Icon(Icons.note_add),
                        label: const Text('Notes'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoicePartProgress(String voicePart, Map<LearningStatus, int> stats) {
    final total = stats.values.fold(0, (sum, count) => sum + count);
    final mastered = stats[LearningStatus.mastered] ?? 0;
    final inProgress = stats[LearningStatus.inProgress] ?? 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getVoicePartLabel(voicePart),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '$mastered/$total maîtrisé',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: total > 0 ? mastered / total : 0,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ],
      ),
    );
  }

  Map<String, Map<LearningStatus, int>> _calculateSongStats(
    String songId,
    List<ChoirMember> members,
  ) {
    final stats = <String, Map<LearningStatus, int>>{};
    
    for (final member in members) {
      final voicePart = member.voicePart;
      if (!stats.containsKey(voicePart)) {
        stats[voicePart] = {
          LearningStatus.notStarted: 0,
          LearningStatus.inProgress: 0,
          LearningStatus.mastered: 0,
        };
      }
      
      final status = member.songProgress[songId] ?? LearningStatus.notStarted;
      stats[voicePart]![status] = (stats[voicePart]![status] ?? 0) + 1;
    }
    
    return stats;
  }

  String _getVoicePartLabel(String voicePart) {
    switch (voicePart) {
      case 'soprano':
        return 'Soprano';
      case 'alto':
        return 'Alto';
      case 'tenor':
        return 'Ténor';
      case 'bass':
        return 'Basse';
      default:
        return voicePart;
    }
  }
}
