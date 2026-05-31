import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/widgets/page_header.dart';
import '../../auth/domain/auth_session.dart';
import '../data/clinic_gateway.dart';

class DatabaseMaintenanceScreen extends StatefulWidget {
  const DatabaseMaintenanceScreen({
    required this.session,
    required this.clinicGateway,
    super.key,
  });

  final AuthSession session;
  final ClinicGateway clinicGateway;

  @override
  State<DatabaseMaintenanceScreen> createState() => _DatabaseMaintenanceScreenState();
}

class _DatabaseMaintenanceScreenState extends State<DatabaseMaintenanceScreen> {
  final _confirmController = TextEditingController();
  bool _isConfirmEnabled = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(_onConfirmChanged);
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  void _onConfirmChanged() {
    final value = _confirmController.text.trim().toUpperCase();
    setState(() {
      _isConfirmEnabled = value == 'PURGER';
    });
  }

  Future<void> _executePurge() async {
    if (!_isConfirmEnabled || _loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.clinicGateway.purgeDatabase(session: widget.session);
      if (!mounted) return;
      
      setState(() {
        _loading = false;
      });

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.medicalGreen),
              const SizedBox(width: 8),
              Text(
                'Purge réussie',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.deepHealthBlue,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          content: const Text(
            'Toutes les données patients et de transactions ont été supprimées avec succès. Les stocks de la pharmacie ont été réinitialisés.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // pop dialog
                Navigator.of(context).pop(); // pop screen
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Une erreur est survenue lors de la purge : $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            const PageHeader(
              title: 'Base de données',
              subtitle: 'Maintenance et nettoyage des données',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: Color(0xFFD97706), size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  'ATTENTION : ACTION IRRÉVERSIBLE',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: const Color(0xFFD97706),
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Cette opération supprimera définitivement toutes les données textuelles et de transaction suivantes de la clinique :',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoItem('Dossiers patients complets'),
                            _buildInfoItem('Visites et fiches d\'examens prescrites'),
                            _buildInfoItem('Consultations, constantes et ordonnances'),
                            _buildInfoItem('Résultats de laboratoire et factures de la caisse'),
                            _buildInfoItem('Tickets de support technique créés'),
                            _buildInfoItem('Historique des mouvements de stock'),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            const Text(
                              'Seront conservés :',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            _buildKeepItem('Comptes utilisateurs de l\'équipe'),
                            _buildKeepItem('Grille tarifaire (examens et actes de soins)'),
                            _buildKeepItem('Configuration générale de la clinique'),
                            _buildKeepItem('Catalogue des médicaments de la pharmacie'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFB91C1C)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text(
                      'Pour confirmer la suppression complète, veuillez saisir le mot "PURGER" ci-dessous :',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _confirmController,
                      autocorrect: false,
                      enableSuggestions: false,
                      enabled: !_loading,
                      decoration: InputDecoration(
                        hintText: 'Saisir PURGER en majuscules',
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.deepHealthBlue, width: 2),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: (_isConfirmEnabled && !_loading) ? _executePurge : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[500],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Purger la base de données',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildKeepItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.medicalGreen, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
