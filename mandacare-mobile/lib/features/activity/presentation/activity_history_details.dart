part of 'activity_history_widgets.dart';

void _showConsultationDetails(
  BuildContext context,
  ConsultationHistoryItem item,
) {
  _showActivityDetails(
    context,
    title: item.patientName,
    subtitle: '${item.patientNumber} · ${_formatDateTime(item.createdAt)}',
    icon: Icons.monitor_heart_rounded,
    accent: AppColors.medicalGreen,
    heroLabel: 'Diagnostic',
    heroValue: item.diagnosis,
    heroMeta: item.reason,
    chips: [_statusLabel(item.status), _statusLabel(item.decision)],
    metrics: [
      _MetricInfo('Patient', item.patientNumber),
      _MetricInfo('Date', _formatDateTime(item.createdAt)),
    ],
    sections: [
      _DetailSection('Dossier clinique', Icons.assignment_rounded, [
        _DetailRow('Motif', item.reason),
        _DetailRow('Diagnostic', item.diagnosis),
      ]),
      _DetailSection('Parcours', Icons.route_rounded, [
        _DetailRow('Statut', _statusLabel(item.status)),
        _DetailRow('Décision', _statusLabel(item.decision)),
      ]),
    ],
  );
}

void _showCashDeskDetails(BuildContext context, CashDeskHistoryItem item) {
  final remaining = item.remainingAmount > 0
      ? '${_formatAmount(item.remainingAmount)} FCFA'
      : 'Soldé';
  _showActivityDetails(
    context,
    title: item.patientName,
    subtitle: '${item.invoiceNumber} · ${_formatDateTime(item.createdAt)}',
    icon: Icons.receipt_long_rounded,
    accent: AppColors.premiumGold,
    heroLabel: 'Reste à payer',
    heroValue: remaining,
    heroMeta: '${_formatAmount(item.paidAmount)} FCFA encaissé',
    chips: [_statusLabel(item.status)],
    metrics: [
      _MetricInfo('Net', '${_formatAmount(item.netAmount)} FCFA'),
      _MetricInfo('Encaissé', '${_formatAmount(item.paidAmount)} FCFA'),
      _MetricInfo('Reste', remaining),
    ],
    sections: [
      _DetailSection('Paiement', Icons.payments_rounded, [
        _DetailRow('Net à payer', '${_formatAmount(item.netAmount)} FCFA'),
        _DetailRow(
          'Montant encaissé',
          '${_formatAmount(item.paidAmount)} FCFA',
        ),
        _DetailRow('Reste à payer', remaining),
      ]),
      _DetailSection('Facture', Icons.description_rounded, [
        _DetailRow('Statut', _statusLabel(item.status)),
        _DetailRow('Numéro', item.invoiceNumber),
        _DetailRow('Date', _formatDateTime(item.createdAt)),
      ]),
    ],
  );
}

void _showActivityDetails(
  BuildContext context, {
  required String title,
  required String subtitle,
  required IconData icon,
  required Color accent,
  required String heroLabel,
  required String heroValue,
  required String heroMeta,
  required List<String> chips,
  required List<_MetricInfo> metrics,
  required List<_DetailSection> sections,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.88,
      child: _ActivityDetailSheet(
        title: title,
        subtitle: subtitle,
        icon: icon,
        accent: accent,
        heroLabel: heroLabel,
        heroValue: heroValue,
        heroMeta: heroMeta,
        chips: chips,
        metrics: metrics,
        sections: sections,
      ),
    ),
  );
}

class _ActivityDetailSheet extends StatelessWidget {
  const _ActivityDetailSheet({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.heroLabel,
    required this.heroValue,
    required this.heroMeta,
    required this.chips,
    required this.metrics,
    required this.sections,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String heroLabel;
  final String heroValue;
  final String heroMeta;
  final List<String> chips;
  final List<_MetricInfo> metrics;
  final List<_DetailSection> sections;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: Material(
        color: AppColors.lightBackground,
        child: SafeArea(
          top: false,
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: _SheetHandle()),
              SliverToBoxAdapter(
                child: _PremiumHeader(
                  title: title,
                  subtitle: subtitle,
                  accent: accent,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                sliver: SliverList.list(
                  children: [
                    _HeroSummary(
                      accent: accent,
                      label: heroLabel,
                      value: heroValue,
                      meta: heroMeta,
                      chips: chips,
                    ),
                    const SizedBox(height: 12),
                    _MetricGrid(items: metrics, accent: accent),
                    const SizedBox(height: 14),
                    for (final section in sections) ...[
                      _DetailSectionCard(section: section, accent: accent),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 54,
        height: 4,
        margin: const EdgeInsets.only(top: 12, bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.border.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _PremiumHeader extends StatelessWidget {
  const _PremiumHeader({
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 20),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.deepHealthBlue.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 3,
            height: 42,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.deepHealthBlue,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 25),
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}

String _formatAmount(double value) {
  return value.round().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ' ',
  );
}

String _statusLabel(String status) {
  return status
      .replaceAll('_', ' ')
      .toLowerCase()
      .replaceFirstMapped(
        RegExp(r'^[a-z]'),
        (match) => match[0]!.toUpperCase(),
      );
}
