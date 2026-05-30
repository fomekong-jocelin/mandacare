import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/layout/adaptive_layout.dart';
import '../../../shared/presentation/widgets/action_tile.dart';
import '../../../shared/presentation/widgets/feature_header.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({
    required this.connectedUserName,
    required this.username,
    super.key,
  });

  final String connectedUserName;
  final String username;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          FeatureHeader(
            title: 'Administration',
            subtitle: 'Compte, modules et paramètres',
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
                    children: [
                      _ProfileCard(
                        connectedUserName: connectedUserName,
                        username: username,
                      ),
                      const SizedBox(height: 18),
                      const _SectionTitle(title: 'Gestion'),
                      const SizedBox(height: 10),
                      ActionTile(
                        icon: Icons.local_pharmacy_rounded,
                        title: 'Stock pharmacie',
                        subtitle: 'Module non raccordé',
                        trailing: _UnavailableBadge(),
                      ),
                      const SizedBox(height: 10),
                      ActionTile(
                        icon: Icons.analytics_rounded,
                        title: 'Rapports',
                        subtitle: 'Module non raccordé',
                        trailing: _UnavailableBadge(),
                      ),
                      const SizedBox(height: 10),
                      ActionTile(
                        icon: Icons.groups_rounded,
                        title: 'Équipe',
                        subtitle: 'Module non raccordé',
                        trailing: _UnavailableBadge(),
                      ),
                      const SizedBox(height: 18),
                      const _SectionTitle(title: 'Configuration'),
                      const SizedBox(height: 10),
                      ActionTile(
                        icon: Icons.business_rounded,
                        title: 'Clinique',
                        subtitle: 'Module non raccordé',
                        trailing: _UnavailableBadge(),
                      ),
                      const SizedBox(height: 10),
                      ActionTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Support',
                        subtitle: 'Module non raccordé',
                        trailing: _UnavailableBadge(),
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
  const _ProfileCard({required this.connectedUserName, required this.username});

  final String connectedUserName;
  final String username;

  @override
  Widget build(BuildContext context) {
    final initials = connectedUserName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

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
          CircleAvatar(
            radius: 27,
            backgroundColor: Colors.white,
            child: _ProfileInitials(initials: initials),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connectedUserName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  username,
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

class _ProfileInitials extends StatelessWidget {
  const _ProfileInitials({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Text(
      initials.isEmpty ? 'U' : initials,
      style: const TextStyle(
        color: AppColors.deepHealthBlue,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _UnavailableBadge extends StatelessWidget {
  const _UnavailableBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'À raccorder',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
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
