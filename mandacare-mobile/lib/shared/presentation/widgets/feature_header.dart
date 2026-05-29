import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../layout/adaptive_layout.dart';

class FeatureHeader extends StatelessWidget {
  const FeatureHeader({
    required this.title,
    required this.subtitle,
    required this.actionIcon,
    required this.actionTooltip,
    required this.onActionPressed,
    this.bottom,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData actionIcon;
  final String actionTooltip;
  final VoidCallback onActionPressed;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final compact = AdaptiveLayout.useSideNavigation(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.lightBackground.withValues(alpha: 0.98),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepHealthBlue.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          compact ? 8 : 12,
          16,
          compact ? 8 : 14,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.deepHealthBlue,
                              fontSize: compact ? 20 : 21,
                              fontWeight: FontWeight.w700,
                              height: 1.05,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12.5,
                          height: 1.12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filled(
                  onPressed: onActionPressed,
                  tooltip: actionTooltip,
                  style: IconButton.styleFrom(
                    fixedSize: compact
                        ? const Size(40, 40)
                        : const Size(42, 42),
                    backgroundColor: AppColors.medicalGreen,
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(actionIcon),
                ),
              ],
            ),
            if (bottom != null) ...[
              SizedBox(height: compact ? 10 : 14),
              bottom!,
            ],
          ],
        ),
      ),
    );
  }
}
