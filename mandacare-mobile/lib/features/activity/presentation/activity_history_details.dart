part of 'activity_history_widgets.dart';

void _showConsultationDetails(
  BuildContext context,
  ConsultationHistoryItem item,
) {
  _showHistoryDetails(context, item.patientName, [
    _DetailRow('Patient', item.patientNumber),
    _DetailRow('Motif', item.reason),
    _DetailRow('Diagnostic', item.diagnosis),
    _DetailRow('Statut', _statusLabel(item.status)),
    _DetailRow('Décision', _statusLabel(item.decision)),
    _DetailRow('Date', _formatDateTime(item.createdAt)),
  ]);
}

void _showCashDeskDetails(BuildContext context, CashDeskHistoryItem item) {
  _showHistoryDetails(context, item.patientName, [
    _DetailRow('Facture', item.invoiceNumber),
    _DetailRow('Statut', _statusLabel(item.status)),
    _DetailRow('Net à payer', '${_formatAmount(item.netAmount)} FCFA'),
    _DetailRow('Encaissé', '${_formatAmount(item.paidAmount)} FCFA'),
    _DetailRow('Reste', '${_formatAmount(item.remainingAmount)} FCFA'),
    _DetailRow('Date', _formatDateTime(item.createdAt)),
  ]);
}

void _showHistoryDetails(
  BuildContext context,
  String title,
  List<_DetailRow> rows,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.deepHealthBlue,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            for (final row in rows) ...[
              Text(row.label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 3),
              Text(row.value),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    ),
  );
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
