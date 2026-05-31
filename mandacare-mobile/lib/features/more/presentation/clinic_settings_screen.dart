import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/widgets/compact_form_field.dart';
import '../../../shared/presentation/widgets/form_dialog.dart';
import '../../../shared/presentation/widgets/page_header.dart';
import '../../auth/domain/auth_session.dart';
import '../data/clinic_gateway.dart';

class ClinicSettingsScreen extends StatefulWidget {
  const ClinicSettingsScreen({
    required this.session,
    required this.clinicGateway,
    super.key,
  });

  final AuthSession session;
  final ClinicGateway clinicGateway;

  @override
  State<ClinicSettingsScreen> createState() => _ClinicSettingsScreenState();
}

class _ClinicSettingsScreenState extends State<ClinicSettingsScreen> {
  late Future<ClinicSettings> _settingsFuture;

  bool get _canEdit => widget.session.roleCode == 'ADMIN';

  @override
  void initState() {
    super.initState();
    _settingsFuture = _loadSettings();
  }

  Future<ClinicSettings> _loadSettings() {
    return widget.clinicGateway.getSettings(session: widget.session);
  }

  void _refresh() {
    setState(() => _settingsFuture = _loadSettings());
  }

  void _showEditDialog(ClinicSettings settings) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: settings.name);
    final sloganController = TextEditingController(text: settings.slogan);
    final phoneController = TextEditingController(text: settings.phone ?? '');
    final emailController = TextEditingController(text: settings.email ?? '');
    final cityController = TextEditingController(text: settings.city);
    final addressController = TextEditingController(
      text: settings.address ?? '',
    );
    final poBoxController = TextEditingController(text: settings.poBox ?? '');
    final rccmController = TextEditingController(text: settings.rccm ?? '');
    final taxpayerController = TextEditingController(
      text: settings.taxpayerNumber ?? '',
    );
    bool saving = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AppFormDialog(
              title: 'Modifier la clinique',
              subtitle: 'Paramètres utilisés sur les documents',
              icon: Icons.business_rounded,
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CompactTextFormField(
                      controller: nameController,
                      label: 'Nom du centre',
                      icon: Icons.business_rounded,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    CompactTextFormField(
                      controller: sloganController,
                      label: 'Slogan / Devise',
                      icon: Icons.campaign_rounded,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    CompactTextFormField(
                      controller: phoneController,
                      label: 'Téléphone',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    CompactTextFormField(
                      controller: emailController,
                      label: 'Email',
                      icon: Icons.mail_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    CompactTextFormField(
                      controller: cityController,
                      label: 'Ville / Quartier',
                      icon: Icons.location_city_rounded,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    CompactTextFormField(
                      controller: addressController,
                      label: 'Localisation / Adresse',
                      icon: Icons.place_rounded,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CompactTextFormField(
                            controller: poBoxController,
                            label: 'BP',
                            icon: Icons.markunread_mailbox_rounded,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CompactTextFormField(
                            controller: rccmController,
                            label: 'RCCM',
                            icon: Icons.badge_rounded,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CompactTextFormField(
                      controller: taxpayerController,
                      label: 'N° contribuable',
                      icon: Icons.receipt_long_rounded,
                      textInputAction: TextInputAction.done,
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => saving = true);
                          try {
                            final updated = await widget.clinicGateway
                                .updateSettings(
                                  session: widget.session,
                                  settings: ClinicSettings(
                                    name: nameController.text.trim(),
                                    slogan: sloganController.text.trim(),
                                    phone: _optional(phoneController.text),
                                    email: _optional(emailController.text),
                                    city: cityController.text.trim(),
                                    address: _optional(addressController.text),
                                    poBox: _optional(poBoxController.text),
                                    rccm: _optional(rccmController.text),
                                    taxpayerNumber: _optional(
                                      taxpayerController.text,
                                    ),
                                  ),
                                );
                            if (!mounted || !dialogContext.mounted) return;
                            setState(() {
                              _settingsFuture = Future.value(updated);
                            });
                            Navigator.of(dialogContext).pop();
                          } catch (_) {
                            setDialogState(() => saving = false);
                          }
                        },
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
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

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Requis';
    }
    return null;
  }

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: 'Clinique',
              subtitle: 'Paramètres du centre de soins',
              trailing: FutureBuilder<ClinicSettings>(
                future: _settingsFuture,
                builder: (context, snapshot) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: _refresh,
                        tooltip: 'Rafraîchir',
                      ),
                      if (_canEdit && snapshot.hasData)
                        IconButton(
                          icon: const Icon(
                            Icons.edit_rounded,
                            color: AppColors.medicalGreen,
                          ),
                          onPressed: () => _showEditDialog(snapshot.data!),
                          tooltip: 'Modifier la clinique',
                        ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: FutureBuilder<ClinicSettings>(
                future: _settingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Impossible de charger les paramètres.',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final settings = snapshot.data!;
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Info Banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.deepHealthBlue.withValues(
                            alpha: 0.05,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.deepHealthBlue.withValues(
                              alpha: 0.15,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.deepHealthBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Ces paramètres du centre sont gérés de manière centralisée sur le serveur. Ils sont automatiquement inclus en en-tête de toutes les ordonnances, factures, reçus et comptes-rendus d\'examens.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.deepHealthBlue,
                                      height: 1.35,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Settings List Card
                      Card(
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: AppColors.border.withValues(alpha: 0.40),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Column(
                            children: [
                              _buildSettingItem(
                                context,
                                icon: Icons.business_rounded,
                                label: 'Nom du centre',
                                value: settings.name,
                              ),
                              const Divider(height: 20),
                              _buildSettingItem(
                                context,
                                icon: Icons.campaign_rounded,
                                label: 'Slogan / Devise',
                                value: settings.slogan,
                              ),
                              if (_hasValue(settings.phone)) ...[
                                const Divider(height: 20),
                                _buildSettingItem(
                                  context,
                                  icon: Icons.phone_rounded,
                                  label: 'Téléphone',
                                  value: settings.phone!,
                                ),
                              ],
                              if (_hasValue(settings.email)) ...[
                                const Divider(height: 20),
                                _buildSettingItem(
                                  context,
                                  icon: Icons.mail_rounded,
                                  label: 'Email',
                                  value: settings.email!,
                                ),
                              ],
                              const Divider(height: 20),
                              _buildSettingItem(
                                context,
                                icon: Icons.location_city_rounded,
                                label: 'Ville / Quartier',
                                value: settings.city,
                              ),
                              if (_hasValue(settings.address)) ...[
                                const Divider(height: 20),
                                _buildSettingItem(
                                  context,
                                  icon: Icons.place_rounded,
                                  label: 'Localisation / Adresse',
                                  value: settings.address!,
                                ),
                              ],
                              if (_hasValue(settings.poBox)) ...[
                                const Divider(height: 20),
                                _buildSettingItem(
                                  context,
                                  icon: Icons.markunread_mailbox_rounded,
                                  label: 'BP',
                                  value: settings.poBox!,
                                ),
                              ],
                              if (_hasValue(settings.rccm)) ...[
                                const Divider(height: 20),
                                _buildSettingItem(
                                  context,
                                  icon: Icons.badge_rounded,
                                  label: 'RCCM',
                                  value: settings.rccm!,
                                ),
                              ],
                              if (_hasValue(settings.taxpayerNumber)) ...[
                                const Divider(height: 20),
                                _buildSettingItem(
                                  context,
                                  icon: Icons.receipt_long_rounded,
                                  label: 'N° contribuable',
                                  value: settings.taxpayerNumber!,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.medicalGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.medicalGreen, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
