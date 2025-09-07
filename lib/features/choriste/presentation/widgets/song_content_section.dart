import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../i18n/strings.g.dart';
import '../../models/song_model.dart';

class SongContentSection extends StatefulWidget {
  final Song song;
  final String voicePart;

  const SongContentSection({
    super.key,
    required this.song,
    required this.voicePart,
  });

  @override
  State<SongContentSection> createState() => _SongContentSectionState();
}

class _SongContentSectionState extends State<SongContentSection> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final hasPhonetics = widget.song.phonetics != null &&
        widget.song.phonetics![widget.voicePart] != null;
    final hasTranslation = widget.song.translation != null &&
        widget.song.translation![widget.voicePart] != null;

    final tabs = <String>[];
    tabs.add(t.song.lyrics);
    if (hasPhonetics) tabs.add(t.song.phonetics);
    if (hasTranslation) tabs.add(t.song.translation);

    return Card(
      child: Column(
        children: [
          // Onglets de contenu
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: tabs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tab = entry.value;
                  final isSelected = _selectedTabIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        tab,
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Contenu de l'onglet sélectionné
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildTabContent(tabs[_selectedTabIndex]),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(String tabName) {
    final t = Translations.of(context);
    String content = '';

    if (tabName == t.song.lyrics) {
      content =
          widget.song.lyrics[widget.voicePart] ?? 'Paroles non disponibles';
    } else if (tabName == t.song.phonetics && widget.song.phonetics != null) {
      content = widget.song.phonetics![widget.voicePart] ??
          'Phonétique non disponible';
    } else if (tabName == t.song.translation &&
        widget.song.translation != null) {
      content = widget.song.translation![widget.voicePart] ??
          'Traduction non disponible';
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tabName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
