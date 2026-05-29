import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../patients/domain/vitals_summary.dart';

class LatestVitalsCard extends StatelessWidget {
  const LatestVitalsCard({
    required this.vitals,
    required this.isLoading,
    required this.errorMessage,
    super.key,
  });

  final VitalsSummary? vitals;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final currentVitals = vitals;

    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.medicalGreen.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.monitor_heart_rounded,
                  color: AppColors.medicalGreen,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Dernières constantes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (currentVitals?.createdAt != null)
                Text(
                  _timeLabel(currentVitals!.createdAt!),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (isLoading)
            const _VitalsMessage(
              icon: Icons.sync_rounded,
              text: 'Chargement des constantes',
            )
          else if (errorMessage != null)
            _VitalsMessage(
              icon: Icons.info_outline_rounded,
              text: errorMessage!,
              color: AppColors.warning,
            )
          else if (currentVitals == null)
            const _VitalsMessage(
              icon: Icons.monitor_heart_outlined,
              text: 'Aucune constante enregistrée pour cette visite.',
            )
          else
            _VitalsGrid(vitals: currentVitals),
        ],
      ),
    );
  }

  static String _timeLabel(DateTime value) {
    final localValue = value.toLocal();
    return '${_twoDigits(localValue.hour)}:${_twoDigits(localValue.minute)}';
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _VitalsGrid extends StatelessWidget {
  const _VitalsGrid({required this.vitals});

  final VitalsSummary vitals;

  @override
  Widget build(BuildContext context) {
    final items = [
      _VitalsMetric('Temp.', _decimal(vitals.temperature), '°C'),
      _VitalsMetric(
        'TA',
        '${_integer(vitals.systolicPressure)}/${_integer(vitals.diastolicPressure)}',
        'mmHg',
      ),
      _VitalsMetric('Pouls', _integer(vitals.pulse), '/min'),
      _VitalsMetric('SpO2', _integer(vitals.oxygenSaturation), '%'),
      _VitalsMetric('FR', _integer(vitals.respiratoryRate), '/min'),
      _VitalsMetric('Poids', _decimal(vitals.weight), 'kg'),
      _VitalsMetric('Taille', _decimal(vitals.height), 'cm'),
      _VitalsMetric('IMC', _decimal(vitals.bmi, fractionDigits: 2), ''),
      _VitalsMetric(
        'Glycémie',
        _decimal(vitals.bloodGlucose, fractionDigits: 2),
        '',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 360 ? 2 : 3;
        const spacing = 6.0;
        final itemWidth =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: _VitalsMetricTile(item: item),
              ),
          ],
        );
      },
    );
  }

  static String _integer(int? value) => value?.toString() ?? '--';

  static String _decimal(double? value, {int fractionDigits = 1}) {
    if (value == null) {
      return '--';
    }
    final formatted = value.toStringAsFixed(fractionDigits);
    return formatted.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

class _VitalsMetric {
  const _VitalsMetric(this.label, this.value, this.unit);

  final String label;
  final String value;
  final String unit;
}

class _VitalsMetricTile extends StatelessWidget {
  const _VitalsMetricTile({required this.item});

  final _VitalsMetric item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
              children: [
                TextSpan(text: item.value),
                if (item.unit.isNotEmpty)
                  TextSpan(
                    text: ' ${item.unit}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalsMessage extends StatelessWidget {
  const _VitalsMessage({
    required this.icon,
    required this.text,
    this.color = AppColors.textSecondary,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
