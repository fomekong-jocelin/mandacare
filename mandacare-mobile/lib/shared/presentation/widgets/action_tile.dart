import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class ActionTile extends StatelessWidget {
  const ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 260;
        final content = narrow
            ? _CompactActionContent(tile: this)
            : _WideActionContent(tile: this);
        return Material(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(narrow ? 11 : 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepHealthBlue.withValues(alpha: 0.035),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: content,
            ),
          ),
        );
      },
    );
  }
}

class _WideActionContent extends StatelessWidget {
  const _WideActionContent({required this.tile});

  final ActionTile tile;

  @override
  Widget build(BuildContext context) {
    final trailing =
        tile.trailing ??
        (tile.onTap == null ? null : const Icon(Icons.chevron_right_rounded));

    return Row(
      children: [
        _ActionIcon(icon: tile.icon),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionText(title: tile.title, subtitle: tile.subtitle),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing],
      ],
    );
  }
}

class _CompactActionContent extends StatelessWidget {
  const _CompactActionContent({required this.tile});

  final ActionTile tile;

  @override
  Widget build(BuildContext context) {
    final trailing =
        tile.trailing ??
        (tile.onTap == null ? null : const Icon(Icons.chevron_right_rounded));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _ActionIcon(icon: tile.icon),
            const Spacer(),
            ?trailing,
          ],
        ),
        const Spacer(),
        _ActionText(title: tile.title, subtitle: tile.subtitle),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.medicalGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColors.medicalGreen, size: 20),
    );
  }
}

class _ActionText extends StatelessWidget {
  const _ActionText({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.fade,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.18),
        ),
      ],
    );
  }
}
