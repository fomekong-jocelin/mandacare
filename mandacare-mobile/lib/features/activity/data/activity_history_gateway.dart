import '../../../app/api/api_client.dart';
import '../../auth/domain/auth_session.dart';
import '../../patients/data/patient_gateway.dart';
import '../domain/activity_history_item.dart';

abstract class ActivityHistoryGateway {
  Future<List<ConsultationHistoryItem>> listConsultations({
    required AuthSession session,
    ActivityHistoryPeriod period = ActivityHistoryPeriod.thirtyDays,
    int limit = 50,
  });

  Future<List<CashDeskHistoryItem>> listCashDesk({
    required AuthSession session,
    ActivityHistoryPeriod period = ActivityHistoryPeriod.thirtyDays,
    int limit = 50,
  });
}

class BackendActivityHistoryGateway implements ActivityHistoryGateway {
  const BackendActivityHistoryGateway(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<List<ConsultationHistoryItem>> listConsultations({
    required AuthSession session,
    ActivityHistoryPeriod period = ActivityHistoryPeriod.thirtyDays,
    int limit = 50,
  }) async {
    final response = await apiClient.getJsonList(
      '/activity/consultations',
      query: _query(period, limit),
      token: session.accessToken,
    );
    return response
        .whereType<Map<String, dynamic>>()
        .map(_consultationFromJson)
        .toList(growable: false);
  }

  @override
  Future<List<CashDeskHistoryItem>> listCashDesk({
    required AuthSession session,
    ActivityHistoryPeriod period = ActivityHistoryPeriod.thirtyDays,
    int limit = 50,
  }) async {
    final response = await apiClient.getJsonList(
      '/activity/cash-desk',
      query: _query(period, limit),
      token: session.accessToken,
    );
    return response
        .whereType<Map<String, dynamic>>()
        .map(_cashDeskFromJson)
        .toList(growable: false);
  }

  static ConsultationHistoryItem _consultationFromJson(
    Map<String, dynamic> json,
  ) {
    return ConsultationHistoryItem(
      id: _string(json['id']),
      visitId: _optionalString(json['visitId']),
      patientId: _string(json['patientId']),
      patientName: _string(json['patientName'], fallback: 'Patient'),
      patientNumber: _string(json['patientNumber'], fallback: '-'),
      reason: _string(json['reason'], fallback: 'Motif non renseigné'),
      diagnosis: _string(
        json['diagnosis'],
        fallback: 'Diagnostic non renseigné',
      ),
      status: _string(json['status']),
      decision: _string(json['decision']),
      hasPrescription: _bool(json['hasPrescription']),
      createdAt: _dateTime(json['createdAt']),
    );
  }

  static CashDeskHistoryItem _cashDeskFromJson(Map<String, dynamic> json) {
    return CashDeskHistoryItem(
      invoiceId: _string(json['invoiceId']),
      visitId: _optionalString(json['visitId']),
      patientId: _string(json['patientId']),
      invoiceNumber: _string(json['invoiceNumber'], fallback: '-'),
      patientName: _string(json['patientName'], fallback: 'Patient'),
      netAmount: _double(json['netAmount']),
      paidAmount: _double(json['paidAmount']),
      remainingAmount: _double(json['remainingAmount']),
      status: _string(json['status']),
      createdAt: _dateTime(json['createdAt']),
    );
  }
}

class EmptyActivityHistoryGateway implements ActivityHistoryGateway {
  const EmptyActivityHistoryGateway();

  @override
  Future<List<ConsultationHistoryItem>> listConsultations({
    required AuthSession session,
    ActivityHistoryPeriod period = ActivityHistoryPeriod.thirtyDays,
    int limit = 50,
  }) async => const [];

  @override
  Future<List<CashDeskHistoryItem>> listCashDesk({
    required AuthSession session,
    ActivityHistoryPeriod period = ActivityHistoryPeriod.thirtyDays,
    int limit = 50,
  }) async => const [];
}

ActivityHistoryGateway activityHistoryGatewayFor(PatientGateway gateway) {
  if (gateway is BackendPatientGateway) {
    return BackendActivityHistoryGateway(gateway.apiClient);
  }
  return const EmptyActivityHistoryGateway();
}

String _string(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return fallback;
}

String? _optionalString(Object? value) {
  final text = _string(value);
  return text.isEmpty ? null : text;
}

double _double(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}

bool _bool(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    return value.toLowerCase() == 'true';
  }
  return false;
}

DateTime _dateTime(Object? value) {
  if (value is String) {
    return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
  }
  return DateTime.now();
}

Map<String, String> _query(ActivityHistoryPeriod period, int limit) {
  final query = {'limit': limit.toString()};
  final from = period.from;
  final to = period.to;
  if (from != null) {
    query['from'] = _dateOnly(from);
  }
  if (to != null) {
    query['to'] = _dateOnly(to);
  }
  return query;
}

String _dateOnly(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
