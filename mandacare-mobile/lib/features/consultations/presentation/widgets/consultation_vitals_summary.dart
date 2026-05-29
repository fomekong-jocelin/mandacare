import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../patients/domain/vitals_summary.dart';

class ConsultationVitalsSummary extends StatelessWidget {
  const ConsultationVitalsSummary({required this.vitals, super.key});

  final VitalsSummary? vitals;

  @override
  Widget build(BuildContext context) {
    final currentVitals = vitals;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepHealthBlue.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.monitor_heart_rounded,
                color: AppColors.medicalGreen,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Constantes de la visite',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (currentVitals?.createdAt != null)
                Text(
                  _timeLabel(currentVitals!.createdAt!),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (currentVitals == null)
            Text(
              'Non disponibles',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _VitalsPill(
                  label: 'TA',
                  value:
                      '${_int(currentVitals.systolicPressure)}/${_int(currentVitals.diastolicPressure)}',
                ),
                _VitalsPill(
                  label: 'T',
                  value: '${_decimal(currentVitals.temperature)} °C',
                ),
                _VitalsPill(
                  label: 'Pouls',
                  value: '${_int(currentVitals.pulse)} /min',
                ),
                _VitalsPill(
                  label: 'SpO2',
                  value: '${_int(currentVitals.oxygenSaturation)} %',
                ),
                _VitalsPill(
                  label: 'IMC',
                  value: _decimal(currentVitals.bmi, fractionDigits: 2),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static String _int(int? value) => value?.toString() ?? '--';

  static String _decimal(double? value, {int fractionDigits = 1}) {
    if (value == null) {
      return '--';
    }
    final formatted = value.toStringAsFixed(fractionDigits);
    return formatted.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static String _timeLabel(DateTime value) {
    final localValue = value.toLocal();
    return '${_twoDigits(localValue.hour)}:${_twoDigits(localValue.minute)}';
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _VitalsPill extends StatelessWidget {
  const _VitalsPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ({Color bg, Color text, IconData icon}) style = switch (label) {
      'TA' => (
        bg: const Color(0xFFF0F9FF),
        text: const Color(0xFF0284C7),
        icon: Icons.monitor_heart_rounded,
      ),
      'T' => (
        bg: const Color(0xFFFEF3C7),
        text: const Color(0xFFD97706),
        icon: Icons.thermostat_rounded,
      ),
      'Pouls' => (
        bg: const Color(0xFFFFF1F2),
        text: const Color(0xFFE11D48),
        icon: Icons.favorite_rounded,
      ),
      'SpO2' => (
        bg: const Color(0xFFECFDF5),
        text: const Color(0xFF059669),
        icon: Icons.air_rounded,
      ),
      'IMC' => (
        bg: const Color(0xFFF5F3FF),
        text: const Color(0xFF7C3AED),
        icon: Icons.scale_rounded,
      ),
      _ => (
        bg: AppColors.lightBackground,
        text: AppColors.textPrimary,
        icon: Icons.info_outline_rounded,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: style.text.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, color: style.text, size: 14),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: style.text.withValues(alpha: 0.8),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: style.text,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
