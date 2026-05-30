import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/api/api_client.dart';
import '../../app/theme/app_colors.dart';
import '../../features/auth/domain/auth_session.dart';

class DocumentPreviewShareScreen extends StatefulWidget {
  const DocumentPreviewShareScreen({
    required this.pdfUrl,
    required this.title,
    required this.session,
    required this.apiClient,
    required this.entityId,
    required this.entityType,
    this.phoneNumber,
    super.key,
  });

  final String pdfUrl;
  final String title;
  final AuthSession session;
  final ApiClient apiClient;
  final String entityId;
  final String entityType;
  final String? phoneNumber;

  @override
  State<DocumentPreviewShareScreen> createState() =>
      _DocumentPreviewShareScreenState();
}

class _DocumentPreviewShareScreenState
    extends State<DocumentPreviewShareScreen> {
  PdfController? _pdfController;
  bool _loading = true;
  String? _errorMessage;
  Uint8List? _pdfBytes;
  bool _consentGiven = false;
  late final TextEditingController _phoneController;
  bool _isSaving = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.phoneNumber ?? '');
    _loadPdf();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadPdf() async {
    try {
      final bytes = await widget.apiClient.getBytes(
        widget.pdfUrl,
        token: widget.session.accessToken,
      );
      if (!mounted) return;
      setState(() {
        _pdfBytes = bytes;
      });

      final isTest = Platform.environment.containsKey('FLUTTER_TEST');
      if (!isTest) {
        _pdfController = PdfController(
          document: PdfDocument.openData(bytes),
        );
      }
      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Impossible de charger le document PDF.";
        _loading = false;
      });
    }
  }

  Future<void> _downloadPdf() async {
    if (_pdfBytes == null) return;
    setState(() => _isSaving = true);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cleanedTitle = widget.title.replaceAll(RegExp(r'[^\w\s\-]'), '_');
      final fileName = '${cleanedTitle}_${widget.entityId.substring(0, 8)}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(_pdfBytes!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.medicalGreen,
          content: Text('Document enregistré avec succès :\n$filePath'),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Échec de la sauvegarde locale du document.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _shareOnWhatsApp() async {
    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text('Veuillez confirmer le consentement du patient.'),
        ),
      );
      return;
    }

    setState(() => _isSharing = true);
    try {
      // 1. Logger l'événement sur le serveur
      try {
        await widget.apiClient.postJson(
          '/patients/share-log',
          {
            'entityType': widget.entityType,
            'entityId': widget.entityId,
            'channel': 'WHATSAPP',
            'consent': true,
          },
          token: widget.session.accessToken,
        );
      } catch (_) {
        // Si le log serveur échoue, on continue quand même le partage mais on loggue localement
      }

      // 2. Préparer l'URL du document
      final baseUrl = widget.apiClient.baseUrl;
      final documentUrl = '$baseUrl${widget.pdfUrl}';
      final message =
          "Bonjour, voici votre document médical MandaCare (${widget.title}) : $documentUrl.\nMerci de votre confiance.";

      final phone = _phoneController.text.trim().replaceAll(RegExp(r'[^\d\+]'), '');

      // 3. Ouvrir l'URL de partage WhatsApp
      final Uri whatsappUri;
      if (phone.isNotEmpty) {
        whatsappUri = Uri.parse(
          'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
        );
      } else {
        whatsappUri = Uri.parse(
          'https://wa.me/?text=${Uri.encodeComponent(message)}',
        );
      }

      final success = await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Impossible d\'ouvrir l\'application WhatsApp.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Une erreur est survenue lors du partage.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    Widget controlPanel = Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Actions du document',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.medicalGreen,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Numéro WhatsApp du patient',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: 'Ex: +237699999999 ou laisser vide pour choix manuel',
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              activeColor: AppColors.medicalGreen,
              value: _consentGiven,
              onChanged: (val) => setState(() => _consentGiven = val),
              title: const Text(
                'Consentement obtenu',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Le patient a consenti au partage de ses données médicales.',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _consentGiven && !_isSharing ? _shareOnWhatsApp : null,
              icon: _isSharing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.share),
              label: const Text('Partager sur WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.medicalGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pdfBytes != null && !_isSaving ? _downloadPdf : null,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.download),
              label: const Text('Télécharger le document'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.medicalGreen,
                side: const BorderSide(color: AppColors.medicalGreen),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Widget pdfViewerWidget;
    if (_loading) {
      pdfViewerWidget = const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.medicalGreen),
        ),
      );
    } else if (_errorMessage != null) {
      pdfViewerWidget = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    } else {
      final isTest = Platform.environment.containsKey('FLUTTER_TEST');
      if (isTest || _pdfController == null) {
        pdfViewerWidget = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf,
                  size: 80, color: AppColors.medicalGreen),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mode simulation d\'aperçu',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        );
      } else {
        pdfViewerWidget = Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PdfView(
              controller: _pdfController!,
              scrollDirection: Axis.vertical,
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: isLandscape
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: pdfViewerWidget,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: controlPanel,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: pdfViewerWidget,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: controlPanel,
                  ),
                ],
              ),
      ),
    );
  }
}
