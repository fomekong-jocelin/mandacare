import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/presentation/widgets/metric_strip.dart';
import '../../domain/patient_summary.dart';

class PatientStatsStrip extends StatelessWidget {
  const PatientStatsStrip({required this.patients, super.key});

  final List<PatientSummary> patients;

  @override
  Widget build(BuildContext context) {
    final todayCount = patients
        .where((patient) => patient.lastVisit.startsWith("Aujourd'hui"))
        .length;
    final urgentCount = patients
        .where((patient) => patient.priority == PatientPriority.urgent)
        .length;

    return MetricStrip(
      items: [
        MetricStripItem(
          value: patients.length.toString(),
          label: 'patients',
          color: AppColors.deepHealthBlue,
        ),
        MetricStripItem(
          value: todayCount.toString(),
          label: "aujourd'hui",
          color: AppColors.medicalGreen,
        ),
        MetricStripItem(
          value: urgentCount.toString(),
          label: 'urgents',
          color: AppColors.warning,
        ),
      ],
    );
  }
}
