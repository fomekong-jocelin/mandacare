import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class TodayStatusGrid extends StatelessWidget {
  const TodayStatusGrid({required this.isTablet, super.key});

  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 4 : 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: isTablet ? 116 : 108,
      ),
      itemBuilder: (context, index) => cards[index],
    );
  }

  static const cards = [
    _StatusCard(
      title: 'Patients',
      value: '24',
      subtitle: '+6 vs hier',
      icon: Icons.group_add_rounded,
      background: Color(0xFFEAF4FF),
      accent: AppColors.info,
    ),
    _StatusCard(
      title: 'Consultations',
      value: '16',
      subtitle: '+3 vs hier',
      icon: Icons.medical_services_rounded,
      background: Color(0xFFEAF6F1),
      accent: AppColors.medicalGreen,
    ),
    _StatusCard(
      title: 'Examens',
      value: '8',
      subtitle: '2 urgents',
      icon: Icons.science_rounded,
      background: Color(0xFFFFF4E1),
      accent: AppColors.warning,
    ),
    _StatusCard(
      title: 'Recettes',
      value: '185K',
      subtitle: 'FCFA encaissés',
      icon: Icons.payments_rounded,
      background: Color(0xFFF6F0DE),
      accent: AppColors.premiumGold,
    ),
  ];
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.accent,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Icon(icon, color: accent.withValues(alpha: 0.28), size: 34),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
              const Spacer(),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
