import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/widgets/compact_form_field.dart';
import '../../../shared/presentation/widgets/form_dialog.dart';
import '../../../shared/presentation/widgets/page_header.dart';
import '../../auth/data/auth_gateway.dart';
import '../../auth/domain/auth_session.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    required this.session,
    required this.authGateway,
    required this.onSessionChanged,
    super.key,
  });

  final AuthSession session;
  final AuthGateway authGateway;
  final ValueChanged<AuthSession> onSessionChanged;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late AuthSession _currentSession;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session;
  }

  void _showEditProfileDialog() {
    final nameParts = _currentSession.displayName.trim().split(RegExp(r'\s+'));
    final defaultFirstName = nameParts.isNotEmpty ? nameParts.first : '';
    final defaultLastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final firstNameController = TextEditingController(text: defaultFirstName);
    final lastNameController = TextEditingController(text: defaultLastName);
    final phoneController = TextEditingController(text: _currentSession.phone ?? '');
    final emailController = TextEditingController(text: _currentSession.email ?? '');
    final passwordController = TextEditingController();

    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AppFormDialog(
              title: 'Modifier le profil',
              subtitle: 'Mettre à jour mes informations personnelles',
              icon: Icons.person_rounded,
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CompactTextFormField(
                      fieldKey: const ValueKey('profile-edit-firstname'),
                      controller: firstNameController,
                      label: 'Prénom',
                      icon: Icons.person_rounded,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le prénom est requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CompactTextFormField(
                      fieldKey: const ValueKey('profile-edit-lastname'),
                      controller: lastNameController,
                      label: 'Nom',
                      icon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom est requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CompactTextFormField(
                      fieldKey: const ValueKey('profile-edit-phone'),
                      controller: phoneController,
                      label: 'Téléphone',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    CompactTextFormField(
                      fieldKey: const ValueKey('profile-edit-email'),
                      controller: emailController,
                      label: 'Email',
                      icon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    CompactTextFormField(
                      fieldKey: const ValueKey('profile-edit-password'),
                      controller: passwordController,
                      label: 'Nouveau mot de passe',
                      icon: Icons.lock_rounded,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      helperText: 'Laisser vide pour ne pas modifier',
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() => saving = true);

                          try {
                            final updatedSession = await widget.authGateway.updateProfile(
                              accessToken: _currentSession.accessToken,
                              firstName: firstNameController.text.trim(),
                              lastName: lastNameController.text.trim(),
                              phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                              email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                              password: passwordController.text.trim().isEmpty ? null : passwordController.text.trim(),
                            );

                            if (!context.mounted || !dialogContext.mounted) return;
                            widget.onSessionChanged(updatedSession);

                            setState(() {
                              _currentSession = updatedSession;
                              _error = null;
                            });
                            Navigator.of(dialogContext).pop(); // Dismiss dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profil mis à jour avec succès.'),
                                backgroundColor: AppColors.medicalGreen,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => saving = false);
                            if (!context.mounted || !dialogContext.mounted) return;
                            setState(() {
                              _error = 'Erreur lors de la mise à jour : $e';
                            });
                            Navigator.of(dialogContext).pop(); // Dismiss dialog
                          }
                        },
                  icon: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(saving ? 'Enregistrement...' : 'Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: 'Mon profil',
              subtitle: 'Gérer mes informations de compte',
              trailing: IconButton(
                icon: const Icon(
                  Icons.edit_rounded,
                  color: AppColors.medicalGreen,
                ),
                onPressed: _showEditProfileDialog,
                tooltip: 'Modifier le profil',
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFB91C1C)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      color: Colors.white,
                      child: Column(
                        children: [
                          Container(
                            height: 90,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.deepHealthBlue,
                                  AppColors.medicalGreen,
                                ],
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -40),
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.deepHealthBlue.withValues(alpha: 0.15),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 40,
                                    backgroundColor: AppColors.deepHealthBlue,
                                    child: Text(
                                      _currentSession.initials,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    _currentSession.displayName,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: AppColors.deepHealthBlue,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 22,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '@${_currentSession.username}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.medicalGreen.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.medicalGreen.withValues(alpha: 0.20)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.verified_user_rounded,
                                        color: AppColors.medicalGreen,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _currentSession.roleLabel,
                                        style: const TextStyle(
                                          color: AppColors.medicalGreen,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.deepHealthBlue.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.badge_rounded,
                                    color: AppColors.deepHealthBlue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Coordonnées',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: AppColors.deepHealthBlue,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildInfoRow(
                              Icons.phone_rounded,
                              'Téléphone',
                              _currentSession.phone ?? 'Non renseigné',
                            ),
                            const Divider(height: 20),
                            _buildInfoRow(
                              Icons.email_rounded,
                              'Adresse email',
                              _currentSession.email ?? 'Non renseignée',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _showEditProfileDialog,
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text(
                        'Modifier mon profil',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.deepHealthBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.lightBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(icon, color: AppColors.deepHealthBlue, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.deepHealthBlue,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
