import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../domain/activity_history_item.dart';

class ActivitySegmentedHeader extends StatelessWidget {
  const ActivitySegmentedHeader({
    required this.selectedIndex,
    required this.onSelectionChanged,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 0, label: Text('A traiter')),
        ButtonSegment(value: 1, label: Text('Historique')),
      ],
      selected: {selectedIndex},
      onSelectionChanged: (selection) => onSelectionChanged(selection.first),
      showSelectedIcon: false,
    );
  }
}

class ConsultationHistoryList extends StatelessWidget {
  const ConsultationHistoryList({
    required this.items,
    required this.loading,
    required this.error,
    required this.onRetry,
    super.key,
  });

  final List<ConsultationHistoryItem> items;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _HistoryShell(
      loading: loading,
      error: error,
      emptyTitle: 'Aucune consultation recente',
      emptyMessage: 'Les consultations saisies apparaitront ici.',
      onRetry: onRetry,
      children: [
        for (final item in items)
          _HistoryTile(
            icon: Icons.medical_services_rounded,
            title: item.patientName,
            subtitle: '${item.patientNumber} · ${item.reason}',
            meta:
                '${_formatDateTime(item.createdAt)} · ${_statusLabel(item.status)}',
            amount: item.diagnosis,
          ),
      ],
    );
  }
}

class CashDeskHistoryList extends StatelessWidget {
  const CashDeskHistoryList({
    required this.items,
    required this.loading,
    required this.error,
    required this.onRetry,
    super.key,
  });

  final List<CashDeskHistoryItem> items;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _HistoryShell(
      loading: loading,
      error: error,
      emptyTitle: 'Aucun encaissement recent',
      emptyMessage: 'Les factures et paiements apparaitront ici.',
      onRetry: onRetry,
      children: [
        for (final item in items)
          _HistoryTile(
            icon: Icons.receipt_long_rounded,
            title: item.patientName,
            subtitle: '${item.invoiceNumber} · ${_statusLabel(item.status)}',
            meta: _formatDateTime(item.createdAt),
            amount: '${_formatAmount(item.paidAmount)} FCFA',
          ),
      ],
    );
  }
}

class _HistoryShell extends StatelessWidget {
  const _HistoryShell({
    required this.loading,
    required this.error,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.onRetry,
    required this.children,
  });

  final bool loading;
  final String? error;
  final String emptyTitle;
  final String emptyMessage;
  final VoidCallback onRetry;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return _HistoryMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Historique indisponible',
        message: error!,
        action: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reessayer'),
        ),
      );
    }
    if (children.isEmpty) {
      return _HistoryMessage(
        icon: Icons.history_rounded,
        title: emptyTitle,
        message: emptyMessage,
      );
    }
    return Column(
      children: [
        for (final child in children) ...[child, const SizedBox(height: 10)],
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.amount,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String meta;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.medicalGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 8), action!],
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
