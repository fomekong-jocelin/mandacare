import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class MetricStrip extends StatelessWidget {
  const MetricStrip({required this.items, super.key});

  final List<MetricStripItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final item in items) ...[
          Expanded(child: _MetricTile(item: item)),
          if (item != items.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class MetricStripItem {
  const MetricStripItem({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.item});

  final MetricStripItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: item.color.withValues(alpha: 0.12)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: item.color,
                fontWeight: FontWeight.w700,
                height: 1.05,
              ),
            ),
            Text(
              item.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
