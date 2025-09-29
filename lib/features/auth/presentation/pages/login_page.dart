import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:go_router/go_router.dart';

import '../../../../i18n/strings.g.dart';
import '../../providers/auth_provider.dart';

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

  bool get _isFormValid {
    final nameValid = _nameController.text.trim().isNotEmpty;
    final voicePartValid =
        _selectedRole == 'maestro' || _selectedVoicePart != null;
    return nameValid && voicePartValid;
  }

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

    // Check if widget is still mounted after async operation
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.error != null) {
      if (mounted) {
        toastification.show(
          context: context,
          title: Text('Erreur de connexion'),
          description: Text(authState.error!),
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } else if (authState.isAuthenticated) {
      if (mounted) {
        final route = _selectedRole == 'maestro' ? '/maestro' : '/choriste';
        context.go(route);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            width: 360,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header simple
                  Image.asset(
                    'assets/images/shirbook_icon.png',
                    fit: BoxFit.fill,
                    width: 80,
                    height: 80,
                  ),
                  const SizedBox(height: 16),

                  Text(
                    t.app.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      // Use theme primary color for dark/light support
                      color: null,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    t.app.subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Formulaire
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Champ nom
                        TextFormField(
                          controller: _nameController,
                          onChanged: (value) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: t.auth.enterName,
                            hintText: t.auth.namePlaceholder,
                            prefixIcon: const Icon(Icons.person_outline),
                            border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide(
                                  color: colorScheme.primary, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Veuillez entrer votre nom';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Sélection du rôle
                        Text(
                          'Rôle',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _SimpleRoleCard(
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SimpleRoleCard(
                                title: t.auth.maestro,
                                icon: Icons.music_note,
                                isSelected: _selectedRole == 'maestro',
                                isDisabled: true,
                                onTap: () {
                                  toastification.show(
                                    context: context,
                                    title: const Text(
                                        'Fonctionnalité en développement'),
                                    type: ToastificationType.info,
                                    style: ToastificationStyle.fillColored,
                                    autoCloseDuration:
                                        const Duration(seconds: 3),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        // Menu déroulant pour pupitre (si choriste)
                        if (_selectedRole == 'choriste') ...[
                          const SizedBox(height: 20),
                          Text(
                            'Pupitre',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedVoicePart,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide(
                                    color: colorScheme.primary, width: 2),
                              ),
                            ),
                            hint: Text(
                              'Sélectionnez votre pupitre',
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            dropdownColor: colorScheme.surface,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                            ),
                            iconEnabledColor: colorScheme.onSurface,
                            items: [
                              DropdownMenuItem(
                                value: 'soprano',
                                child: Text(
                                  'Soprano',
                                  style:
                                      TextStyle(color: colorScheme.onSurface),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'alto',
                                child: Text(
                                  'Alto',
                                  style:
                                      TextStyle(color: colorScheme.onSurface),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'tenor',
                                child: Text(
                                  'Ténor',
                                  style:
                                      TextStyle(color: colorScheme.onSurface),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'bass',
                                child: Text(
                                  'Basse',
                                  style:
                                      TextStyle(color: colorScheme.onSurface),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedVoicePart = value;
                              });
                            },
                            validator: (value) {
                              if (_selectedRole == 'choriste' &&
                                  value == null) {
                                return 'Veuillez sélectionner votre pupitre';
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 45),
                      ],
                    ),
                  ),

                  // Bouton en bas
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: authState.isLoading || !_isFormValid
                          ? null
                          : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: authState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
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
    );
  }
}

class _SimpleRoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _SimpleRoleCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isDisabledState = isDisabled;
    final bool isSelectedState = isSelected && !isDisabledState;

    final Color cardBackgroundColor = isSelectedState
        ? colorScheme.primary.withOpacity(0.1)
        : theme.colorScheme.surfaceVariant.withOpacity(
            theme.brightness == Brightness.dark ? 0.2 : 0.5,
          );
    final Color borderColor =
        isSelectedState ? colorScheme.primary : theme.colorScheme.outline;
    final Color iconColor = isSelectedState
        ? colorScheme.primary
        : (isDisabledState
            ? theme.colorScheme.onSurface.withOpacity(0.38)
            : theme.colorScheme.onSurfaceVariant);
    final Color textColor = isSelectedState
        ? colorScheme.primary
        : (isDisabledState
            ? theme.colorScheme.onSurface.withOpacity(0.38)
            : theme.colorScheme.onSurface);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            // if (isDisabled) ...[
            //   const SizedBox(height: 4),
            //   Text(
            //     '🚧',
            //     style: TextStyle(fontSize: 12),
            //   ),
            // ],
          ],
        ),
      ),
    );
  }
}
