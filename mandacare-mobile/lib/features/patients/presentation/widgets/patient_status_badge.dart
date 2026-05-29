import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/patient_summary.dart';

class PatientStatusBadge extends StatelessWidget {
  const PatientStatusBadge({required this.status, super.key});

  final PatientStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      PatientStatus.waiting => AppColors.warning,
      PatientStatus.inConsultation => AppColors.success,
      PatientStatus.lab => AppColors.info,
      PatientStatus.released => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
