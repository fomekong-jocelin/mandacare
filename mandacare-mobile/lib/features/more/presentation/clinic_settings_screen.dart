import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/widgets/page_header.dart';
import '../../auth/domain/auth_session.dart';
import '../data/clinic_gateway.dart';

class ClinicSettingsScreen extends StatelessWidget {
  const ClinicSettingsScreen({
    required this.session,
    required this.clinicGateway,
    super.key,
  });

  final AuthSession session;
  final ClinicGateway clinicGateway;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            const PageHeader(
              title: 'Clinique',
              subtitle: 'Paramètres du centre de soins',
            ),
            Expanded(
              child: FutureBuilder<ClinicSettings>(
                future: clinicGateway.getSettings(session: session),
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
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                          color: AppColors.deepHealthBlue.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.deepHealthBlue.withValues(alpha: 0.15),
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
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              const Divider(height: 20),
                              _buildSettingItem(
                                context,
                                icon: Icons.location_city_rounded,
                                label: 'Ville / Quartier',
                                value: settings.city,
                              ),
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
}
