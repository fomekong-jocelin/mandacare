import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandacare_mobile/features/auth/domain/auth_session.dart';
import 'package:mandacare_mobile/features/more/presentation/support_ticket_screen.dart';
import 'widget_test.dart'; // Pour importer FakePatientGateway

void main() {
  const session = AuthSession(
    accessToken: 'test-token',
    username: 'admin',
    displayName: 'Dr Manda',
    roleCode: 'ADMIN',
    roleLabel: 'Administrateur',
  );

  testWidgets('SupportTicketScreen displays tickets and opens dialog', (
    tester,
  ) async {
    final fakeGateway = FakePatientGateway();

    await tester.pumpWidget(
      MaterialApp(
        home: SupportTicketScreen(
          session: session,
          patientGateway: fakeGateway,
        ),
      ),
    );

    // Chargement
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    // Au début, c'est vide
    expect(find.text('Aucune demande d\'assistance créée.'), findsOneWidget);

    // Cliquer sur le bouton pour ouvrir le dialogue
    await tester.tap(find.text('Créer une demande'));
    await tester.pumpAndSettle();

    // Vérifier les champs du dialogue
    expect(find.text('Soumettre un ticket de support'), findsOneWidget);
    expect(find.text('Sujet / Titre de la demande'), findsOneWidget);
    expect(find.text('Description détaillée'), findsOneWidget);

    // Remplir et soumettre
    await tester.enterText(
      find.byKey(const ValueKey('support-subject-field')),
      'Bug validation caisse',
    );
    await tester.enterText(
      find.byKey(const ValueKey('support-description-field')),
      'Le bouton de validation ne répond pas.',
    );
    await tester.tap(find.text('Soumettre'));
    await tester.pumpAndSettle();

    // Vérifier que le ticket créé s'affiche dans la liste
    expect(find.text('Bug validation caisse'), findsOneWidget);
    expect(find.text('Le bouton de validation ne répond pas.'), findsOneWidget);
    expect(find.text('EN COURS'), findsOneWidget);
  });
}
