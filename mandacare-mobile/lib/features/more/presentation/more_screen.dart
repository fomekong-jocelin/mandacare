import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/layout/adaptive_layout.dart';
import '../../../shared/presentation/widgets/action_tile.dart';
import '../../../shared/presentation/widgets/feature_header.dart';
import '../../../shared/presentation/widgets/metric_strip.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          FeatureHeader(
            title: 'Plus',
            subtitle: 'Modules, équipe et paramètres',
            actionIcon: Icons.settings_rounded,
            actionTooltip: 'Paramètres',
            onActionPressed: () {},
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    14,
                    16,
                    AdaptiveLayout.bottomContentPadding(context),
                  ),
                  sliver: SliverList.list(
                    children: const [
                      _ProfileCard(),
                      SizedBox(height: 14),
                      MetricStrip(
                        items: [
                          MetricStripItem(
                            value: '6',
                            label: 'membres',
                            color: AppColors.deepHealthBlue,
                          ),
                          MetricStripItem(
                            value: '3',
                            label: 'stocks bas',
                            color: AppColors.warning,
                          ),
                          MetricStripItem(
                            value: '24',
                            label: 'alertes',
                            color: AppColors.medicalGreen,
                          ),
                        ],
                      ),
                      SizedBox(height: 18),
                      _SectionTitle(title: 'Gestion'),
                      SizedBox(height: 10),
                      ActionTile(
                        icon: Icons.local_pharmacy_rounded,
                        title: 'Stock pharmacie',
                        subtitle: 'Médicaments, alertes et inventaire',
                      ),
                      SizedBox(height: 10),
                      ActionTile(
                        icon: Icons.analytics_rounded,
                        title: 'Rapports',
                        subtitle: 'Activité, recettes et fréquentation',
                      ),
                      SizedBox(height: 10),
                      ActionTile(
                        icon: Icons.groups_rounded,
                        title: 'Équipe',
                        subtitle: 'Rôles, accès et permissions',
                      ),
                      SizedBox(height: 18),
                      _SectionTitle(title: 'Configuration'),
                      SizedBox(height: 10),
                      ActionTile(
                        icon: Icons.business_rounded,
                        title: 'Clinique',
                        subtitle: 'Identité, horaires et services',
                      ),
                      SizedBox(height: 10),
                      ActionTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Support',
                        subtitle: 'Assistance et documentation',
                      ),
                    ],
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

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.deepHealthBlue,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepHealthBlue.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 27,
            backgroundColor: Colors.white,
            child: Text(
              'DM',
              style: TextStyle(
                color: AppColors.deepHealthBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr Manda',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Administrateur · MandaCare',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.76),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified_rounded, color: AppColors.premiumGold),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppColors.deepHealthBlue,
        fontSize: 15.5,
        fontWeight: FontWeight.w700,
        height: 1.12,
      ),
    );
  }
}
