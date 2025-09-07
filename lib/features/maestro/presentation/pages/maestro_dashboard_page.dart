import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/choir_management_provider.dart';
import '../widgets/maestro_header.dart';
import '../widgets/stats_overview.dart';
import '../widgets/choir_members_section.dart';
import '../widgets/repertoire_management_section.dart';
import '../widgets/add_song_fab.dart';

class MaestroDashboardPage extends ConsumerStatefulWidget {
  const MaestroDashboardPage({super.key});

  @override
  ConsumerState<MaestroDashboardPage> createState() => _MaestroDashboardPageState();
}

class _MaestroDashboardPageState extends ConsumerState<MaestroDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user!;
    final stats = ref.watch(choirStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header maestro
            MaestroHeader(user: user),

            // Onglets de navigation
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryBlue,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: AppTheme.primaryBlue,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.dashboard_outlined),
                    text: 'Vue d\'ensemble',
                  ),
                  Tab(
                    icon: Icon(Icons.people_outline),
                    text: 'Choristes',
                  ),
                  Tab(
                    icon: Icon(Icons.library_music_outlined),
                    text: 'Répertoire',
                  ),
                ],
              ),
            ),

            // Contenu des onglets
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Vue d'ensemble
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        StatsOverview(stats: stats),
                        const SizedBox(height: 16),
                        _buildRecentActivity(context),
                        const SizedBox(height: 16),
                        _buildQuickActions(context),
                      ],
                    ),
                  ),

                  // Gestion des choristes
                  const ChoirMembersSection(),

                  // Gestion du répertoire
                  const RepertoireManagementSection(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AddSongFab(
        onPressed: () {
          _showAddSongDialog(context);
        },
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activité récente',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildActivityItem(
              'Marie Dubois a maîtrisé "Ave Maria"',
              'Il y a 2 heures',
              Icons.check_circle,
              Colors.green,
            ),
            _buildActivityItem(
              'Nouveau chant ajouté: "Amazing Grace"',
              'Hier',
              Icons.library_add,
              AppTheme.primaryBlue,
            ),
            _buildActivityItem(
              'Pierre Durand a rejoint le chœur',
              'Il y a 3 jours',
              Icons.person_add,
              AppTheme.secondaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions rapides',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'Ajouter un chant',
                    Icons.add_circle_outline,
                    AppTheme.primaryBlue,
                    () => _showAddSongDialog(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    'Inviter choriste',
                    Icons.person_add_outlined,
                    AppTheme.secondaryBlue,
                    () => _showInviteDialog(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      label: Text(
        label,
        style: TextStyle(color: color),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  void _showAddSongDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un nouveau chant'),
        content: const Text('Cette fonctionnalité sera disponible prochainement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inviter un choriste'),
        content: const Text('Cette fonctionnalité sera disponible prochainement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
