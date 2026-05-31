import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/widgets/page_header.dart';
import 'help_topic.dart';

class HelpTopicDetailScreen extends StatelessWidget {
  const HelpTopicDetailScreen({required this.topic, super.key});

  final HelpTopic topic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: topic.title,
              subtitle: 'Guide utilisateur MandaCare',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  _MockupPreviewCard(topic: topic),
                  const SizedBox(height: 18),
                  _SectionHeader(title: 'Comment l\'exploiter ?', icon: Icons.playlist_add_check_rounded),
                  const SizedBox(height: 10),
                  for (var i = 0; i < topic.steps.length; i++) ...[
                    _StepItem(index: i + 1, text: topic.steps[i]),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 20),
                  _SectionHeader(title: 'Règles de gestion & Validation', icon: Icons.gavel_rounded),
                  const SizedBox(height: 10),
                  _RulesCard(topic: topic),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockupPreviewCard extends StatelessWidget {
  const _MockupPreviewCard({required this.topic});

  final HelpTopic topic;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.deepHealthBlue.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(topic.icon, color: AppColors.deepHealthBlue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    topic.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.deepHealthBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            child: InteractiveViewer(
              maxScale: 3.0,
              child: Image.asset(
                topic.imageAssetPath,
                fit: BoxFit.contain,
                height: 380,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey.shade100,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_rounded, color: Colors.grey.shade400, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          'Aperçu indisponible',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.deepHealthBlue, size: 19),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.deepHealthBlue,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.medicalGreen,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            index.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.3,
                  fontSize: 14,
                ),
          ),
        ),
      ],
    );
  }
}

class _RulesCard extends StatelessWidget {
  const _RulesCard({required this.topic});

  final HelpTopic topic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final rule in topic.rules) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rule,
                    style: TextStyle(
                      color: AppColors.warning.withValues(alpha: 0.90),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            if (rule != topic.rules.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
