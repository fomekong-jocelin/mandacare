import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandacare_mobile/app/api/api_client.dart';
import 'package:mandacare_mobile/features/auth/domain/auth_session.dart';
import 'package:mandacare_mobile/shared/presentation/document_preview_share_screen.dart';

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(baseUrl: 'http://localhost');

  @override
  Future<Uint8List> getBytes(
    String path, {
    Map<String, String>? query,
    String? token,
  }) async {
    // Retourne un faux contenu de fichier PDF pour le test
    return Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 52]); // %PDF-1.4
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    return <String, dynamic>{};
  }
}

void main() {
  const session = AuthSession(
    accessToken: 'test-token',
    username: 'admin',
    displayName: 'Dr Manda',
    roleCode: 'ADMIN',
    roleLabel: 'Administrateur',
  );

  testWidgets('DocumentPreviewShareScreen displays title and controls correctly',
      (tester) async {
    final fakeApiClient = FakeApiClient();

    await tester.pumpWidget(
      MaterialApp(
        home: DocumentPreviewShareScreen(
          pdfUrl: '/visits/123/invoice/pdf',
          title: 'Facture Test',
          session: session,
          apiClient: fakeApiClient,
          entityId: '123',
          entityType: 'INVOICE',
          phoneNumber: '+237699999999',
        ),
      ),
    );

    // Au début, on a un indicateur de chargement
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Attendre que le chargement se termine
    await tester.pumpAndSettle();

    // Vérifier le titre et les éléments affichés
    expect(find.text('Facture Test'), findsWidgets);
    expect(find.text('Mode simulation d\'aperçu'), findsOneWidget);
    expect(find.text('Actions du document'), findsOneWidget);

    // Vérifier que le numéro WhatsApp pré-rempli est bien présent
    final phoneField = find.byType(TextField);
    expect(phoneField, findsOneWidget);
    final TextField textField = tester.widget<TextField>(phoneField);
    expect(textField.controller?.text, '+237699999999');

    // Vérifier que le bouton de partage WhatsApp est désactivé par défaut
    final shareButtonFinder = find.widgetWithText(ElevatedButton, 'Partager sur WhatsApp');
    expect(shareButtonFinder, findsOneWidget);
    ElevatedButton shareButton = tester.widget<ElevatedButton>(shareButtonFinder);
    expect(shareButton.onPressed, isNull); // Désactivé

    // Activer le commutateur de consentement
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Vérifier que le bouton de partage est désormais activé
    shareButton = tester.widget<ElevatedButton>(shareButtonFinder);
    expect(shareButton.onPressed, isNotNull); // Activé
  });
}
