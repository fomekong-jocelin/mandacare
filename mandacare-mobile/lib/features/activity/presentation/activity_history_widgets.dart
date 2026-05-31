import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/api/api_client.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/document_preview_share_screen.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/activity_history_item.dart';

part 'activity_history_details.dart';
part 'activity_history_detail_components.dart';
part 'activity_history_filters.dart';

const activityAllStatuses = '__all__';

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
    required this.period,
    required this.statusFilter,
    required this.onPeriodChanged,
    required this.onStatusChanged,
    required this.onRetry,
    this.session,
    this.apiClient,
    super.key,
  });

  final List<ConsultationHistoryItem> items;
  final bool loading;
  final String? error;
  final ActivityHistoryPeriod period;
  final String statusFilter;
  final ValueChanged<ActivityHistoryPeriod> onPeriodChanged;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onRetry;
  final AuthSession? session;
  final ApiClient? apiClient;

  @override
  Widget build(BuildContext context) {
    final visibleItems = _filterStatus(items, statusFilter);
    return _HistoryShell(
      loading: loading,
      error: error,
      emptyTitle: 'Aucune consultation',
      emptyMessage: 'Aucune consultation ne correspond aux filtres.',
      onRetry: onRetry,
      filters: _filters(items, period, statusFilter),
      onPeriodChanged: onPeriodChanged,
      onStatusChanged: onStatusChanged,
      children: [
        for (final item in visibleItems)
          _HistoryTile(
            icon: Icons.medical_services_rounded,
            title: item.patientName,
            subtitle: item.diagnosis,
            meta: '${item.patientNumber} · ${_formatDateTime(item.createdAt)}',
            badge: _statusLabel(item.status),
            detail: item.reason,
            onTap: () => _showConsultationDetails(
              context,
              item,
              session: session,
              apiClient: apiClient,
            ),
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
    required this.period,
    required this.statusFilter,
    required this.onPeriodChanged,
    required this.onStatusChanged,
    required this.onRetry,
    this.session,
    this.apiClient,
    super.key,
  });

  final List<CashDeskHistoryItem> items;
  final bool loading;
  final String? error;
  final ActivityHistoryPeriod period;
  final String statusFilter;
  final ValueChanged<ActivityHistoryPeriod> onPeriodChanged;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onRetry;
  final AuthSession? session;
  final ApiClient? apiClient;

  @override
  Widget build(BuildContext context) {
    final visibleItems = _filterStatus(items, statusFilter);
    return _HistoryShell(
      loading: loading,
      error: error,
      emptyTitle: 'Aucun encaissement',
      emptyMessage: 'Aucun encaissement ne correspond aux filtres.',
      onRetry: onRetry,
      filters: _filters(items, period, statusFilter),
      onPeriodChanged: onPeriodChanged,
      onStatusChanged: onStatusChanged,
      children: [
        for (final item in visibleItems)
          _HistoryTile(
            icon: Icons.receipt_long_rounded,
            title: item.patientName,
            subtitle: '${_formatAmount(item.paidAmount)} FCFA encaissé',
            meta: '${item.invoiceNumber} · ${_formatDateTime(item.createdAt)}',
            badge: _statusLabel(item.status),
            detail: item.remainingAmount > 0
                ? 'Reste ${_formatAmount(item.remainingAmount)} FCFA'
                : 'Soldé',
            onTap: () => _showCashDeskDetails(
              context,
              item,
              session: session,
              apiClient: apiClient,
            ),
          ),
      ],
    );
  }
}

class _HistoryShell<T> extends StatelessWidget {
  const _HistoryShell({
    required this.loading,
    required this.error,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.onRetry,
    required this.filters,
    required this.onPeriodChanged,
    required this.onStatusChanged,
    required this.children,
  });

  final bool loading;
  final String? error;
  final String emptyTitle;
  final String emptyMessage;
  final VoidCallback onRetry;
  final _HistoryFilters filters;
  final ValueChanged<ActivityHistoryPeriod> onPeriodChanged;
  final ValueChanged<String> onStatusChanged;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PeriodFilter(selected: filters.period, onChanged: onPeriodChanged),
        const SizedBox(height: 8),
        _StatusFilter(
          selected: filters.status,
          values: filters.statusValues,
          onChanged: onStatusChanged,
        ),
        const SizedBox(height: 14),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (error != null)
          _HistoryMessage(
            icon: Icons.cloud_off_rounded,
            title: 'Historique indisponible',
            message: error!,
            action: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          )
        else if (children.isEmpty)
          _HistoryMessage(
            icon: Icons.history_rounded,
            title: emptyTitle,
            message: emptyMessage,
          )
        else
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
    required this.badge,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String meta;
  final String badge;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
          ),
          child: Row(
            children: [
              _HistoryIcon(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: _HistoryText(
                  title: title,
                  subtitle: subtitle,
                  meta: meta,
                  detail: detail,
                  badge: badge,
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.border),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryText extends StatelessWidget {
  const _HistoryText({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.detail,
    required this.badge,
  });

  final String title;
  final String subtitle;
  final String meta;
  final String detail;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            _SoftBadge(label: badge),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 3),
        Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _HistoryIcon extends StatelessWidget {
  const _HistoryIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.medicalGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: AppColors.medicalGreen, size: 22),
    );
  }
}

class _PeriodFilter extends StatelessWidget {
  const _PeriodFilter({required this.selected, required this.onChanged});

  final ActivityHistoryPeriod selected;
  final ValueChanged<ActivityHistoryPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return _ChipRow(
      children: [
        for (final period in ActivityHistoryPeriod.values)
          ChoiceChip(
            label: Text(period.label),
            selected: period == selected,
            onSelected: (_) => onChanged(period),
          ),
      ],
    );
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({
    required this.selected,
    required this.values,
    required this.onChanged,
  });

  final String selected;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _ChipRow(
      children: [
        ChoiceChip(
          label: const Text('Tous statuts'),
          selected: selected == activityAllStatuses,
          onSelected: (_) => onChanged(activityAllStatuses),
        ),
        for (final value in values)
          ChoiceChip(
            label: Text(_statusLabel(value)),
            selected: selected == value,
            onSelected: (_) => onChanged(value),
          ),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) => children[index],
      ),
    );
  }
}

class _SoftBadge extends StatelessWidget {
  const _SoftBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 116),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.medicalGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.medicalGreen,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
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
