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
    final songsList = songs.valueOrNull ?? [];
    final members = ref.watch(choirMembersProvider);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: songsList.length,
      itemBuilder: (context, index) {
        final song = songsList[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: ListTile(
              title: Text(song.title),
              subtitle: Text('Durée: ${song.duration.inMinutes} min'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                      'Chanté par: ${members.where((m) => m.voicePart == 'soprano').length} S, '
                      '${members.where((m) => m.voicePart == 'alto').length} A, '
                      '${members.where((m) => m.voicePart == 'tenor').length} T, '
                      '${members.where((m) => m.voicePart == 'bass').length} B'),
                  const SizedBox(height: 4),
                  Text('Statut: ${song.availability}'),
                ],
              ),
              onTap: () {
                // Action lors du tap sur un chant (ex: ouvrir les détails)
              },
            ),
          ),
        );
      },
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
}
