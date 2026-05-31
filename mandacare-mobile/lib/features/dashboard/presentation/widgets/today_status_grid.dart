import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/dashboard_today_summary.dart';

class TodayStatusGrid extends StatelessWidget {
  const TodayStatusGrid({
    required this.isTablet,
    required this.summary,
    required this.loading,
    required this.onRetry,
    required this.onOpenPatients,
    required this.onOpenConsultations,
    required this.onOpenLab,
    required this.onOpenCashDesk,
    super.key,
    this.error,
  });

  final bool isTablet;
  final DashboardTodaySummary summary;
  final bool loading;
  final String? error;
  final Future<void> Function() onRetry;
  final VoidCallback onOpenPatients;
  final VoidCallback onOpenConsultations;
  final VoidCallback onOpenLab;
  final VoidCallback onOpenCashDesk;

  @override
  Widget build(BuildContext context) {
    final cards = _cards();
    return Column(
      children: [
        if (error != null) ...[
          _StatusLoadError(message: error!, onRetry: onRetry),
          const SizedBox(height: 10),
        ],
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 4 : 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: isTablet ? 120 : 112,
          ),
          itemBuilder: (context, index) => cards[index],
        ),
      ],
    );
  }

  List<Widget> _cards() {
    final loadingValue = loading ? '...' : null;
    return [
      _StatusCard(
        key: const ValueKey('dashboard-status-card-patients'),
        title: 'Patients du jour',
        value: loadingValue ?? _formatNumber(summary.patientsToday),
        subtitle: loading
            ? 'Chargement'
            : '${summary.activeQueue} dossier(s) actif(s)',
        icon: Icons.group_add_rounded,
        background: const Color(0xFFEAF4FF),
        accent: AppColors.info,
        onTap: onOpenPatients,
      ),
      _StatusCard(
        key: const ValueKey('dashboard-status-card-consultations'),
        title: 'Consultations',
        value: loadingValue ?? _formatNumber(summary.consultationQueue),
        subtitle: loading
            ? 'Chargement'
            : '${summary.consultationsToday} acte(s) saisi(s)',
        icon: Icons.medical_services_rounded,
        background: const Color(0xFFEAF6F1),
        accent: AppColors.medicalGreen,
        onTap: onOpenConsultations,
      ),
      _StatusCard(
        key: const ValueKey('dashboard-status-card-lab'),
        title: 'Labo',
        value: loadingValue ?? _formatNumber(summary.labQueue),
        subtitle: loading
            ? 'Chargement'
            : '${summary.validatedResults} résultat(s) validé(s)',
        icon: Icons.science_rounded,
        background: const Color(0xFFFFF4E1),
        accent: AppColors.warning,
        onTap: onOpenLab,
      ),
      _StatusCard(
        key: const ValueKey('dashboard-status-card-cash-desk'),
        title: 'Caisse',
        value: loadingValue ?? _formatNumber(summary.cashDeskQueue),
        subtitle: loading
            ? 'Chargement'
            : '${_formatFcfa(summary.dailyRevenue)} encaissé(s)',
        icon: Icons.point_of_sale_rounded,
        background: const Color(0xFFF6F0DE),
        accent: AppColors.premiumGold,
        onTap: onOpenCashDesk,
      ),
    ];
  }

  static String _formatNumber(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final remaining = text.length - i;
      buffer.write(text[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  static String _formatFcfa(double value) {
    final rounded = value.round();
    if (rounded == 0) {
      return '0 FCFA';
    }
    return '${_formatNumber(rounded)} FCFA';
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent.withValues(alpha: 0.12)),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Icon(
                  icon,
                  color: accent.withValues(alpha: 0.28),
                  size: 34,
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 38),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: accent.withValues(alpha: 0.42),
                    size: 20,
                  ),
                ),
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
                      fontSize: value.length > 9 ? 20 : 26,
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
        ),
      ),
    );
  }
}

class _StatusLoadError extends StatelessWidget {
  const _StatusLoadError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
