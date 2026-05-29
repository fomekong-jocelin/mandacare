import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    required this.actionLabel,
    this.onActionPressed,
    super.key,
  });

  final String title;
  final String actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.deepHealthBlue,
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            height: 1.12,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onActionPressed,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            foregroundColor: Theme.of(context).colorScheme.primary,
            textStyle: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}
