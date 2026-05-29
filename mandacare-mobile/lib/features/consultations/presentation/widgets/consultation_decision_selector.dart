import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/consultation_decision.dart';

class ConsultationDecisionSelector extends StatelessWidget {
  const ConsultationDecisionSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final ConsultationDecision value;
  final ValueChanged<ConsultationDecision> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DecisionOption(
          decision: ConsultationDecision.keepInConsultation,
          selected: value == ConsultationDecision.keepInConsultation,
          icon: Icons.medical_services_rounded,
          title: 'Continuer',
          subtitle: 'Garder le patient en consultation',
          onTap: onChanged,
        ),
        const SizedBox(height: 7),
        _DecisionOption(
          decision: ConsultationDecision.sendToLab,
          selected: value == ConsultationDecision.sendToLab,
          icon: Icons.science_rounded,
          title: 'Labo',
          subtitle: 'Envoyer vers les examens',
          onTap: onChanged,
        ),
        const SizedBox(height: 7),
        _DecisionOption(
          decision: ConsultationDecision.releasePatient,
          selected: value == ConsultationDecision.releasePatient,
          icon: Icons.logout_rounded,
          title: 'Sortie',
          subtitle: 'Clôturer la visite',
          onTap: onChanged,
        ),
      ],
    );
  }
}

class _DecisionOption extends StatelessWidget {
  const _DecisionOption({
    required this.decision,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final ConsultationDecision decision;
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final ValueChanged<ConsultationDecision> onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.medicalGreen : AppColors.textSecondary;
    return Material(
      color: selected
          ? AppColors.medicalGreen.withValues(alpha: 0.10)
          : AppColors.lightBackground,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => onTap(decision),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColors.medicalGreen
                  : AppColors.border.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 19),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
