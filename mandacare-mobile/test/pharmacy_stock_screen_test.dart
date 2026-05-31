import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandacare_mobile/features/auth/domain/auth_session.dart';
import 'package:mandacare_mobile/features/pharmacy/presentation/pharmacy_stock_screen.dart';
import 'widget_test.dart'; // Pour importer FakePatientGateway

void main() {
  const session = AuthSession(
    accessToken: 'test-token',
    username: 'admin',
    displayName: 'Dr Manda',
    roleCode: 'ADMIN',
    roleLabel: 'Administrateur',
  );

  testWidgets('PharmacyStockScreen loads and displays items and dialogs', (tester) async {
    final fakeGateway = FakePatientGateway();

    await tester.pumpWidget(
      MaterialApp(
        home: PharmacyStockScreen(
          session: session,
          patientGateway: fakeGateway,
        ),
      ),
    );

    // Chargement
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    // Vérifier que les médicaments s'affichent
    expect(find.text('Paracétamol'), findsOneWidget);
    expect(find.text('Amoxicilline'), findsOneWidget);
    expect(find.text('Ibuprofène'), findsOneWidget);
    expect(find.text('Stock critique !'), findsOneWidget); // Pour l'Amoxicilline

    // Tester la recherche
    await tester.enterText(find.byType(TextField), 'Paracétamol');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Paracétamol'), findsOneWidget);
    expect(find.text('Amoxicilline'), findsNothing);

    // Annuler la recherche
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();

    // Ouvrir le dialogue d'ajustement du stock
    await tester.tap(find.widgetWithText(ListTile, 'Paracétamol'));
    await tester.pumpAndSettle();

    expect(find.text('Ajuster Stock - Paracétamol'), findsOneWidget);
    expect(find.text('Stock actuel : 50 unités'), findsOneWidget);

    // Fermer le dialogue
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
  });
}
