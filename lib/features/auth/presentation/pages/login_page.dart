import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:toastification/toastification.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../i18n/strings.g.dart';
import '../../providers/auth_provider.dart';
import '../widgets/voice_part_selector.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedRole = 'choriste';
  String? _selectedVoicePart;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedRole == 'choriste' && _selectedVoicePart == null) {
      toastification.show(
        context: context,
        title: const Text('Veuillez sélectionner votre pupitre'),
        type: ToastificationType.warning,
        style: ToastificationStyle.fillColored,
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    await ref.read(authProvider.notifier).login(
      name: _nameController.text.trim(),
      role: _selectedRole,
      voicePart: _selectedVoicePart,
    );

    final authState = ref.read(authProvider);
    if (authState.error != null) {
      toastification.show(
        context: context,
        title: Text('Erreur de connexion'),
        description: Text(authState.error!),
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        autoCloseDuration: const Duration(seconds: 3),
      );
    } else if (authState.isAuthenticated) {
      final route = _selectedRole == 'maestro' ? '/maestro' : '/choriste';
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final t = Translations.of(context);
    
    return Scaffold(
      body: Container(
        decoration:  BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo et titre
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child:  Icon(
                            Icons.music_note,
                            size: 40,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        Text(
                          t.app.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        
                        Text(
                          t.app.subtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        
                        // Champ nom
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: t.auth.enterName,
                            hintText: t.auth.namePlaceholder,
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Veuillez entrer votre nom';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        // Sélection du rôle
                        Text(
                          t.auth.selectRole,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _RoleCard(
                                title: t.auth.choriste,
                                icon: Icons.people_outline,
                                isSelected: _selectedRole == 'choriste',
                                onTap: () {
                                  setState(() {
                                    _selectedRole = 'choriste';
                                    _selectedVoicePart = null;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _RoleCard(
                                title: t.auth.maestro,
                                icon: Icons.music_video_outlined,
                                isSelected: _selectedRole == 'maestro',
                                onTap: () {
                                  setState(() {
                                    _selectedRole = 'maestro';
                                    _selectedVoicePart = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        // Sélection du pupitre (si choriste)
                        if (_selectedRole == 'choriste') ...[
                          const SizedBox(height: 24),
                          Text(
                            t.auth.selectVoicePart,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          VoicePartSelector(
                            selectedVoicePart: _selectedVoicePart,
                            onVoicePartSelected: (voicePart) {
                              setState(() {
                                _selectedVoicePart = voicePart;
                              });
                            },
                          ),
                        ],
                        
                        const SizedBox(height: 32),
                        
                        // Bouton de connexion
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: authState.isLoading
                                ? SpinKitThreeBounce(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    size: 20,
                                  )
                                : Text(
                                    t.auth.login,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
