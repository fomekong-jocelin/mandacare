import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandacare_mobile/features/auth/data/auth_gateway.dart';
import 'package:mandacare_mobile/features/auth/domain/auth_session.dart';
import 'package:mandacare_mobile/features/consultations/domain/consultation_decision.dart';
import 'package:mandacare_mobile/features/consultations/domain/create_consultation_payload.dart';
import 'package:mandacare_mobile/features/consultations/domain/prescription.dart';
import 'package:mandacare_mobile/features/patients/data/mock_patient_summaries.dart';
import 'package:mandacare_mobile/features/patients/data/patient_gateway.dart';
import 'package:mandacare_mobile/features/patients/domain/patient_summary.dart';
import 'package:mandacare_mobile/features/patients/domain/patient_timeline_item.dart';
import 'package:mandacare_mobile/features/patients/domain/vitals_summary.dart';
import 'package:mandacare_mobile/app/mandacare_app.dart';

void main() {
  const session = AuthSession(
    accessToken: 'test-token',
    username: 'admin',
    displayName: 'Dr Manda',
  );

  Widget appWithSession() {
    return MandaCareApp(
      initialSession: session,
      patientGateway: FakePatientGateway(),
    );
  }

  testWidgets('logs in before opening the app', (tester) async {
    await tester.pumpWidget(
      MandaCareApp(
        authGateway: FakeAuthGateway(session),
        patientGateway: FakePatientGateway(),
      ),
    );

    expect(find.text('Connexion'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('login-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Bonjour, Dr Manda'), findsOneWidget);
  });

  testWidgets('shows MandaCare dashboard', (tester) async {
    await tester.pumpWidget(appWithSession());

    expect(find.text('Bonjour, Dr Manda'), findsOneWidget);
    expect(find.text('Accès rapide'), findsOneWidget);
    expect(find.text("File d'attente"), findsOneWidget);
  });

  testWidgets('dashboard patient action opens creation form', (tester) async {
    await tester.pumpWidget(appWithSession());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Patient'));
    await tester.pumpAndSettle();

    expect(find.text('Nouveau patient'), findsOneWidget);
    expect(find.text('Enregistrer patient'), findsOneWidget);
  });

  testWidgets('dashboard opens waiting queue in patients tab', (tester) async {
    await tester.pumpWidget(appWithSession());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Voir tout'));
    await tester.pumpAndSettle();

    expect(find.text('Dossiers actifs et file du jour'), findsOneWidget);
    expect(find.text('Awa Diop'), findsOneWidget);
    expect(find.text('Cheikh Fall'), findsOneWidget);
    expect(find.text('Mamadou Sarr'), findsNothing);
  });

  testWidgets('created patient appears on dashboard without manual refresh', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final patientGateway = FakePatientGateway();
    await tester.pumpWidget(
      MandaCareApp(initialSession: session, patientGateway: patientGateway),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom-nav-patients')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ajouter un patient'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Nora Test');
    await tester.enterText(find.byType(TextFormField).at(1), '34');
    await tester.enterText(find.byType(TextFormField).at(2), '699000111');
    await tester.enterText(find.byType(TextFormField).last, 'Contrôle initial');
    await tester.tap(find.byKey(const ValueKey('save-patient-button')));
    await tester.pumpAndSettle();

    expect(find.text('Profil patient'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bottom-nav-home')));
    await tester.pumpAndSettle();

    expect(find.text('Nora Test'), findsOneWidget);
  });

  testWidgets(
    'dashboard queue opens patient detail without direct clinical actions',
    (tester) async {
      final patientGateway = FakePatientGateway();
      await tester.pumpWidget(
        MandaCareApp(initialSession: session, patientGateway: patientGateway),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey(
            'visit-status-menu-10000000-0000-0000-0000-000000000001',
          ),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('vitals-action-10000000-0000-0000-0000-000000000001'),
        ),
        findsNothing,
      );

      await tester.tap(find.text('Awa Diop').first);
      await tester.pumpAndSettle();

      expect(find.text('Profil patient'), findsOneWidget);
      expect(find.text('Actions patient'), findsOneWidget);
    },
  );

  testWidgets('opens and searches patients', (tester) async {
    await tester.pumpWidget(appWithSession());

    await tester.tap(find.byKey(const ValueKey('bottom-nav-patients')));
    await tester.pumpAndSettle();

    expect(find.text('Dossiers actifs et file du jour'), findsOneWidget);
    expect(find.text('Awa Diop'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Ibrahima');
    await tester.pump();

    expect(find.text('Ibrahima Diallo'), findsOneWidget);
    expect(find.text('Awa Diop'), findsNothing);
  });

  testWidgets('opens patient creation form', (tester) async {
    await tester.pumpWidget(appWithSession());

    await tester.tap(find.byKey(const ValueKey('bottom-nav-patients')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ajouter un patient'));
    await tester.pumpAndSettle();

    expect(find.text('Nouveau patient'), findsOneWidget);
    expect(find.text('Nom complet'), findsOneWidget);
    expect(find.text('Téléphone'), findsOneWidget);
    expect(find.text('Enregistrer patient'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('save-patient-button')));
    await tester.pump();

    expect(find.text('Champ requis'), findsWidgets);
  });

  testWidgets('opens patient detail screen', (tester) async {
    await tester.pumpWidget(appWithSession());

    await tester.tap(find.byKey(const ValueKey('bottom-nav-patients')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Awa Diop').first);
    await tester.pumpAndSettle();

    expect(find.text('Profil patient'), findsOneWidget);
    expect(find.text('Résumé clinique'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Historique'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Historique'), findsOneWidget);
    expect(find.text('Saisir les constantes'), findsOneWidget);
  });

  testWidgets('opens vitals form from patient detail', (tester) async {
    await tester.pumpWidget(appWithSession());

    await tester.tap(find.byKey(const ValueKey('bottom-nav-patients')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Awa Diop').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saisir les constantes'));
    await tester.pumpAndSettle();

    expect(find.text('Constantes'), findsWidgets);
    expect(find.text('Signes vitaux'), findsOneWidget);
    expect(find.byKey(const ValueKey('save-vitals-button')), findsOneWidget);
  });

  testWidgets('opens consultation cash desk and more screens', (tester) async {
    await tester.pumpWidget(appWithSession());

    await tester.tap(find.byKey(const ValueKey('bottom-nav-consultations')));
    await tester.pumpAndSettle();
    expect(find.text('Actes du jour et priorités'), findsOneWidget);
    expect(find.text('Consultation sélectionnée'), findsOneWidget);
    expect(find.text('Dernières constantes'), findsOneWidget);
    expect(find.text('TA'), findsOneWidget);
    expect(find.text('IMC'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-cashDesk')));
    await tester.pumpAndSettle();
    expect(find.text('Patients à encaisser'), findsOneWidget);
    expect(find.text('Aucun passage en caisse'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-more')));
    await tester.pumpAndSettle();
    expect(find.text('Modules, équipe et paramètres'), findsOneWidget);
    expect(find.text('Stock pharmacie'), findsOneWidget);
  });

  testWidgets('saves a consultation and applies the decision', (tester) async {
    final patientGateway = FakePatientGateway();
    const visitId = '10000000-0000-0000-0000-000000000002';

    await tester.pumpWidget(
      MandaCareApp(initialSession: session, patientGateway: patientGateway),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bottom-nav-consultations')));
    await tester.pumpAndSettle();

    expect(find.text('Consultation sélectionnée'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('open-consultation-form-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Observation clinique'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('consultation-symptoms-field')),
      'Céphalées depuis deux jours',
    );
    await tester.enterText(
      find.byKey(const ValueKey('consultation-clinical-exam-field')),
      'Patient conscient, stable',
    );
    await tester.drag(
      find.byKey(const ValueKey('consultation-form-scroll')),
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('consultation-diagnosis-field')),
      'Céphalées simples',
    );
    await tester.drag(
      find.byKey(const ValueKey('consultation-form-scroll')),
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sortie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sortie'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-consultation-button')));
    await tester.pumpAndSettle();

    expect(patientGateway.consultationSavedFor(visitId), isTrue);
    expect(patientGateway.statusFor(visitId), PatientStatus.cashDesk);
  });

  testWidgets('returns patient from cash desk to consultation for correction', (
    tester,
  ) async {
    final patientGateway = FakePatientGateway();
    const visitId = '10000000-0000-0000-0000-000000000002';

    await patientGateway.createVitals(
      session: session,
      visitId: visitId,
      payload: const CreateVitalsPayload(
        temperature: 37.4,
        systolicPressure: 130,
        diastolicPressure: 85,
        pulse: 82,
        weight: 78,
        height: 176,
      ),
    );
    await patientGateway.createConsultation(
      session: session,
      visitId: visitId,
      payload: const CreateConsultationPayload(
        symptoms: 'Fièvre persistante',
        clinicalExam: 'Patient fébrile',
        diagnosis: 'Bilan infectieux',
        advice: 'NFS',
        decision: ConsultationDecision.sendToLab,
        status: 'VALIDATED',
      ),
    );

    await tester.pumpWidget(
      MandaCareApp(initialSession: session, patientGateway: patientGateway),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom-nav-patients')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mamadou Sarr').first);
    await tester.pumpAndSettle();

    expect(find.text('Valider le passage en caisse'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('return-to-consultation-action')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('return-to-consultation-action')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Revenir à la consultation ?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Revenir'));
    await tester.pumpAndSettle();

    expect(patientGateway.statusFor(visitId), PatientStatus.inConsultation);
    expect(find.text('Rédiger la consultation'), findsOneWidget);
  });

  testWidgets('saves a consultation as draft without validating fields', (
    tester,
  ) async {
    final patientGateway = FakePatientGateway();
    const visitId = '10000000-0000-0000-0000-000000000002';

    await tester.pumpWidget(
      MandaCareApp(initialSession: session, patientGateway: patientGateway),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bottom-nav-consultations')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('open-consultation-form-button')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('consultation-symptoms-field')),
      'Fièvre persistante',
    );

    await tester.tap(find.byKey(const ValueKey('save-draft-button')));
    await tester.pumpAndSettle();

    expect(patientGateway.consultationSavedFor(visitId), isTrue);
    expect(patientGateway.statusFor(visitId), PatientStatus.inConsultation);
  });

  testWidgets('renders cash desk in compact landscape', (tester) async {
    tester.view.physicalSize = const Size(932, 430);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(appWithSession());
    await tester.tap(find.byKey(const ValueKey('bottom-nav-cashDesk')));
    await tester.pumpAndSettle();

    expect(find.text('Caisse'), findsWidgets);
    expect(find.text('Patients à encaisser'), findsOneWidget);
    expect(find.text('Aucun passage en caisse'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cash desk validates payment and routes patient to lab', (
    tester,
  ) async {
    final patientGateway = FakePatientGateway();
    const visitId = '10000000-0000-0000-0000-000000000002';

    await patientGateway.createConsultation(
      session: session,
      visitId: visitId,
      payload: const CreateConsultationPayload(
        symptoms: 'Fièvre persistante',
        clinicalExam: 'Patient fébrile',
        diagnosis: 'Bilan infectieux',
        advice: 'NFS et CRP',
        decision: ConsultationDecision.sendToLab,
        status: 'VALIDATED',
      ),
    );

    await tester.pumpWidget(
      MandaCareApp(initialSession: session, patientGateway: patientGateway),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom-nav-cashDesk')));
    await tester.pumpAndSettle();

    expect(find.text('Mamadou Sarr'), findsOneWidget);
    expect(find.textContaining('vers labo'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('cashdesk-complete-$visitId')));
    await tester.pumpAndSettle();
    expect(find.text('Encaisser et orienter'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('cashdesk-payment-amount')),
      '22000',
    );
    await tester.tap(find.byKey(const ValueKey('cashdesk-payment-submit')));
    await tester.pumpAndSettle();

    expect(patientGateway.statusFor(visitId), PatientStatus.lab);
    expect(find.text('Mamadou Sarr'), findsNothing);
  });
}

class FakeAuthGateway implements AuthGateway {
  const FakeAuthGateway(this.session);

  final AuthSession session;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    return session;
  }
}

class FakePatientGateway implements PatientGateway {
  final List<PatientSummary> _patients = [...mockPatientSummaries];
  final Map<String, PatientStatus> _visitStatuses = {};
  final Map<String, ConsultationDecision> _consultationDecisions = {};
  final Map<String, CreateVitalsPayload> _vitalsByVisit = {};
  final Set<String> _consultationVisits = {};
  final Set<String> _vitalsVisits = {};

  @override
  Future<List<PatientSummary>> listPatients({
    required AuthSession session,
    String? search,
  }) async {
    return _patients.map(_withCurrentStatus).toList(growable: false);
  }

  @override
  Future<List<PatientSummary>> listTodayQueue({
    required AuthSession session,
  }) async {
    return _patients
        .map(_withCurrentStatus)
        .where((patient) => patient.status != PatientStatus.released)
        .toList(growable: false);
  }

  @override
  Future<PatientSummary> createPatient({
    required AuthSession session,
    required CreatePatientPayload payload,
  }) async {
    final index = _patients.length + 1;
    final visitId = 'created-visit-$index';
    final patient = PatientSummary(
      id: 'created-patient-$index',
      patientNumber: 'MC-${index.toString().padLeft(4, '0')}',
      latestVisitId: visitId,
      fullName: '${payload.firstName} ${payload.lastName}',
      sexAge: payload.sex == 'FEMALE'
          ? 'F · ${payload.declaredAge} ans'
          : 'M · ${payload.declaredAge} ans',
      phoneNumber: payload.phone,
      reason: payload.arrivalReason,
      lastVisit: "Aujourd'hui · 10:30",
      status: PatientStatus.waiting,
      priority: switch (payload.priority) {
        'URGENT' => PatientPriority.urgent,
        'SURVEILLANCE' => PatientPriority.watch,
        _ => PatientPriority.normal,
      },
    );
    _patients.add(patient);
    _visitStatuses[visitId] = PatientStatus.waiting;
    return patient;
  }

  @override
  Future<void> createVisit({
    required AuthSession session,
    required String patientId,
    required CreateVisitPayload payload,
  }) async {}

  @override
  Future<void> changeVisitStatus({
    required AuthSession session,
    required String visitId,
    required PatientStatus status,
  }) async {
    _visitStatuses[visitId] = status;
  }

  @override
  Future<PatientSummary> completeCashDesk({
    required AuthSession session,
    required String visitId,
    required CreateCashDeskPaymentPayload payload,
  }) async {
    _paymentsByVisit[visitId] = payload;
    _visitStatuses[visitId] =
        _consultationDecisions[visitId] == ConsultationDecision.sendToLab
        ? PatientStatus.lab
        : PatientStatus.released;
    final patient = _patients.firstWhere((p) => p.latestVisitId == visitId);
    return _withCurrentStatus(patient);
  }

  @override
  Future<void> createVitals({
    required AuthSession session,
    required String visitId,
    required CreateVitalsPayload payload,
  }) async {
    _vitalsByVisit[visitId] = payload;
    _vitalsVisits.add(visitId);
    _visitStatuses[visitId] = PatientStatus.inConsultation;
  }

  @override
  Future<VitalsSummary> getLatestVitals({
    required AuthSession session,
    required String visitId,
  }) async {
    final payload = _vitalsByVisit[visitId];
    if (payload == null) {
      return VitalsSummary(
        visitId: visitId,
        temperature: 37.2,
        systolicPressure: 138,
        diastolicPressure: 86,
        pulse: 78,
        respiratoryRate: 18,
        oxygenSaturation: 97,
        weight: 82,
        height: 178,
        bmi: 25.88,
        bloodGlucose: 0.95,
        createdAt: DateTime(2026, 5, 29, 9, 15),
      );
    }

    return VitalsSummary(
      visitId: visitId,
      temperature: payload.temperature,
      systolicPressure: payload.systolicPressure,
      diastolicPressure: payload.diastolicPressure,
      pulse: payload.pulse,
      respiratoryRate: payload.respiratoryRate,
      oxygenSaturation: payload.oxygenSaturation,
      weight: payload.weight,
      height: payload.height,
      bmi: _bmi(payload),
      bloodGlucose: payload.bloodGlucose,
      createdAt: DateTime(2026, 5, 29, 9, 15),
    );
  }

  @override
  Future<String> createConsultation({
    required AuthSession session,
    required String visitId,
    required CreateConsultationPayload payload,
  }) async {
    _consultationVisits.add(visitId);
    _consultationDecisions[visitId] = payload.decision;
    if (payload.status == 'DRAFT') {
      _visitStatuses[visitId] = PatientStatus.inConsultation;
    } else {
      _visitStatuses[visitId] = switch (payload.decision) {
        ConsultationDecision.keepInConsultation => PatientStatus.inConsultation,
        ConsultationDecision.sendToLab => PatientStatus.cashDesk,
        ConsultationDecision.releasePatient => PatientStatus.cashDesk,
      };
    }
    return 'consult-$visitId';
  }

  @override
  Future<List<PatientTimelineItem>> getPatientTimeline({
    required AuthSession session,
    required String patientId,
  }) async {
    final patient = _patients.firstWhere((p) => p.id == patientId);
    final visitId = patient.latestVisitId;
    if (visitId == null) {
      return [];
    }

    final status = _visitStatuses[visitId] ?? patient.status;
    final hasVitals = _vitalsVisits.contains(visitId);
    final hasConsultation = _consultationVisits.contains(visitId);

    return [
      PatientTimelineItem(
        visitId: visitId,
        reason: patient.reason,
        targetService: 'Médecine Générale',
        status: status,
        priority: patient.priority,
        arrivalAt: DateTime.now().subtract(const Duration(hours: 2)),
        vitals: hasVitals
            ? await getLatestVitals(session: session, visitId: visitId)
            : null,
        consultation: hasConsultation
            ? PatientConsultationSummary(
                id: 'consult-$visitId',
                symptoms: 'Fièvre, toux',
                clinicalExam: 'Examen pulmonaire normal',
                diagnosis: 'Syndrome grippal',
                decision:
                    _consultationDecisions[visitId] ??
                    ConsultationDecision.keepInConsultation,
                status: 'VALIDATED',
                createdAt: DateTime.now().subtract(const Duration(hours: 1)),
              )
            : null,
      ),
    ];
  }

  final Map<String, CreatePrescriptionPayload> _prescriptionsByConsultation =
      {};
  final Map<String, CreateCashDeskPaymentPayload> _paymentsByVisit = {};

  @override
  Future<Prescription?> getPrescription({
    required AuthSession session,
    required String consultationId,
  }) async {
    final payload = _prescriptionsByConsultation[consultationId];
    if (payload == null) {
      return null;
    }
    return Prescription(
      id: 'presc-$consultationId',
      patientId: 'patient-id',
      consultationId: consultationId,
      prescriptionNumber: 'ORD-20260529-123456',
      status: payload.status,
      createdAt: DateTime.now(),
      items: payload.items.asMap().entries.map((entry) {
        final idx = entry.key;
        final item = entry.value;
        return PrescriptionItem(
          id: 'item-$idx',
          drugName: item.drugName,
          form: item.form,
          dosage: item.dosage,
          frequency: item.frequency,
          duration: item.duration,
          quantity: item.quantity,
          instructions: item.instructions,
        );
      }).toList(),
    );
  }

  @override
  Future<void> savePrescription({
    required AuthSession session,
    required String consultationId,
    required CreatePrescriptionPayload payload,
  }) async {
    _prescriptionsByConsultation[consultationId] = payload;
  }

  @override
  Future<void> submitLabResults({
    required AuthSession session,
    required String visitId,
    required CreateLabResultPayload payload,
  }) async {
    _labResultsByVisit[visitId] = payload;
    _visitStatuses[visitId] = PatientStatus.released;
  }

  PatientStatus? statusFor(String visitId) => _visitStatuses[visitId];

  bool vitalsSavedFor(String visitId) => _vitalsVisits.contains(visitId);

  bool consultationSavedFor(String visitId) {
    return _consultationVisits.contains(visitId);
  }

  final Map<String, CreateLabResultPayload> _labResultsByVisit = {};

  double? _bmi(CreateVitalsPayload payload) {
    final weight = payload.weight;
    final height = payload.height;
    if (weight == null || height == null || height == 0) {
      return null;
    }
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  PatientSummary _withCurrentStatus(PatientSummary patient) {
    final visitId = patient.latestVisitId;
    final status = visitId == null ? null : _visitStatuses[visitId];
    if (status == null) {
      return patient;
    }
    return PatientSummary(
      id: patient.id,
      patientNumber: patient.patientNumber,
      latestVisitId: patient.latestVisitId,
      fullName: patient.fullName,
      sexAge: patient.sexAge,
      phoneNumber: patient.phoneNumber,
      reason: patient.reason,
      lastVisit: patient.lastVisit,
      status: status,
      priority: patient.priority,
    );
  }
}
