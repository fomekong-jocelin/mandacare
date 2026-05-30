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
                        sliver: SliverList.builder(
                          itemCount: _countSlots(sortedCats, grouped),
                          itemBuilder: (context, index) {
                            return _buildSlot(
                              index,
                              sortedCats,
                              grouped,
                            );
                          },
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

  // Compte total de slots (headers + items)
  int _countSlots(
    List<String> cats,
    Map<String, List<TariffItem>> grouped,
  ) {
    int count = 0;
    for (final cat in cats) {
      count += 1 + (grouped[cat]?.length ?? 0);
    }
    return count;
  }

  Widget _buildSlot(
    int index,
    List<String> sortedCats,
    Map<String, List<TariffItem>> grouped,
  ) {
    int cursor = 0;
    for (final cat in sortedCats) {
      final catItems = grouped[cat] ?? [];
      if (index == cursor) {
        // Header de catégorie
        return Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 6),
          child: _CategoryHeader(
            label: cat,
            count: catItems.length,
          ),
        );
      }
      cursor++;
      final itemIndex = index - cursor;
      if (itemIndex < catItems.length) {
        final item = catItems[itemIndex];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _TariffCard(
            item: item,
            onTap: () => _openForm(item),
          ),
        );
      }
      cursor += catItems.length;
    }
    return const SizedBox.shrink();
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

// ─── Category header ──────────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.medicalGreen.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.medicalGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.6,
                ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count acte${count > 1 ? 's' : ''}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.75),
                fontSize: 11,
              ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 10),
            height: 1,
            color: AppColors.border.withValues(alpha: 0.30),
          ),
        ),
      ],
    );
  }
}

// ─── Tariff card ──────────────────────────────────────────────────────────────

class _TariffCard extends StatelessWidget {
  const _TariffCard({required this.item, required this.onTap});

  final TariffItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = item.active;
    return Material(
      color: active ? AppColors.card : AppColors.lightBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? AppColors.border.withValues(alpha: 0.40)
                  : AppColors.border.withValues(alpha: 0.22),
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color:
                          AppColors.deepHealthBlue.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Code pill
              _CodePill(code: item.code, active: active),
              const SizedBox(width: 12),
              // Name + statut
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: active
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                height: 1.25,
                              ),
                    ),
                    if (!active) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.block_rounded,
                            size: 11,
                            color: AppColors.error.withValues(alpha: 0.65),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Inactif',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.error
                                          .withValues(alpha: 0.65),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Prix + chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatPrice(item.price),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: active
                              ? AppColors.deepHealthBlue
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          height: 1,
                        ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'FCFA',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textSecondary.withValues(alpha: 0.45),
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

class _CodePill extends StatelessWidget {
  const _CodePill({required this.code, required this.active});

  final String code;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color =
        active ? AppColors.medicalGreen : AppColors.textSecondary;
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        code,
        maxLines: 2,
        textAlign: TextAlign.center,
        overflow: TextOverflow.visible,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
              letterSpacing: 0.4,
              height: 1.3,
            ),
      ),
    );
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
