part of 'activity_history_widgets.dart';

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({
    required this.accent,
    required this.label,
    required this.value,
    required this.meta,
    required this.chips,
  });

  final Color accent;
  final String label;
  final String value;
  final String meta;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepHealthBlue.withValues(alpha: 0.025),
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
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ),
              for (final chip in chips) ...[
                const SizedBox(width: 6),
                _HeroChip(label: chip, color: accent),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.deepHealthBlue,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            meta,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items, required this.accent});

  final List<_MetricInfo> items;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - ((items.length - 1) * 8)) / items.length;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              SizedBox(
                width: width.clamp(104, constraints.maxWidth),
                child: _MetricPill(item: item, accent: accent),
              ),
          ],
        );
      },
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.item, required this.accent});

  final _MetricInfo item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 62),
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSectionCard extends StatelessWidget {
  const _DetailSectionCard({required this.section, required this.accent});

  final _DetailSection section;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(section.icon, color: accent, size: 16),
              const SizedBox(width: 8),
              Text(
                section.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.deepHealthBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final row in section.rows) _DetailField(row: row),
        ],
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.row});

  final _DetailRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              row.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              row.value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                height: 1.18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection {
  const _DetailSection(this.title, this.icon, this.rows);

  final String title;
  final IconData icon;
  final List<_DetailRow> rows;
}

class _DocumentSection extends StatelessWidget {
  const _DocumentSection({required this.documents, required this.accent});

  final List<_ActivityDocument> documents;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file_rounded, color: accent, size: 16),
              const SizedBox(width: 8),
              Text(
                'Documents',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.deepHealthBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final document in documents)
            _DocumentRow(document: document, accent: accent),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatefulWidget {
  const _DocumentRow({required this.document, required this.accent});

  final _ActivityDocument document;
  final Color accent;

  @override
  State<_DocumentRow> createState() => _DocumentRowState();
}

class _DocumentRowState extends State<_DocumentRow> {
  bool _downloading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.document.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.document.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Visualiser',
            onPressed: _openPreview,
            icon: const Icon(Icons.visibility_outlined, size: 20),
            color: widget.accent,
          ),
          IconButton(
            tooltip: 'Télécharger',
            onPressed: _downloading ? null : _download,
            icon: _downloading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined, size: 20),
            color: widget.accent,
          ),
        ],
      ),
    );
  }

  void _openPreview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentPreviewShareScreen(
          pdfUrl: widget.document.pdfUrl,
          title: widget.document.title,
          session: widget.document.session,
          apiClient: widget.document.apiClient,
          entityId: widget.document.entityId,
          entityType: widget.document.entityType,
        ),
      ),
    );
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final bytes = await widget.document.apiClient.getBytes(
        widget.document.pdfUrl,
        token: widget.document.session.accessToken,
      );
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${widget.document.fileName}');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document enregistré : ${file.path}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Téléchargement impossible.')),
      );
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }
}

class _ActivityDocument {
  const _ActivityDocument({
    required this.title,
    required this.subtitle,
    required this.pdfUrl,
    required this.entityId,
    required this.entityType,
    required this.session,
    required this.apiClient,
  });

  final String title;
  final String subtitle;
  final String pdfUrl;
  final String entityId;
  final String entityType;
  final AuthSession session;
  final ApiClient apiClient;

  String get fileName {
    final cleanedTitle = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final shortId = entityId.length <= 8 ? entityId : entityId.substring(0, 8);
    return '$cleanedTitle-$shortId.pdf';
  }
}

class _DetailRow {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;
}

class _MetricInfo {
  const _MetricInfo(this.label, this.value);

  final String label;
  final String value;
}
