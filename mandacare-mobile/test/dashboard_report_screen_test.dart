import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandacare_mobile/features/auth/domain/auth_session.dart';
import 'package:mandacare_mobile/features/dashboard/presentation/dashboard_report_screen.dart';
import 'widget_test.dart'; // Pour importer FakePatientGateway

void main() {
  const session = AuthSession(
    accessToken: 'test-token',
    username: 'admin',
    displayName: 'Dr Manda',
    roleCode: 'ADMIN',
    roleLabel: 'Administrateur',
  );

  testWidgets('DashboardReportScreen displays stats and KPIs', (tester) async {
    final fakeGateway = FakePatientGateway();

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardReportScreen(
          session: session,
          patientGateway: fakeGateway,
        ),
      ),
    );

    // Chargement
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    // Vérifier les KPIs
    expect(find.text('Patients du jour'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('Recettes totales'), findsOneWidget);
    expect(find.text('70000 FCFA'), findsOneWidget);

    // Vérifier la répartition par statut
    expect(find.text('En cours de consultation'), findsOneWidget);
    expect(find.text('En attente examens (Labo)'), findsOneWidget);
    expect(find.text('3 patients'), findsNWidgets(2));

    // Vérifier les examens prescrits
    expect(find.text('Top 5 des examens prescrits'), findsOneWidget);
    expect(find.text('NFS'), findsOneWidget);
    expect(find.text('8 prescriptions'), findsOneWidget);
  });
}
