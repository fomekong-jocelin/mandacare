import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandacare_mobile/features/auth/data/auth_gateway.dart';
import 'package:mandacare_mobile/features/auth/domain/auth_session.dart';
import 'package:mandacare_mobile/features/consultations/domain/consultation_decision.dart';
import 'package:mandacare_mobile/features/patients/domain/pharmacy_item.dart';
import 'package:mandacare_mobile/features/patients/domain/daily_report.dart';
import 'package:mandacare_mobile/features/patients/domain/support_ticket.dart';
import 'package:mandacare_mobile/features/consultations/domain/create_consultation_payload.dart';
import 'package:mandacare_mobile/features/consultations/domain/prescription.dart';
import 'package:mandacare_mobile/features/dashboard/domain/dashboard_today_summary.dart';
import 'package:mandacare_mobile/features/patients/data/mock_patient_summaries.dart';
import 'package:mandacare_mobile/features/patients/data/patient_gateway.dart';
import 'package:mandacare_mobile/features/patients/domain/patient_summary.dart';
import 'package:mandacare_mobile/features/patients/domain/patient_timeline_item.dart';
import 'package:mandacare_mobile/features/patients/domain/vitals_summary.dart';
import 'package:mandacare_mobile/features/consultations/domain/exam.dart';
import 'package:mandacare_mobile/features/cashdesk/domain/invoice_preview.dart';
import 'package:mandacare_mobile/features/cashdesk/domain/invoice.dart';
import 'package:mandacare_mobile/features/users/data/user_gateway.dart';
import 'package:mandacare_mobile/features/users/domain/team_user.dart';
import 'package:mandacare_mobile/features/users/domain/user_payload.dart';
import 'package:mandacare_mobile/features/users/domain/user_role.dart';
import 'package:mandacare_mobile/app/mandacare_app.dart';
import 'package:mandacare_mobile/features/more/data/clinic_gateway.dart';

void main() {
  const session = AuthSession(
    accessToken: 'test-token',
    username: 'admin',
    displayName: 'Dr Manda',
    roleCode: 'ADMIN',
    roleLabel: 'Administrateur',
  );

  Widget appWithSession({ClinicGateway? clinicGateway}) {
    return MandaCareApp(
      initialSession: session,
      patientGateway: FakePatientGateway(),
      userGateway: FakeUserGateway(),
      clinicGateway: clinicGateway ?? const FakeClinicGateway(),
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

  testWidgets('dashboard handles very long username without issues', (tester) async {
    final longSession = const AuthSession(
      accessToken: 'test-token',
      username: 'admin',
      displayName: 'Dr. Jean-Pierre de la Tour-du-Pin-Chambly de La Charce-Montmorency',
      roleCode: 'ADMIN',
      roleLabel: 'Administrateur Principal de la Clinique MandaCare',
    );
    await tester.pumpWidget(MandaCareApp(
      initialSession: longSession,
      patientGateway: FakePatientGateway(),
      userGateway: FakeUserGateway(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Bonjour, Dr. Jean-Pierre de la Tour-du-Pin-Chambly de La Charce-Montmorency'), findsOneWidget);
    expect(find.text('Administrateur Principal de la Clinique MandaCare'), findsOneWidget);
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

  testWidgets('dashboard status cards open the right work queues', (
    tester,
  ) async {
    await tester.pumpWidget(appWithSession());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('dashboard-status-card-lab')));
    await tester.pumpAndSettle();

    expect(find.text('Dossiers actifs et file du jour'), findsOneWidget);
    expect(find.text('Ibrahima Diallo'), findsOneWidget);
    expect(find.text('Awa Diop'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-home')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('dashboard-status-card-cash-desk')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vue opérationnelle'), findsOneWidget);
    expect(find.text('Dossiers à encaisser'), findsOneWidget);
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
    expect(
      find.text('Encaissement des dossiers orientés par consultation'),
      findsOneWidget,
    );
    expect(find.text('Aucun passage en caisse'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-more')));
    await tester.pumpAndSettle();
    expect(find.text('Compte, rôle et modules'), findsOneWidget);
    expect(find.text('Dr Manda'), findsWidgets);
    expect(find.text('Administrateur'), findsWidgets);
    expect(find.text('Stock pharmacie'), findsOneWidget);
    expect(find.text('Utilisateurs, rôles et accès'), findsOneWidget);

    await tester.tap(find.text('Équipe'));
    await tester.pumpAndSettle();
    expect(find.text('Utilisateurs, profils et accès'), findsOneWidget);
    expect(find.text('Awa Ndiaye'), findsOneWidget);
    expect(find.text('Caissier · @paul.caisse'), findsOneWidget);
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

    expect(find.textContaining('Valider le passage en caisse'), findsOneWidget);
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
    expect(
      find.text('Encaissement des dossiers orientés par consultation'),
      findsOneWidget,
    );
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

    expect(patientGateway.lastQueueStatus, PatientStatus.cashDesk);
    expect(patientGateway.lastQueueLimit, 20);
    expect(find.text('Mamadou Sarr'), findsOneWidget);
    expect(find.textContaining('vers labo'), findsWidgets);
    expect(find.text('Encaisser'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cashdesk-complete-$visitId')));
    await tester.pumpAndSettle();
    expect(find.text('Encaisser et orienter'), findsOneWidget);
    expect(find.text('15000'), findsNothing);
    expect(find.text('Espèces'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('cashdesk-payment-amount')),
      '22000',
    );
    await tester.tap(find.byKey(const ValueKey('cashdesk-payment-submit')));
    await tester.pumpAndSettle();

    expect(patientGateway.statusFor(visitId), PatientStatus.lab);
    expect(find.text('Mamadou Sarr'), findsNothing);
  });

  testWidgets('lab results form returns patient to consultation', (
    tester,
  ) async {
    final patientGateway = FakePatientGateway();
    const visitId = '10000000-0000-0000-0000-000000000002';

    await patientGateway.createVitals(
      session: session,
      visitId: visitId,
      payload: const CreateVitalsPayload(
        temperature: 38.1,
        systolicPressure: 132,
        diastolicPressure: 86,
        pulse: 84,
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
        advice: 'NFS et CRP',
        decision: ConsultationDecision.sendToLab,
        status: 'VALIDATED',
      ),
    );
    await patientGateway.completeCashDesk(
      session: session,
      visitId: visitId,
      payload: const CreateCashDeskPaymentPayload(amount: 15000, mode: 'CASH'),
    );

    await tester.pumpWidget(
      MandaCareApp(initialSession: session, patientGateway: patientGateway),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom-nav-patients')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mamadou Sarr').first);
    await tester.pumpAndSettle();

    expect(find.text('Saisir les résultats labo'), findsOneWidget);
    await tester.tap(find.text('Saisir les résultats labo'));
    await tester.pumpAndSettle();

    expect(find.text('Résultat de laboratoire'), findsOneWidget);
    final labResultsFinder = find.byKey(const ValueKey('lab-results-field'));
    await tester.scrollUntilVisible(labResultsFinder, 80.0);
    await tester.pumpAndSettle();
    await tester.enterText(labResultsFinder, 'GB 7200/mm3, Hb 13 g/dL');
    await tester.tap(find.byKey(const ValueKey('submit-lab-results-button')));
    await tester.pumpAndSettle();

    expect(patientGateway.statusFor(visitId), PatientStatus.inConsultation);
  });

  testWidgets('modifying constants loads existing vitals values', (
    tester,
  ) async {
    final patientGateway = FakePatientGateway();
    const visitId = '10000000-0000-0000-0000-000000000001'; // Awa Diop
    await patientGateway.createVitals(
      session: session,
      visitId: visitId,
      payload: const CreateVitalsPayload(
        temperature: 37.9,
        systolicPressure: 125,
        diastolicPressure: 78,
        pulse: 72,
        weight: 65,
        height: 165,
      ),
    );

    await tester.pumpWidget(
      MandaCareApp(initialSession: session, patientGateway: patientGateway),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom-nav-patients')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Awa Diop').first);
    await tester.pumpAndSettle();

    expect(find.text('Modifier les constantes'), findsOneWidget);
    await tester.tap(find.text('Modifier les constantes'));
    await tester.pumpAndSettle();

    // Verify fields are pre-populated
    final tempFinder = find.descendant(
      of: find.byKey(const ValueKey('vitals-temperature-field')),
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(tempFinder).controller?.text, '37.9');

    final sysFinder = find.descendant(
      of: find.byKey(const ValueKey('vitals-systolic-field')),
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(sysFinder).controller?.text, '125');

    final weightFinder = find.descendant(
      of: find.byKey(const ValueKey('vitals-weight-field')),
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(weightFinder).controller?.text, '65.0');
  });

  testWidgets(
    'modifying consultation restores selected exams list from invoice',
    (tester) async {
      final patientGateway = FakePatientGateway();
      const visitId = '10000000-0000-0000-0000-000000000002'; // Mamadou Sarr

      await patientGateway.createVitals(
        session: session,
        visitId: visitId,
        payload: const CreateVitalsPayload(
          temperature: 37.2,
          systolicPressure: 120,
          diastolicPressure: 80,
        ),
      );

      await patientGateway.createConsultation(
        session: session,
        visitId: visitId,
        payload: const CreateConsultationPayload(
          symptoms: 'Maux de tête',
          clinicalExam: 'Normal',
          diagnosis: 'Migraine',
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

      final modifierConsultFinder = find.text('Modifier la consultation');
      await tester.scrollUntilVisible(
        modifierConsultFinder,
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();

      expect(modifierConsultFinder, findsOneWidget);
      await tester.tap(modifierConsultFinder);
      await tester.pumpAndSettle();

      final examTileFinder = find.byKey(const ValueKey('exam-tile-NFS'));
      await tester.scrollUntilVisible(
        examTileFinder,
        100,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('consultation-form-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();

      // The mock active exams list has 'NFS'. Since our mock invoice has EXAM 'NFS',
      // it should be automatically checked!
      expect(find.text('NFS'), findsWidgets);
      final checkboxTile = tester.widget<CheckboxListTile>(examTileFinder);
      expect(checkboxTile.value, isTrue);
    },
  );

  testWidgets('admin can navigate to database maintenance and purge database', (tester) async {
    await tester.pumpWidget(appWithSession());
    await tester.pumpAndSettle();

    // 1. Switch to "more" tab
    await tester.tap(find.byKey(const ValueKey('bottom-nav-more')));
    await tester.pumpAndSettle();

    // 2. Verify "Maintenance base" is present by scrolling to it
    final tileFinder = find.text('Maintenance base');
    await tester.scrollUntilVisible(
      tileFinder,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(tileFinder);
    await tester.pumpAndSettle();

    // 3. Verify screen title and caution list
    expect(find.text('ATTENTION : ACTION IRRÉVERSIBLE'), findsOneWidget);
    expect(find.text('Dossiers patients complets'), findsOneWidget);

    // 4. Verify button is disabled initially
    final buttonFinder = find.widgetWithText(ElevatedButton, 'Purger la base de données');
    expect(tester.widget<ElevatedButton>(buttonFinder).onPressed, isNull);

    // 5. Enter wrong confirm word
    await tester.enterText(find.byType(TextField), 'WRONG_CONFIRM');
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(buttonFinder).onPressed, isNull);

    // 6. Enter correct confirm word "PURGER"
    await tester.enterText(find.byType(TextField), 'PURGER');
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(buttonFinder).onPressed, isNotNull);

    // 7. Execute purge
    await tester.scrollUntilVisible(
      buttonFinder,
      50,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(buttonFinder);
    await tester.pump(); // Start execution
    await tester.pumpAndSettle(const Duration(milliseconds: 700)); // wait for FakeClinicGateway delay

    // 8. Verify success dialog
    expect(find.text('Purge réussie'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // 9. Verify we are back on more tab
    expect(find.text('Compte, rôle et modules'), findsOneWidget);
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
    PatientStatus? status,
    int limit = 8,
  }) async {
    lastQueueStatus = status;
    lastQueueLimit = limit;
    return _patients
        .map(_withCurrentStatus)
        .where((patient) => patient.status != PatientStatus.released)
        .where((patient) => status == null || patient.status == status)
        .take(limit)
        .toList(growable: false);
  }

  PatientStatus? lastQueueStatus;
  int? lastQueueLimit;

  @override
  Future<DashboardTodaySummary> getTodayDashboard({
    required AuthSession session,
  }) async {
    final patients = _patients.map(_withCurrentStatus).toList(growable: false);
    final todayPatients = patients
        .where((patient) => patient.lastVisit.startsWith("Aujourd'hui"))
        .toList(growable: false);
    final dailyRevenue = _paymentsByVisit.values.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );

    return DashboardTodaySummary(
      patientsToday: todayPatients.length,
      activeQueue: todayPatients
          .where((patient) => patient.status != PatientStatus.released)
          .length,
      waitingQueue: todayPatients
          .where((patient) => patient.status == PatientStatus.waiting)
          .length,
      consultationQueue: todayPatients
          .where((patient) => patient.status == PatientStatus.inConsultation)
          .length,
      cashDeskQueue: todayPatients
          .where((patient) => patient.status == PatientStatus.cashDesk)
          .length,
      labQueue: todayPatients
          .where((patient) => patient.status == PatientStatus.lab)
          .length,
      consultationsToday: todayPatients
          .where((patient) => patient.status != PatientStatus.waiting)
          .length,
      pendingExams: todayPatients
          .where((patient) => patient.status == PatientStatus.lab)
          .length,
      validatedResults: _labResultsByVisit.length,
      dailyRevenue: dailyRevenue,
      unpaidInvoices: todayPatients
          .where((patient) => patient.status == PatientStatus.cashDesk)
          .length,
    );
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
    _visitStatuses[visitId] = PatientStatus.inConsultation;
  }

  @override
  Future<List<Exam>> listActiveExams({required AuthSession session}) async {
    return const [
      Exam(
        id: '30000000-0000-0000-0000-000000000007',
        code: 'NFS',
        name: 'NFS',
        category: 'HEMATOLOGIE',
        price: 4000.0,
        active: true,
      ),
    ];
  }

  @override
  Future<InvoicePreview> getInvoicePreview({
    required AuthSession session,
    required String visitId,
  }) async {
    return const InvoicePreview(
      totalAmount: 9000.0,
      discount: 0.0,
      netAmount: 9000.0,
      items: [
        InvoiceLine(
          type: 'BENEFIT',
          label: 'Consultation médicale',
          price: 5000.0,
          quantity: 1,
        ),
        InvoiceLine(type: 'EXAM', label: 'NFS', price: 4000.0, quantity: 1),
      ],
    );
  }

  @override
  Future<List<Invoice>> getInvoices({
    required AuthSession session,
    required String visitId,
  }) async {
    return [
      Invoice(
        id: 'invoice-123',
        invoiceNumber: 'FAC-TEST',
        totalAmount: 9000.0,
        discount: 0.0,
        netAmount: 9000.0,
        paidAmount: 9000.0,
        remainingAmount: 0.0,
        status: 'PAID',
        createdAt: DateTime.now(),
        items: const [
          InvoiceLine(
            type: 'BENEFIT',
            label: 'Consultation médicale',
            price: 5000.0,
            quantity: 1,
          ),
          InvoiceLine(type: 'EXAM', label: 'NFS', price: 4000.0, quantity: 1),
        ],
      ),
    ];
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

  // Stock Pharmacie (Simulation)
  final List<PharmacyItem> _pharmacyItems = [
    const PharmacyItem(
      id: '1',
      code: 'PARACET500',
      label: 'Paracétamol',
      dosage: '500mg',
      price: 500.00,
      stockQuantity: 50,
      alertThreshold: 10,
      critical: false,
    ),
    const PharmacyItem(
      id: '2',
      code: 'AMOXICILLIN',
      label: 'Amoxicilline',
      dosage: '1g',
      price: 1500.00,
      stockQuantity: 3,
      alertThreshold: 5,
      critical: true,
    ),
    const PharmacyItem(
      id: '3',
      code: 'IBUPROFEN',
      label: 'Ibuprofène',
      dosage: '400mg',
      price: 800.00,
      stockQuantity: 20,
      alertThreshold: 5,
      critical: false,
    ),
  ];

  @override
  Future<List<PharmacyItem>> getPharmacyItems({
    required AuthSession session,
  }) async {
    return _pharmacyItems;
  }

  @override
  Future<PharmacyItem> adjustPharmacyStock({
    required AuthSession session,
    required String id,
    required int quantity,
    required String reason,
  }) async {
    final idx = _pharmacyItems.indexWhere((item) => item.id == id);
    if (idx != -1) {
      final old = _pharmacyItems[idx];
      final newQty = old.stockQuantity + quantity;
      final updated = PharmacyItem(
        id: old.id,
        code: old.code,
        label: old.label,
        dosage: old.dosage,
        price: old.price,
        stockQuantity: newQty < 0 ? 0 : newQty,
        alertThreshold: old.alertThreshold,
        critical: (newQty < 0 ? 0 : newQty) <= old.alertThreshold,
      );
      _pharmacyItems[idx] = updated;
      return updated;
    }
    throw Exception("Not found");
  }

  @override
  Future<PharmacyItem> createPharmacyItem({
    required AuthSession session,
    required String code,
    required String label,
    required String? dosage,
    required double price,
    required int alertThreshold,
  }) async {
    final newItem = PharmacyItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      code: code,
      label: label,
      dosage: dosage,
      price: price,
      stockQuantity: 0,
      alertThreshold: alertThreshold,
      critical: true,
    );
    _pharmacyItems.add(newItem);
    return newItem;
  }

  @override
  Future<PharmacyItem> updatePharmacyItem({
    required AuthSession session,
    required String id,
    required String code,
    required String label,
    required String? dosage,
    required double price,
    required int alertThreshold,
  }) async {
    final idx = _pharmacyItems.indexWhere((item) => item.id == id);
    if (idx != -1) {
      final old = _pharmacyItems[idx];
      final updated = PharmacyItem(
        id: old.id,
        code: code,
        label: label,
        dosage: dosage,
        price: price,
        stockQuantity: old.stockQuantity,
        alertThreshold: alertThreshold,
        critical: old.stockQuantity <= alertThreshold,
      );
      _pharmacyItems[idx] = updated;
      return updated;
    }
    throw Exception("Not found");
  }

  // Rapports & Pilotage (Simulation)
  @override
  Future<DailyReport> getDailyReport({required AuthSession session}) async {
    return const DailyReport(
      totalPatientsToday: 15,
      patientsByStatus: {
        'waiting': 5,
        'inConsultation': 3,
        'cashDesk': 2,
        'lab': 3,
        'released': 2,
      },
      revenueByPaymentMode: {'Espèces': 45000.0, 'Mobile Money': 25000.0},
      totalRevenue: 70000.0,
      topPrescribedExams: {'NFS': 8, 'Biochimie': 5, 'Parasitologie': 3},
    );
  }

  // Support & Assistance (Simulation)
  final List<SupportTicket> _supportTickets = [];

  @override
  Future<List<SupportTicket>> getMySupportTickets({
    required AuthSession session,
  }) async {
    return _supportTickets;
  }

  @override
  Future<SupportTicket> createSupportTicket({
    required AuthSession session,
    required String subject,
    required String description,
    required String category,
    required String priority,
  }) async {
    final ticket = SupportTicket(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      subject: subject,
      description: description,
      category: category,
      priority: priority,
      status: 'OPEN',
      createdAt: DateTime.now(),
      userId: 'test-user-id',
    );
    _supportTickets.add(ticket);
    return ticket;
  }
}

class FakeUserGateway implements UserGateway {
  final List<UserRole> _roles = const [
    UserRole(
      code: 'ADMIN',
      label: 'Administrateur',
      description: 'Accès complet',
    ),
    UserRole(code: 'MEDECIN', label: 'Médecin'),
    UserRole(code: 'INFIRMIER', label: 'Infirmier'),
    UserRole(code: 'CAISSIER', label: 'Caissier'),
    UserRole(code: 'LABORATOIRE', label: 'Laboratoire'),
    UserRole(code: 'ACCUEIL', label: 'Accueil'),
    UserRole(code: 'AUTRE', label: 'Autre profil'),
  ];

  final List<TeamUser> _users = const [
    TeamUser(
      id: 'user-admin',
      username: 'admin',
      displayName: 'Dr Manda',
      firstName: 'Dr',
      lastName: 'Manda',
      status: 'ACTIVE',
      role: UserRole(code: 'ADMIN', label: 'Administrateur'),
    ),
    TeamUser(
      id: 'user-doctor',
      username: 'awa.ndiaye',
      displayName: 'Awa Ndiaye',
      firstName: 'Awa',
      lastName: 'Ndiaye',
      phone: '690000001',
      status: 'ACTIVE',
      role: UserRole(code: 'MEDECIN', label: 'Médecin'),
    ),
    TeamUser(
      id: 'user-cashier',
      username: 'paul.caisse',
      displayName: 'Paul Caisse',
      firstName: 'Paul',
      lastName: 'Caisse',
      status: 'INACTIVE',
      role: UserRole(code: 'CAISSIER', label: 'Caissier'),
    ),
  ];

  @override
  Future<List<UserRole>> listRoles({required AuthSession session}) async {
    return _roles;
  }

  @override
  Future<List<TeamUser>> listUsers({required AuthSession session}) async {
    return _users;
  }

  @override
  Future<TeamUser> createUser({
    required AuthSession session,
    required CreateTeamUserPayload payload,
  }) async {
    final role = _roles.firstWhere((role) => role.code == payload.roleCode);
    return TeamUser(
      id: 'created-user',
      username: payload.username,
      displayName: '${payload.firstName} ${payload.lastName}',
      firstName: payload.firstName,
      lastName: payload.lastName,
      phone: payload.phone,
      email: payload.email,
      status: 'ACTIVE',
      role: role,
    );
  }

  @override
  Future<TeamUser> updateUser({
    required AuthSession session,
    required String id,
    required UpdateTeamUserPayload payload,
  }) async {
    final role = _roles.firstWhere((role) => role.code == payload.roleCode);
    return TeamUser(
      id: id,
      username: payload.username,
      displayName: '${payload.firstName} ${payload.lastName}',
      firstName: payload.firstName,
      lastName: payload.lastName,
      phone: payload.phone,
      email: payload.email,
      status: payload.status,
      role: role,
    );
  }
}
