import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../patients/domain/patient_summary.dart';
import 'status_chip.dart';

class QueuePanel extends StatelessWidget {
  const QueuePanel({
    required this.patients,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onPatientTap,
    super.key,
  });

  final List<PatientSummary> patients;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<PatientSummary> onPatientTap;

  @override
  Widget build(BuildContext context) {
    final content = _content(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.40)),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepHealthBlue.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: content,
    );
  }

  Widget _content(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return _QueueMessage(
        icon: Icons.cloud_off_rounded,
        title: 'File indisponible',
        message: error!,
        action: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Réessayer'),
        ),
      );
    }

    if (patients.isEmpty) {
      return const _QueueMessage(
        icon: Icons.event_available_rounded,
        title: 'Aucun patient en attente',
        message: "Les visites créées aujourd'hui apparaîtront ici.",
      );
    }

    final visiblePatients = patients.take(8).toList(growable: false);
    return Column(
      children: [
        for (final entry in visiblePatients.indexed) ...[
          _QueueLine(patient: entry.$2, onPatientTap: onPatientTap),
          if (entry.$1 < visiblePatients.length - 1) const _SoftDivider(),
        ],
      ],
    );
  }
}

class _QueueLine extends StatelessWidget {
  const _QueueLine({required this.patient, required this.onPatientTap});

  final PatientSummary patient;
  final ValueChanged<PatientSummary> onPatientTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onPatientTap(patient),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: AppColors.lightBackground,
              child: Text(
                patient.initials,
                style: const TextStyle(
                  color: AppColors.deepHealthBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14.5,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      StatusChip(
                        label: patient.status.label,
                        color: _statusColor(patient.status),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${patient.reason} • ${patient.lastVisit}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(PatientStatus status) {
    return switch (status) {
      PatientStatus.waiting => AppColors.warning,
      PatientStatus.inConsultation => AppColors.success,
      PatientStatus.cashDesk => AppColors.premiumGold,
      PatientStatus.lab => AppColors.info,
      PatientStatus.released => AppColors.textSecondary,
    };
  }
}

class _QueueMessage extends StatelessWidget {
  const _QueueMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: Column(
        children: [
          Icon(icon, color: AppColors.medicalGreen, size: 30),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (action != null) ...[const SizedBox(height: 8), action!],
        ],
      ),
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 64),
      color: const Color(0xFFEAF0EE),
    );
  }
}
