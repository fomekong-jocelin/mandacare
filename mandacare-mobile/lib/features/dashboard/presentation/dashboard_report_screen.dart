import 'package:flutter/material.dart';
import '../../../app/api/api_exception.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/widgets/metric_strip.dart';
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
      final data = await widget.patientGateway.getDailyReport(
        session: widget.session,
      );
      if (!mounted) return;
      setState(() {
        _report = data;
        _loading = false;
      });
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() {
        _error = _reportErrorMessage(exception);
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

  String _reportErrorMessage(ApiException exception) {
    return switch (exception.statusCode) {
      401 => 'Session expirée. Reconnectez-vous pour afficher les rapports.',
      403 => "Votre profil n'a pas accès aux rapports de pilotage.",
      _ => exception.message,
    };
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
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _ReportStateView(
                      message: _error!,
                      onRetry: () => _loadReport(),
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MetricStrip(
            items: [
              MetricStripItem(
                value: report.totalPatientsToday.toString(),
                label: 'Patients du jour',
                color: AppColors.deepHealthBlue,
              ),
              MetricStripItem(
                value: '${report.totalRevenue.toStringAsFixed(0)} FCFA',
                label: 'Recettes totales',
                color: AppColors.medicalGreen,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ReportSection(
            title: 'Répartition des patients actifs',
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
          const SizedBox(height: 18),
          _ReportSection(
            title: 'Recettes par mode de paiement',
            child: report.revenueByPaymentMode.isEmpty
                ? const _ReportEmptyLine(
                    label: 'Aucune recette encaissée aujourd\'hui.',
                  )
                : Column(
                    children: report.revenueByPaymentMode.entries.map((entry) {
                      final mode = entry.key;
                      final amount = entry.value;
                      final pct = report.totalRevenue > 0
                          ? amount / report.totalRevenue
                          : 0.0;
                      final isLast =
                          entry.key == report.revenueByPaymentMode.keys.last;
                      return _PaymentModeRow(
                        mode: mode,
                        amount: amount,
                        percentage: pct,
                        addDivider: !isLast,
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 18),
          _ReportSection(
            title: 'Top 5 des examens prescrits',
            child: report.topPrescribedExams.isEmpty
                ? const _ReportEmptyLine(
                    label: 'Aucun examen prescrit aujourd\'hui.',
                  )
                : Column(
                    children: report.topPrescribedExams.entries.map((entry) {
                      final label = entry.key;
                      final count = entry.value;
                      final isLast =
                          entry.key == report.topPrescribedExams.keys.last;
                      return _ExamRow(
                        label: label,
                        count: count,
                        addDivider: !isLast,
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 13.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count patient${count > 1 ? "s" : ""}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.deepHealthBlue,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
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
          child: child,
        ),
      ],
    );
  }
}

class _PaymentModeRow extends StatelessWidget {
  const _PaymentModeRow({
    required this.mode,
    required this.amount,
    required this.percentage,
    required this.addDivider,
  });

  final String mode;
  final double amount;
  final double percentage;
  final bool addDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      mode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${amount.toStringAsFixed(0)} FCFA (${(percentage * 100).toStringAsFixed(0)}%)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.deepHealthBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 7,
                  backgroundColor: AppColors.lightBackground,
                  valueColor: const AlwaysStoppedAnimation(
                    AppColors.medicalGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (addDivider) const Divider(height: 14, thickness: 0.5),
      ],
    );
  }
}

class _ExamRow extends StatelessWidget {
  const _ExamRow({
    required this.label,
    required this.count,
    required this.addDivider,
  });

  final String label;
  final int count;
  final bool addDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.deepHealthBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.biotech_rounded,
                  color: AppColors.deepHealthBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  '$count prescription${count > 1 ? "s" : ""}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.deepHealthBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (addDivider) const Divider(height: 14, thickness: 0.5),
      ],
    );
  }
}

class _ReportEmptyLine extends StatelessWidget {
  const _ReportEmptyLine({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ReportStateView extends StatelessWidget {
  const _ReportStateView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: AppColors.error,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement impossible',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
