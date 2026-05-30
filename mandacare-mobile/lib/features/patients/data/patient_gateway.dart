import '../../../app/api/api_client.dart';
import '../../../app/api/api_exception.dart';
import '../../auth/domain/auth_session.dart';
import '../../consultations/domain/consultation_decision.dart';
import '../../consultations/domain/create_consultation_payload.dart';
import '../../consultations/domain/prescription.dart';
import '../../dashboard/domain/dashboard_today_summary.dart';
import '../domain/patient_summary.dart';
import '../../cashdesk/domain/invoice_preview.dart';
import '../../consultations/domain/exam.dart';
import '../domain/patient_timeline_item.dart';
import '../domain/vitals_summary.dart';

abstract class PatientGateway {
  Future<List<PatientSummary>> listPatients({
    required AuthSession session,
    String? search,
  });

  Future<List<PatientSummary>> listTodayQueue({
    required AuthSession session,
    PatientStatus? status,
    int limit = 8,
  });

  Future<DashboardTodaySummary> getTodayDashboard({
    required AuthSession session,
  });

  Future<PatientSummary> createPatient({
    required AuthSession session,
    required CreatePatientPayload payload,
  });

  Future<void> createVisit({
    required AuthSession session,
    required String patientId,
    required CreateVisitPayload payload,
  });

  Future<void> changeVisitStatus({
    required AuthSession session,
    required String visitId,
    required PatientStatus status,
  });

  Future<PatientSummary> completeCashDesk({
    required AuthSession session,
    required String visitId,
    required CreateCashDeskPaymentPayload payload,
  });

  Future<void> createVitals({
    required AuthSession session,
    required String visitId,
    required CreateVitalsPayload payload,
  });

  Future<VitalsSummary> getLatestVitals({
    required AuthSession session,
    required String visitId,
  });

  Future<String> createConsultation({
    required AuthSession session,
    required String visitId,
    required CreateConsultationPayload payload,
  });

  Future<List<PatientTimelineItem>> getPatientTimeline({
    required AuthSession session,
    required String patientId,
  });

  Future<Prescription?> getPrescription({
    required AuthSession session,
    required String consultationId,
  });

  Future<void> savePrescription({
    required AuthSession session,
    required String consultationId,
    required CreatePrescriptionPayload payload,
  });

  Future<void> submitLabResults({
    required AuthSession session,
    required String visitId,
    required CreateLabResultPayload payload,
  });

  Future<List<Exam>> listActiveExams({
    required AuthSession session,
  });

  Future<InvoicePreview> getInvoicePreview({
    required AuthSession session,
    required String visitId,
  });
}

class BackendPatientGateway implements PatientGateway {
  const BackendPatientGateway(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<List<PatientSummary>> listPatients({
    required AuthSession session,
    String? search,
  }) async {
    final query = {'limit': '100'};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final response = await apiClient.getJsonList(
      '/patients',
      query: query,
      token: session.accessToken,
    );
    return response
        .whereType<Map<String, dynamic>>()
        .map(_PatientSummaryMapper.fromJson)
        .toList(growable: false);
  }

  @override
  Future<List<PatientSummary>> listTodayQueue({
    required AuthSession session,
    PatientStatus? status,
    int limit = 8,
  }) async {
    final query = {'limit': limit.toString()};
    if (status != null) {
      query['status'] = status.apiValue;
    }

    final response = await apiClient.getJsonList(
      '/patients/queue/today',
      query: query,
      token: session.accessToken,
    );
    return response
        .whereType<Map<String, dynamic>>()
        .map(_PatientSummaryMapper.fromJson)
        .toList(growable: false);
  }

  @override
  Future<DashboardTodaySummary> getTodayDashboard({
    required AuthSession session,
  }) async {
    final response = await apiClient.getJson(
      '/dashboard/today',
      token: session.accessToken,
    );
    return _DashboardTodaySummaryMapper.fromJson(response);
  }

  @override
  Future<PatientSummary> createPatient({
    required AuthSession session,
    required CreatePatientPayload payload,
  }) async {
    final response = await apiClient.postJson(
      '/patients',
      payload.toJson(),
      token: session.accessToken,
    );
    return _PatientSummaryMapper.fromJson(response);
  }

  @override
  Future<void> createVisit({
    required AuthSession session,
    required String patientId,
    required CreateVisitPayload payload,
  }) async {
    await apiClient.postJson(
      '/patients/$patientId/visits',
      payload.toJson(),
      token: session.accessToken,
    );
  }

  @override
  Future<void> changeVisitStatus({
    required AuthSession session,
    required String visitId,
    required PatientStatus status,
  }) async {
    await apiClient.patchJson('/visits/$visitId/status', {
      'status': status.apiValue,
    }, token: session.accessToken);
  }

  @override
  Future<PatientSummary> completeCashDesk({
    required AuthSession session,
    required String visitId,
    required CreateCashDeskPaymentPayload payload,
  }) async {
    final response = await apiClient.patchJson(
      '/visits/$visitId/cash-desk/complete',
      payload.toJson(),
      token: session.accessToken,
    );
    return _PatientSummaryMapper.fromJson(response);
  }

  @override
  Future<void> createVitals({
    required AuthSession session,
    required String visitId,
    required CreateVitalsPayload payload,
  }) async {
    await apiClient.postJson(
      '/visits/$visitId/vitals',
      payload.toJson(),
      token: session.accessToken,
    );
  }

  @override
  Future<VitalsSummary> getLatestVitals({
    required AuthSession session,
    required String visitId,
  }) async {
    final response = await apiClient.getJson(
      '/visits/$visitId/vitals/latest',
      token: session.accessToken,
    );
    return _VitalsSummaryMapper.fromJson(response);
  }

  @override
  Future<String> createConsultation({
    required AuthSession session,
    required String visitId,
    required CreateConsultationPayload payload,
  }) async {
    final response = await apiClient.postJson(
      '/visits/$visitId/consultations',
      payload.toJson(),
      token: session.accessToken,
    );
    return response['id'] as String;
  }

  @override
  Future<List<PatientTimelineItem>> getPatientTimeline({
    required AuthSession session,
    required String patientId,
  }) async {
    final response = await apiClient.getJsonList(
      '/patients/$patientId/timeline',
      token: session.accessToken,
    );
    return response
        .whereType<Map<String, dynamic>>()
        .map(_PatientTimelineItemMapper.fromJson)
        .toList(growable: false);
  }

  @override
  Future<Prescription?> getPrescription({
    required AuthSession session,
    required String consultationId,
  }) async {
    try {
      final response = await apiClient.getJson(
        '/consultations/$consultationId/prescription',
        token: session.accessToken,
      );
      return Prescription.fromJson(response);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> savePrescription({
    required AuthSession session,
    required String consultationId,
    required CreatePrescriptionPayload payload,
  }) async {
    await apiClient.postJson(
      '/consultations/$consultationId/prescription',
      payload.toJson(),
      token: session.accessToken,
    );
  }

  @override
  Future<void> submitLabResults({
    required AuthSession session,
    required String visitId,
    required CreateLabResultPayload payload,
  }) async {
    await apiClient.postJson(
      '/visits/$visitId/lab-results',
      payload.toJson(),
      token: session.accessToken,
    );
  }

  @override
  Future<List<Exam>> listActiveExams({
    required AuthSession session,
  }) async {
    final response = await apiClient.getJsonList(
      '/exams',
      token: session.accessToken,
    );
    return response
        .whereType<Map<String, dynamic>>()
        .map(Exam.fromJson)
        .toList(growable: false);
  }

  @override
  Future<InvoicePreview> getInvoicePreview({
    required AuthSession session,
    required String visitId,
  }) async {
    final response = await apiClient.getJson(
      '/visits/$visitId/invoice-preview',
      token: session.accessToken,
    );
    return InvoicePreview.fromJson(response);
  }
}

class CreatePatientPayload {
  const CreatePatientPayload({
    required this.firstName,
    required this.lastName,
    required this.sex,
    required this.declaredAge,
    required this.phone,
    required this.city,
    required this.emergencyContactPhone,
    required this.arrivalReason,
    required this.priority,
  });

  final String firstName;
  final String lastName;
  final String sex;
  final int declaredAge;
  final String phone;
  final String? city;
  final String? emergencyContactPhone;
  final String arrivalReason;
  final String priority;

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'sex': sex,
      'declaredAge': declaredAge,
      'phone': phone,
      'city': city,
      'emergencyContactPhone': emergencyContactPhone,
      'arrivalReason': arrivalReason,
      'priority': priority,
      'targetService': 'CONSULTATION',
    };
  }
}

class CreateVisitPayload {
  const CreateVisitPayload({
    required this.reason,
    required this.priority,
    required this.targetService,
  });

  final String reason;
  final String priority;
  final String targetService;

  Map<String, dynamic> toJson() {
    return {
      'reason': reason,
      'priority': priority,
      'targetService': targetService,
    };
  }
}

class CreateVitalsPayload {
  const CreateVitalsPayload({
    this.temperature,
    this.systolicPressure,
    this.diastolicPressure,
    this.pulse,
    this.respiratoryRate,
    this.oxygenSaturation,
    this.weight,
    this.height,
    this.bloodGlucose,
  });

  final double? temperature;
  final int? systolicPressure;
  final int? diastolicPressure;
  final int? pulse;
  final int? respiratoryRate;
  final int? oxygenSaturation;
  final double? weight;
  final double? height;
  final double? bloodGlucose;

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'systolicPressure': systolicPressure,
      'diastolicPressure': diastolicPressure,
      'pulse': pulse,
      'respiratoryRate': respiratoryRate,
      'oxygenSaturation': oxygenSaturation,
      'weight': weight,
      'height': height,
      'bloodGlucose': bloodGlucose,
    }..removeWhere((_, value) => value == null);
  }

  bool get hasMeasurement => toJson().isNotEmpty;
}

class CreateCashDeskPaymentPayload {
  const CreateCashDeskPaymentPayload({
    required this.amount,
    required this.mode,
    this.reference,
  });

  final double amount;
  final String mode;
  final String? reference;

  Map<String, dynamic> toJson() {
    return {'amount': amount, 'mode': mode, 'reference': reference?.trim()}
      ..removeWhere((_, value) => value == null || value == '');
  }
}

class CreateLabResultPayload {
  const CreateLabResultPayload({
    required this.examType,
    required this.results,
    this.observations,
    this.sampleDate,
    this.dossierNumber,
    this.isNormal = false,
  });

  final String examType;
  final String results;
  final String? observations;
  final DateTime? sampleDate;
  final String? dossierNumber;
  final bool isNormal;

  Map<String, dynamic> toJson() {
    return {
      'examType': examType,
      'results': results,
      'observations': observations?.trim(),
      'sampleDate': sampleDate == null ? null : _dateOnly(sampleDate!),
      'dossierNumber': dossierNumber?.trim(),
      'isNormal': isNormal,
    }..removeWhere((_, value) => value == null || value == '');
  }

  static String _dateOnly(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}

class _PatientSummaryMapper {
  const _PatientSummaryMapper._();

  static PatientSummary fromJson(Map<String, dynamic> json) {
    final latestVisit = json['latestVisit'];
    final visitJson = latestVisit is Map<String, dynamic> ? latestVisit : null;
    final sex = json['sex'] as String?;
    final age =
        json['declaredAge'] as int? ?? _ageFromBirthDate(json['birthDate']);

    return PatientSummary(
      id: json['id'] as String?,
      patientNumber: json['patientNumber'] as String?,
      latestVisitId: visitJson?['id'] as String?,
      fullName: _stringOrFallback(json['fullName'], 'Patient sans nom'),
      sexAge: _sexAge(sex, age),
      phoneNumber: _stringOrFallback(json['phone'], 'Téléphone non renseigné'),
      reason: _stringOrFallback(visitJson?['reason'], 'Aucun motif renseigné'),
      lastVisit: _visitDate(visitJson?['arrivalAt']),
      status: _status(visitJson?['status']),
      priority: _priority(visitJson?['priority']),
    );
  }

  static String _stringOrFallback(Object? value, String fallback) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  static String _sexAge(String? sex, int? age) {
    final sexLabel = switch (sex) {
      'FEMALE' => 'F',
      'MALE' => 'M',
      _ => null,
    };
    if (sexLabel == null && age == null) {
      return 'Profil incomplet';
    }
    if (age == null) {
      return sexLabel!;
    }
    if (sexLabel == null) {
      return '$age ans';
    }
    return '$sexLabel · $age ans';
  }

  static String _visitDate(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return 'Aucune visite';
    }

    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) {
      return 'Date visite inconnue';
    }

    final now = DateTime.now();
    final isToday =
        parsed.year == now.year &&
        parsed.month == now.month &&
        parsed.day == now.day;
    final time = '${_twoDigits(parsed.hour)}:${_twoDigits(parsed.minute)}';
    if (isToday) {
      return "Aujourd'hui · $time";
    }
    return '${_twoDigits(parsed.day)}/${_twoDigits(parsed.month)} · $time';
  }

  static int? _ageFromBirthDate(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    final birthDate = DateTime.tryParse(value);
    if (birthDate == null) {
      return null;
    }
    final today = DateTime.now();
    var age = today.year - birthDate.year;
    final birthdayPassed =
        today.month > birthDate.month ||
        (today.month == birthDate.month && today.day >= birthDate.day);
    if (!birthdayPassed) {
      age--;
    }
    return age < 0 ? null : age;
  }

  static PatientStatus _status(Object? value) {
    return switch (value) {
      'WAITING' => PatientStatus.waiting,
      'IN_CONSULTATION' => PatientStatus.inConsultation,
      'CASH_DESK' => PatientStatus.cashDesk,
      'LAB' => PatientStatus.lab,
      'RELEASED' => PatientStatus.released,
      _ => PatientStatus.waiting,
    };
  }

  static PatientPriority _priority(Object? value) {
    return switch (value) {
      'URGENT' => PatientPriority.urgent,
      'SURVEILLANCE' => PatientPriority.watch,
      _ => PatientPriority.normal,
    };
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _DashboardTodaySummaryMapper {
  const _DashboardTodaySummaryMapper._();

  static DashboardTodaySummary fromJson(Map<String, dynamic> json) {
    return DashboardTodaySummary(
      patientsToday: _int(json['patientsToday']),
      consultationsToday: _int(json['consultationsToday']),
      pendingExams: _int(json['pendingExams']),
      validatedResults: _int(json['validatedResults']),
      dailyRevenue: _double(json['dailyRevenue']),
      unpaidInvoices: _int(json['unpaidInvoices']),
    );
  }

  static int _int(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static double _double(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}

class _PatientTimelineItemMapper {
  const _PatientTimelineItemMapper._();

  static PatientTimelineItem fromJson(Map<String, dynamic> json) {
    final vitalsJson = json['vitals'];
    final consultationJson = json['consultation'];

    return PatientTimelineItem(
      visitId: json['visitId'] as String,
      reason: json['reason'] as String? ?? 'Aucun motif',
      targetService: json['targetService'] as String? ?? 'CONSULTATION',
      status: _status(json['status']),
      priority: _priority(json['priority']),
      arrivalAt: DateTime.parse(json['arrivalAt'] as String).toLocal(),
      closedAt: json['closedAt'] != null
          ? DateTime.parse(json['closedAt'] as String).toLocal()
          : null,
      vitals: vitalsJson is Map<String, dynamic>
          ? _VitalsSummaryMapper.fromJson(vitalsJson)
          : null,
      consultation: consultationJson is Map<String, dynamic>
          ? _consultation(consultationJson)
          : null,
    );
  }

  static PatientStatus _status(Object? value) {
    return switch (value) {
      'WAITING' => PatientStatus.waiting,
      'IN_CONSULTATION' => PatientStatus.inConsultation,
      'CASH_DESK' => PatientStatus.cashDesk,
      'LAB' => PatientStatus.lab,
      'RELEASED' => PatientStatus.released,
      _ => PatientStatus.waiting,
    };
  }

  static PatientPriority _priority(Object? value) {
    return switch (value) {
      'URGENT' => PatientPriority.urgent,
      'SURVEILLANCE' => PatientPriority.watch,
      _ => PatientPriority.normal,
    };
  }

  static PatientConsultationSummary _consultation(Map<String, dynamic> json) {
    return PatientConsultationSummary(
      id: json['id'] as String,
      symptoms: json['symptoms'] as String? ?? '',
      clinicalExam: json['clinicalExam'] as String? ?? '',
      diagnosis: json['diagnosis'] as String? ?? '',
      decision: ConsultationDecision.fromApiValue(json['decision']),
      advice: json['advice'] as String?,
      status: json['status'] as String? ?? 'DRAFT',
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }
}

class _VitalsSummaryMapper {
  const _VitalsSummaryMapper._();

  static VitalsSummary fromJson(Map<String, dynamic> json) {
    return VitalsSummary(
      id: _string(json['id']),
      visitId: _string(json['visitId']) ?? '',
      patientId: _string(json['patientId']),
      temperature: _double(json['temperature']),
      systolicPressure: _int(json['systolicPressure']),
      diastolicPressure: _int(json['diastolicPressure']),
      pulse: _int(json['pulse']),
      respiratoryRate: _int(json['respiratoryRate']),
      oxygenSaturation: _int(json['oxygenSaturation']),
      weight: _double(json['weight']),
      height: _double(json['height']),
      bmi: _double(json['bmi']),
      bloodGlucose: _double(json['bloodGlucose']),
      createdAt: _dateTime(json['createdAt']),
    );
  }

  static String? _string(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  static double? _double(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static int? _int(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static DateTime? _dateTime(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value)?.toLocal();
  }
}

extension on PatientStatus {
  String get apiValue {
    return switch (this) {
      PatientStatus.waiting => 'WAITING',
      PatientStatus.inConsultation => 'IN_CONSULTATION',
      PatientStatus.cashDesk => 'CASH_DESK',
      PatientStatus.lab => 'LAB',
      PatientStatus.released => 'RELEASED',
    };
  }
}
