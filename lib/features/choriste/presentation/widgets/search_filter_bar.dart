import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../i18n/strings.g.dart';
import '../../models/song_model.dart';  

class SearchFilterBar extends StatelessWidget {
  final String searchQuery;
  
  final Function(String) onSearchChanged;
 

  const SearchFilterBar({
    super.key,
    required this.searchQuery,
 
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);

    return Column(
      children: [
        // Barre de recherche
        TextField(
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: t.dashboard.searchSongs,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => onSearchChanged(''),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),

       
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: chipColor,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (color != null
                    ? Colors.white
                    : Theme.of(context).colorScheme.onPrimary)
                : chipColor,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
