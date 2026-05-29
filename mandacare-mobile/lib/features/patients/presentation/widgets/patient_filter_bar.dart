import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../patient_filter.dart';

class PatientFilterBar extends StatelessWidget {
  const PatientFilterBar({
    required this.selectedFilter,
    required this.onChanged,
    super.key,
  });

  final PatientFilter selectedFilter;
  final ValueChanged<PatientFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: PatientFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = PatientFilter.values[index];
          final selected = selectedFilter == filter;
          return _FilterPill(
            label: filter.label,
            selected: selected,
            onTap: () => onChanged(filter),
          );
        },
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.textSecondary;
    final background = selected ? AppColors.deepHealthBlue : AppColors.card;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.deepHealthBlue
                  : AppColors.border.withValues(alpha: 0.45),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: foreground,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
