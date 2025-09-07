import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../providers/choir_management_provider.dart';
import '../../models/choir_member_model.dart';
import '../../../choriste/models/song_model.dart';

class ChoirMembersSection extends ConsumerStatefulWidget {
  const ChoirMembersSection({super.key});

  @override
  ConsumerState<ChoirMembersSection> createState() => _ChoirMembersSectionState();
}

class _ChoirMembersSectionState extends ConsumerState<ChoirMembersSection> {
  String _searchQuery = '';
  String? _voicePartFilter;

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(choirMembersProvider);
    
    // Filtrer les membres
    final filteredMembers = members.where((member) {
      final matchesSearch = member.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesVoicePart = _voicePartFilter == null || member.voicePart == _voicePartFilter;
      return matchesSearch && matchesVoicePart;
    }).toList();

    return Column(
      children: [
        // Barre de recherche et filtres
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Rechercher un choriste...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Tous', null),
                    const SizedBox(width: 8),
                    _buildFilterChip('Soprano', 'soprano'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Alto', 'alto'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Ténor', 'tenor'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Basse', 'bass'),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Liste des membres
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredMembers.length,
            itemBuilder: (context, index) {
              final member = filteredMembers[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildMemberCard(member),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String? voicePart) {
    final isSelected = _voicePartFilter == voicePart;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _voicePartFilter = voicePart;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(ChoirMember member) {
    final masteredCount = member.songProgress.values
        .where((status) => status == LearningStatus.mastered)
        .length;
    final inProgressCount = member.songProgress.values
        .where((status) => status == LearningStatus.inProgress)
        .length;
    final totalSongs = member.songProgress.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    member.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _getVoicePartLabel(member.voicePart),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getVoicePartColor(member.voicePart).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getVoicePartLabel(member.voicePart),
                    style: TextStyle(
                      color: _getVoicePartColor(member.voicePart),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Progression
            Row(
              children: [
                Expanded(
                  child: _buildProgressIndicator(
                    'Maîtrisé',
                    masteredCount,
                    totalSongs,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildProgressIndicator(
                    'En cours',
                    inProgressCount,
                    totalSongs,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(String label, int count, int total, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: $count/$total',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: total > 0 ? count / total : 0,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
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

  Color _getVoicePartColor(String voicePart) {
    switch (voicePart) {
      case 'soprano':
        return Colors.pink;
      case 'alto':
        return Colors.purple;
      case 'tenor':
        return Theme.of(context).colorScheme.primary;
      case 'bass':
        return Colors.indigo;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}
