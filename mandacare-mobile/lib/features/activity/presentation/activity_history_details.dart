part of 'activity_history_widgets.dart';

void _showConsultationDetails(
  BuildContext context,
  ConsultationHistoryItem item,
) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _ActivityDetailScreen(
        title: item.patientName,
        subtitle: '${item.patientNumber} · ${_formatDateTime(item.createdAt)}',
        icon: Icons.medical_services_rounded,
        sections: [
          _DetailSection('Consultation', [
            _DetailRow('Motif', item.reason),
            _DetailRow('Diagnostic', item.diagnosis),
          ]),
          _DetailSection('Orientation', [
            _DetailRow('Statut', _statusLabel(item.status)),
            _DetailRow('Décision', _statusLabel(item.decision)),
          ]),
        ],
      ),
    ),
  );
}

void _showCashDeskDetails(BuildContext context, CashDeskHistoryItem item) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _ActivityDetailScreen(
        title: item.patientName,
        subtitle: '${item.invoiceNumber} · ${_formatDateTime(item.createdAt)}',
        icon: Icons.receipt_long_rounded,
        sections: [
          _DetailSection('Paiement', [
            _DetailRow('Net à payer', '${_formatAmount(item.netAmount)} FCFA'),
            _DetailRow('Encaissé', '${_formatAmount(item.paidAmount)} FCFA'),
            _DetailRow('Reste', '${_formatAmount(item.remainingAmount)} FCFA'),
          ]),
          _DetailSection('Facture', [
            _DetailRow('Statut', _statusLabel(item.status)),
            _DetailRow('Numéro', item.invoiceNumber),
          ]),
        ],
      ),
    ),
  );
}

class _ActivityDetailScreen extends StatelessWidget {
  const _ActivityDetailScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.sections,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<_DetailSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _DetailHeader(
                title: title,
                subtitle: subtitle,
                icon: icon,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              sliver: SliverList.list(
                children: [
                  for (final section in sections) ...[
                    _DetailSectionCard(section: section),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.lightBackground.withValues(alpha: 0.98),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepHealthBlue.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.medicalGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.medicalGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.deepHealthBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
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

class _DetailSectionCard extends StatelessWidget {
  const _DetailSectionCard({required this.section});

  final _DetailSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.deepHealthBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          for (final row in section.rows) _DetailField(row: row),
        ],
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.row});

  final _DetailRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            row.value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection {
  const _DetailSection(this.title, this.rows);

  final String title;
  final List<_DetailRow> rows;
}

class _DetailRow {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;
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
