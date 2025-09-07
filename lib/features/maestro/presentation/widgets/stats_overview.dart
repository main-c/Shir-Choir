import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/choir_member_model.dart';
import '../../../choriste/models/song_model.dart';

class StatsOverview extends StatelessWidget {
  final ChoirStats stats;

  const StatsOverview({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Statistiques principales
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Choristes',
                stats.totalMembers.toString(),
                Icons.people,
                AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Chants',
                stats.totalSongs.toString(),
                Icons.library_music,
                AppTheme.secondaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Répartition par pupitre
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Répartition par pupitre',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ...stats.membersByVoicePart.entries.map((entry) {
                  return _buildVoicePartRow(
                    _getVoicePartLabel(entry.key),
                    entry.value,
                    stats.totalMembers,
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Progression globale
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progression globale',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ...stats.overallProgress.entries.map((entry) {
                  return _buildProgressRow(
                    entry.key.label,
                    entry.value,
                    _getTotalProgress(stats.overallProgress),
                    _getStatusColor(entry.key),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoicePartRow(String voicePart, int count, int total) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              voicePart,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: total > 0 ? count / total : 0,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count ($percentage%)',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String status, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              status,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: total > 0 ? count / total : 0,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count ($percentage%)',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
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

  Color _getStatusColor(LearningStatus status) {
    switch (status) {
      case LearningStatus.notStarted:
        return Colors.grey;
      case LearningStatus.inProgress:
        return Colors.orange;
      case LearningStatus.mastered:
        return Colors.green;
    }
  }

  int _getTotalProgress(Map<LearningStatus, int> progress) {
    return progress.values.fold(0, (sum, count) => sum + count);
  }
}
