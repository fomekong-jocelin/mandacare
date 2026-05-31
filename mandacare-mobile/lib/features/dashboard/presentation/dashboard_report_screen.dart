import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
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
      appBar: AppBar(
        title: const Text('Rapports & Pilotage'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReport,
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: _loading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.medicalGreen)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.analytics_outlined, size: 54, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadReport, child: const Text('Réessayer')),
                    ],
                  ),
                )
              : _buildReportView(),
    );
  }

  Widget _buildReportView() {
    final report = _report!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row des KPIs principaux
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: 'Patients du jour',
                  value: report.totalPatientsToday.toString(),
                  subtitle: 'Tous statuts confondus',
                  icon: Icons.people_outline,
                  color: AppColors.deepHealthBlue,
                ),
              ),
              const SizedBox(width: 16),
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

          // File d'attente / Statuts
          _buildSectionHeader('Répartition des patients actifs'),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildStatusRow('En attente accueil / consultation', report.patientsByStatus['waiting'] ?? 0, Colors.orange),
                  const Divider(),
                  _buildStatusRow('En cours de consultation', report.patientsByStatus['inConsultation'] ?? 0, Colors.blue),
                  const Divider(),
                  _buildStatusRow('En attente de paiement (Caisse)', report.patientsByStatus['cashDesk'] ?? 0, Colors.teal),
                  const Divider(),
                  _buildStatusRow('En attente examens (Labo)', report.patientsByStatus['lab'] ?? 0, Colors.purple),
                  const Divider(),
                  _buildStatusRow('Sortis / Libérés', report.patientsByStatus['released'] ?? 0, Colors.green),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Répartition Financière
          _buildSectionHeader('Recettes par mode de paiement'),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: report.revenueByPaymentMode.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Aucune recette encaissée aujourd\'hui.')))
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
                                  Text(mode, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('${amount.toStringAsFixed(0)} FCFA (${(pct * 100).toStringAsFixed(0)}%)'),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: const AlwaysStoppedAnimation(AppColors.medicalGreen),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Top Examens
          _buildSectionHeader('Top 5 des examens prescrits'),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: report.topPrescribedExams.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Aucun examen prescrit aujourd\'hui.')))
                  : Column(
                      children: report.topPrescribedExams.entries.map((entry) {
                        final label = entry.key;
                        final count = entry.value;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.deepHealthBlue.withValues(alpha: 0.1),
                            child: const Icon(Icons.biotech_outlined, color: AppColors.deepHealthBlue),
                          ),
                          title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$count prescription${count > 1 ? "s" : ""}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
                Icon(icon, color: color, size: 24),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.deepHealthBlue,
          ),
    );
  }

  Widget _buildStatusRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          CircleAvatar(radius: 6, backgroundColor: color),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count patient${count > 1 ? "s" : ""}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
