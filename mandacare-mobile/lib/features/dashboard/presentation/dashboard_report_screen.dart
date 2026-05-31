import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/widgets/page_header.dart';
import '../../auth/domain/auth_session.dart';
import '../../patients/data/patient_gateway.dart';
import '../../patients/domain/daily_report.dart';

class DashboardReportScreen extends StatefulWidget {
  const DashboardReportScreen({
    required this.session,
    required this.patientGateway,
    super.key,
  });

  final AuthSession session;
  final PatientGateway patientGateway;

  @override
  State<DashboardReportScreen> createState() => _DashboardReportScreenState();
}

class _DashboardReportScreenState extends State<DashboardReportScreen> {
  DailyReport? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.patientGateway.getDailyReport(session: widget.session);
      if (!mounted) return;
      setState(() {
        _report = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = "Impossible de charger les statistiques d'activité.";
        _loading = false;
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
            PageHeader(
              title: 'Rapports & Pilotage',
              subtitle: 'Pilotage, recettes et statistiques',
              trailing: IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadReport,
                tooltip: 'Rafraîchir',
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(AppColors.medicalGreen),
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.analytics_outlined, size: 54, color: AppColors.textSecondary),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadReport,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Réessayer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.medicalGreen,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildReportView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportView() {
    final report = _report!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: 'Patients du jour',
                  value: report.totalPatientsToday.toString(),
                  subtitle: 'Tous statuts confondus',
                  icon: Icons.people_outline_rounded,
                  color: AppColors.deepHealthBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  title: 'Recettes totales',
                  value: '${report.totalRevenue.toStringAsFixed(0)} FCFA',
                  subtitle: 'Paiements validés',
                  icon: Icons.monetization_on_outlined,
                  color: AppColors.medicalGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('Répartition des patients actifs'),
          const SizedBox(height: 8),
          _buildContainerCard(
            child: Column(
              children: [
                _buildStatusRow(
                  'En attente accueil / consultation',
                  report.patientsByStatus['waiting'] ?? 0,
                  AppColors.warning,
                ),
                const Divider(height: 16, thickness: 0.5),
                _buildStatusRow(
                  'En cours de consultation',
                  report.patientsByStatus['inConsultation'] ?? 0,
                  AppColors.info,
                ),
                const Divider(height: 16, thickness: 0.5),
                _buildStatusRow(
                  'En attente de paiement (Caisse)',
                  report.patientsByStatus['cashDesk'] ?? 0,
                  AppColors.medicalGreen,
                ),
                const Divider(height: 16, thickness: 0.5),
                _buildStatusRow(
                  'En attente examens (Labo)',
                  report.patientsByStatus['lab'] ?? 0,
                  AppColors.premiumGold,
                ),
                const Divider(height: 16, thickness: 0.5),
                _buildStatusRow(
                  'Sortis / Libérés',
                  report.patientsByStatus['released'] ?? 0,
                  AppColors.success,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('Recettes par mode de paiement'),
          const SizedBox(height: 8),
          _buildContainerCard(
            child: report.revenueByPaymentMode.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'Aucune recette encaissée aujourd\'hui.',
                        style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ),
                  )
                : Column(
                    children: report.revenueByPaymentMode.entries.map((entry) {
                      final mode = entry.key;
                      final amount = entry.value;
                      final double pct = report.totalRevenue > 0 ? amount / report.totalRevenue : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  mode,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${amount.toStringAsFixed(0)} FCFA (${(pct * 100).toStringAsFixed(0)}%)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.deepHealthBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 8,
                                backgroundColor: AppColors.lightBackground,
                                valueColor: const AlwaysStoppedAnimation(AppColors.medicalGreen),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('Top 5 des examens prescrits'),
          const SizedBox(height: 8),
          _buildContainerCard(
            child: report.topPrescribedExams.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'Aucun examen prescrit aujourd\'hui.',
                        style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ),
                  )
                : Column(
                    children: report.topPrescribedExams.entries.map((entry) {
                      final label = entry.key;
                      final count = entry.value;
                      final isLast = entry.key == report.topPrescribedExams.keys.last;
                      return Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.deepHealthBlue.withValues(alpha: 0.08),
                              child: const Icon(Icons.biotech_rounded, color: AppColors.deepHealthBlue),
                            ),
                            title: Text(
                              label,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.lightBackground,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
                              ),
                              child: Text(
                                '$count prescription${count > 1 ? "s" : ""}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.deepHealthBlue,
                                ),
                              ),
                            ),
                          ),
                          if (!isLast) const Divider(height: 12, thickness: 0.5),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainerCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.40)),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepHealthBlue.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.40)),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepHealthBlue.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: 22),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.deepHealthBlue,
            ),
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          CircleAvatar(radius: 5, backgroundColor: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 13.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count patient${count > 1 ? "s" : ""}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
