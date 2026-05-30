import 'package:flutter/material.dart';

import '../../../app/api/api_exception.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/widgets/page_header.dart';
import '../../auth/domain/auth_session.dart';
import '../data/tariff_gateway.dart';
import '../domain/tariff_item.dart';
import '../domain/tariff_type.dart';
import 'tariff_form_screen.dart';

class TariffManagementScreen extends StatefulWidget {
  const TariffManagementScreen({
    required this.session,
    required this.tariffGateway,
    super.key,
  });

  final AuthSession session;
  final TariffGateway tariffGateway;

  @override
  State<TariffManagementScreen> createState() => _TariffManagementScreenState();
}

class _TariffManagementScreenState extends State<TariffManagementScreen> {
  TariffType _activeType = TariffType.exam;

  // Données pour chaque onglet — chargées paresseusement
  final Map<TariffType, List<TariffItem>> _data = {};
  final Map<TariffType, bool> _loading = {};
  final Map<TariffType, String?> _errors = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load(TariffType.exam);
    _load(TariffType.benefit);
  }

  @override
  Widget build(BuildContext context) {
    final items = _data[_activeType] ?? [];
    final isLoading = _loading[_activeType] ?? true;
    final error = _errors[_activeType];

    final filtered = _applySearch(items, _searchQuery);
    final grouped = _groupByCategory(filtered);
    final sortedCats = grouped.keys.toList()..sort();

    final totalActive = items.where((i) => i.active).length;
    final totalInactive = items.length - totalActive;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            PageHeader(
              title: 'Grille tarifaire',
              subtitle: 'Gestion des tarifs et actes',
              trailing: IconButton.filled(
                key: const ValueKey('add-tariff-button'),
                onPressed: () => _openForm(),
                tooltip: 'Ajouter un acte',
                icon: const Icon(Icons.add_rounded),
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _load(_activeType),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Sélecteur de type ─────────────────────────
                            _TypeSelector(
                              active: _activeType,
                              onChanged: (t) {
                                setState(() {
                                  _activeType = t;
                                  _searchQuery = '';
                                });
                              },
                            ),
                            const SizedBox(height: 12),

                            // ── Stats ─────────────────────────────────────
                            if (!isLoading && error == null)
                              _StatsRow(
                                total: items.length,
                                active: totalActive,
                                inactive: totalInactive,
                              ),

                            if (!isLoading && error == null)
                              const SizedBox(height: 12),

                            // ── Recherche ─────────────────────────────────
                            if (!isLoading && error == null && items.isNotEmpty)
                              _SearchField(
                                key: ValueKey(_activeType),
                                onChanged: (q) =>
                                    setState(() => _searchQuery = q),
                              ),

                            if (!isLoading && error == null && items.isNotEmpty)
                              const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ),

                    // ── Corps ───────────────────────────────────────────────
                    if (isLoading)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (error != null)
                      SliverFillRemaining(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _ErrorState(
                            message: error,
                            onRetry: () => _load(_activeType),
                          ),
                        ),
                      )
                    else if (items.isEmpty)
                      SliverFillRemaining(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _EmptyState(
                            type: _activeType,
                            onAdd: () => _openForm(),
                          ),
                        ),
                      )
                    else if (filtered.isEmpty)
                      SliverFillRemaining(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _NoResultState(query: _searchQuery),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        sliver: SliverList.list(
                          children: [
                            for (final cat in sortedCats)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _CollapsibleCategory(
                                  key: ValueKey('$_activeType-$cat'),
                                  label: cat,
                                  items: grouped[cat] ?? [],
                                  onTap: _openForm,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  List<TariffItem> _applySearch(List<TariffItem> items, String q) {
    if (q.trim().isEmpty) return items;
    final lower = q.toLowerCase();
    return items
        .where((i) =>
            i.name.toLowerCase().contains(lower) ||
            i.code.toLowerCase().contains(lower) ||
            (i.category?.toLowerCase().contains(lower) ?? false))
        .toList();
  }

  Map<String, List<TariffItem>> _groupByCategory(List<TariffItem> items) {
    final map = <String, List<TariffItem>>{};
    for (final item in items) {
      final cat =
          (item.category?.isNotEmpty == true) ? item.category! : 'Autre';
      map.putIfAbsent(cat, () => []).add(item);
    }
    return map;
  }

  Future<void> _load(TariffType type) async {
    setState(() {
      _loading[type] = true;
      _errors[type] = null;
    });
    try {
      final items = await widget.tariffGateway.listItems(
        session: widget.session,
        type: type,
      );
      if (!mounted) return;
      setState(() {
        _data[type] = items;
        _loading[type] = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading[type] = false;
        _errors[type] = e is ApiException
            ? e.message
            : 'Impossible de charger la grille tarifaire.';
      });
    }
  }

  Future<void> _openForm([TariffItem? item]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TariffFormScreen(
          session: widget.session,
          tariffGateway: widget.tariffGateway,
          type: _activeType,
          item: item,
        ),
      ),
    );
    if (saved == true) await _load(_activeType);
  }
}

// ─── Type selector ────────────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.active, required this.onChanged});

  final TariffType active;
  final ValueChanged<TariffType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final type in TariffType.values) ...[
          if (type != TariffType.values.first) const SizedBox(width: 10),
          Expanded(
            child: _TypeChip(
              type: type,
              selected: type == active,
              onTap: () => onChanged(type),
            ),
          ),
        ],
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final TariffType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = type == TariffType.exam
        ? Icons.science_rounded
        : Icons.medical_services_rounded;
    final color =
        selected ? AppColors.deepHealthBlue : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.deepHealthBlue
              : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.deepHealthBlue
                : AppColors.border.withValues(alpha: 0.55),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.deepHealthBlue.withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : color,
            ),
            const SizedBox(width: 8),
            Text(
              type.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.total,
    required this.active,
    required this.inactive,
  });

  final int total;
  final int active;
  final int inactive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
          value: total.toString(),
          label: 'au total',
          color: AppColors.deepHealthBlue,
          icon: Icons.list_alt_rounded,
        ),
        const SizedBox(width: 8),
        _StatChip(
          value: active.toString(),
          label: 'actifs',
          color: AppColors.medicalGreen,
          icon: Icons.check_circle_outline_rounded,
        ),
        const SizedBox(width: 8),
        _StatChip(
          value: inactive.toString(),
          label: 'inactifs',
          color: AppColors.textSecondary,
          icon: Icons.block_rounded,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 7),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        fontSize: 16,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Search ───────────────────────────────────────────────────────────────────

class _SearchField extends StatefulWidget {
  const _SearchField({required this.onChanged, super.key});

  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      onChanged: widget.onChanged,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
      decoration: InputDecoration(
        hintText: 'Code, désignation ou catégorie…',
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.65),
            ),
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        prefixIconColor: AppColors.textSecondary,
        suffixIcon: _ctrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  _ctrl.clear();
                  widget.onChanged('');
                  setState(() {});
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.card,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: AppColors.border.withValues(alpha: 0.55)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: AppColors.border.withValues(alpha: 0.55)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.medicalGreen, width: 1.5),
        ),
      ),
    );
  }
}

// ─── Catégorie accordéon ──────────────────────────────────────────────────────

class _CollapsibleCategory extends StatefulWidget {
  const _CollapsibleCategory({
    required this.label,
    required this.items,
    required this.onTap,
    super.key,
  });

  final String label;
  final List<TariffItem> items;
  final void Function(TariffItem) onTap;

  @override
  State<_CollapsibleCategory> createState() => _CollapsibleCategoryState();
}

class _CollapsibleCategoryState extends State<_CollapsibleCategory>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _ctrl;
  late final Animation<double> _rotate;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _rotate = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.items.length;
    final activeCount = widget.items.where((i) => i.active).length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.40)),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepHealthBlue.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── En-tête cliquable ──────────────────────────────────────────
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
                child: Row(
                  children: [
                    // Icône catégorie
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.medicalGreen.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.folder_rounded,
                        color: AppColors.medicalGreen,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Label + compteur
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  height: 1.1,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              _CatBadge(
                                label: '$activeCount actif${activeCount > 1 ? 's' : ''}',
                                color: AppColors.medicalGreen,
                              ),
                              if (count - activeCount > 0) ...[
                                const SizedBox(width: 6),
                                _CatBadge(
                                  label: '${count - activeCount} inactif${count - activeCount > 1 ? 's' : ''}',
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Compteur total
                    Text(
                      '$count',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.deepHealthBlue,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                    ),
                    const SizedBox(width: 6),
                    // Chevron animé
                    RotationTransition(
                      turns: _rotate,
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Contenu dépliable ──────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(14),
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? FadeTransition(
                      opacity: _fade,
                      child: Column(
                        children: [
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.border.withValues(alpha: 0.35),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                            child: Column(
                              children: [
                                for (int i = 0;
                                    i < widget.items.length;
                                    i++) ...[
                                  if (i > 0) const SizedBox(height: 6),
                                  _TariffCard(
                                    item: widget.items[i],
                                    onTap: () =>
                                        widget.onTap(widget.items[i]),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatBadge extends StatelessWidget {
  const _CatBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
            ),
      ),
    );
  }
}

// ─── Carte d'acte tarifaire ───────────────────────────────────────────────────

class _TariffCard extends StatelessWidget {
  const _TariffCard({required this.item, required this.onTap});

  final TariffItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = item.active;
    final codeColor =
        active ? AppColors.medicalGreen : AppColors.textSecondary;

    return Material(
      color: active
          ? AppColors.lightBackground.withValues(alpha: 0.70)
          : AppColors.lightBackground.withValues(alpha: 0.40),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? AppColors.border.withValues(alpha: 0.30)
                  : AppColors.border.withValues(alpha: 0.18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Ligne 1 : code + prix + chevron ────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Badge code — une seule ligne, largeur auto
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: codeColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.code,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: codeColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.5,
                            height: 1.0,
                          ),
                    ),
                  ),
                  // Statut inactif
                  if (!active) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Inactif',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color:
                                      AppColors.error.withValues(alpha: 0.75),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Prix
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: _formatPrice(item.price),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: active
                                        ? AppColors.deepHealthBlue
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    height: 1,
                                  ),
                        ),
                        TextSpan(
                          text: ' FCFA',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.edit_outlined,
                    size: 15,
                    color: AppColors.textSecondary.withValues(alpha: 0.40),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              // ── Ligne 2 : désignation ────────────────────────────────────
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: active
                          ? AppColors.textPrimary
                          : AppColors.textSecondary.withValues(alpha: 0.70),
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      height: 1.3,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    final n = price.toInt();
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u202F');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ─── États vides / erreur ─────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.error,
              size: 34,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Chargement échoué',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.type, required this.onAdd});

  final TariffType type;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isExam = type == TariffType.exam;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.deepHealthBlue.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isExam ? Icons.science_outlined : Icons.medical_services_outlined,
              size: 40,
              color: AppColors.deepHealthBlue.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Grille vide',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            isExam
                ? 'Aucun examen de laboratoire dans la grille tarifaire.'
                : 'Aucun acte de soin dans la grille tarifaire.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('Ajouter un ${type.singularLabel.toLowerCase()}'),
          ),
        ],
      ),
    );
  }
}

class _NoResultState extends StatelessWidget {
  const _NoResultState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 44,
            color: AppColors.textSecondary.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 12),
          Text(
            'Aucun résultat',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Aucun acte ne correspond à "$query"',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.75),
                ),
          ),
        ],
      ),
    );
  }
}
