import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
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
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              title: Text(
                'Modifier le profil',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.deepHealthBlue,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        key: const ValueKey('profile-edit-firstname'),
                        controller: firstNameController,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Prénom',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le prénom est requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const ValueKey('profile-edit-lastname'),
                        controller: lastNameController,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Nom',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le nom est requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const ValueKey('profile-edit-phone'),
                        controller: phoneController,
                        enabled: !saving,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const ValueKey('profile-edit-email'),
                        controller: emailController,
                        enabled: !saving,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const ValueKey('profile-edit-password'),
                        controller: passwordController,
                        enabled: !saving,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Nouveau mot de passe (optionnel)',
                          border: OutlineInputBorder(),
                          helperText: 'Laisser vide pour ne pas modifier',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
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

                            if (!context.mounted) return;
                            widget.onSessionChanged(updatedSession);

                            setState(() {
                              _currentSession = updatedSession;
                              _error = null;
                            });
                            Navigator.of(context).pop(); // Dismiss dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profil mis à jour avec succès.'),
                                backgroundColor: AppColors.medicalGreen,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => saving = false);
                            if (!context.mounted) return;
                            setState(() {
                              _error = 'Erreur lors de la mise à jour : $e';
                            });
                            Navigator.of(context).pop(); // Dismiss dialog
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepHealthBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: saving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Enregistrer'),
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
            const PageHeader(
              title: 'Mon profil',
              subtitle: 'Gérer mes informations de compte',
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
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            CircleAvatar(
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
                            const SizedBox(height: 12),
                            Text(
                              _currentSession.displayName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.deepHealthBlue,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '@${_currentSession.username}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.medicalGreen.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _currentSession.roleLabel,
                                style: const TextStyle(
                                  color: AppColors.medicalGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Coordonnées',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.deepHealthBlue,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              Icons.phone_rounded,
                              'Téléphone',
                              _currentSession.phone ?? 'Non renseigné',
                            ),
                            const Divider(height: 24),
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
                    ElevatedButton.icon(
                      onPressed: _showEditProfileDialog,
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text(
                        'Modifier mes informations',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepHealthBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
        Icon(icon, color: AppColors.deepHealthBlue, size: 20),
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
              const SizedBox(height: 2),
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
