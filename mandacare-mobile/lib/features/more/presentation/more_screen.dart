import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/layout/adaptive_layout.dart';
import '../../../shared/presentation/widgets/action_tile.dart';
import '../../../shared/presentation/widgets/feature_header.dart';
import '../../auth/domain/auth_session.dart';
import '../../tariff/data/tariff_gateway.dart';
import '../../tariff/presentation/tariff_management_screen.dart';
import '../../users/data/user_gateway.dart';
import '../../users/presentation/user_management_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({
    required this.session,
    required this.userGateway,
    required this.tariffGateway,
    super.key,
  });

  final AuthSession session;
  final UserGateway userGateway;
  final TariffGateway tariffGateway;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          FeatureHeader(
            title: 'Profil utilisateur',
            subtitle: 'Compte, rôle et modules',
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
                      _ProfileCard(session: session),
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
                        subtitle: session.roleCode == 'ADMIN'
                            ? 'Utilisateurs, rôles et accès'
                            : 'Réservé aux administrateurs',
                        onTap: session.roleCode == 'ADMIN'
                            ? () => _openTeam(context)
                            : null,
                        trailing: session.roleCode == 'ADMIN'
                            ? null
                            : _UnavailableBadge(label: 'Admin'),
                      ),
                      const SizedBox(height: 18),
                      const _SectionTitle(title: 'Configuration'),
                      const SizedBox(height: 10),
                      ActionTile(
                        icon: Icons.price_change_rounded,
                        title: 'Grille tarifaire',
                        subtitle: session.roleCode == 'ADMIN'
                            ? 'Examens labo et actes de soins'
                            : 'Réservé aux administrateurs',
                        onTap: session.roleCode == 'ADMIN'
                            ? () => _openTariff(context)
                            : null,
                        trailing: session.roleCode == 'ADMIN'
                            ? null
                            : _UnavailableBadge(label: 'Admin'),
                      ),
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

  void _openTeam(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            UserManagementScreen(session: session, userGateway: userGateway),
      ),
    );
  }

  void _openTariff(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TariffManagementScreen(
          session: session,
          tariffGateway: tariffGateway,
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    final roleDescription = session.roleDescription?.trim();

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
            child: _ProfileInitials(initials: session.initials),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _RoleBadge(
                      code: session.roleCode,
                      label: session.roleLabel,
                    ),
                    _UsernameBadge(username: session.username),
                  ],
                ),
                if (roleDescription != null && roleDescription.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    roleDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.code, required this.label});

  final String code;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_roleIcon(code), color: AppColors.premiumGold, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  IconData _roleIcon(String code) {
    return switch (code.toUpperCase()) {
      'ADMIN' => Icons.admin_panel_settings_rounded,
      'MEDECIN' => Icons.medical_services_rounded,
      'INFIRMIER' => Icons.health_and_safety_rounded,
      'CAISSIER' => Icons.point_of_sale_rounded,
      'LABORATOIRE' => Icons.science_rounded,
      'ACCUEIL' => Icons.support_agent_rounded,
      _ => Icons.badge_rounded,
    };
  }
}

class _UsernameBadge extends StatelessWidget {
  const _UsernameBadge({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return Text(
      '@$username',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Colors.white.withValues(alpha: 0.78),
        fontWeight: FontWeight.w600,
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
  const _UnavailableBadge({this.label = 'À raccorder'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
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
