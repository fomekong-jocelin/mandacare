part of 'activity_history_widgets.dart';

class _HistoryFilters {
  const _HistoryFilters(this.period, this.status, this.statusValues);

  final ActivityHistoryPeriod period;
  final String status;
  final List<String> statusValues;
}

_HistoryFilters _filters<T extends Object>(
  List<T> items,
  ActivityHistoryPeriod period,
  String status,
) {
  final values = {
    for (final item in items) _statusOf(item),
  }.where((value) => value.isNotEmpty).toList();
  return _HistoryFilters(period, status, values);
}

List<T> _filterStatus<T extends Object>(List<T> items, String status) {
  if (status == activityAllStatuses) {
    return items;
  }
  return items.where((item) => _statusOf(item) == status).toList();
}

String _statusOf(Object item) {
  if (item is ConsultationHistoryItem) {
    return item.status;
  }
  if (item is CashDeskHistoryItem) {
    return item.status;
  }
  return '';
}
