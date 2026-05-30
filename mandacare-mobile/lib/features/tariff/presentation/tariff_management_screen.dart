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

class _TariffManagementScreenState extends State<TariffManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: TariffType.values.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: 'Grille tarifaire',
              subtitle: 'Examens labo et actes de soins',
            ),
            _TariffTabBar(controller: _tabController),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  for (final type in TariffType.values)
                    _TariffTab(
                      session: widget.session,
                      tariffGateway: widget.tariffGateway,
                      type: type,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TariffTabBar extends StatelessWidget {
  const _TariffTabBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.40)),
      ),
      child: TabBar(
        controller: controller,
        padding: const EdgeInsets.all(4),
        dividerHeight: 0,
        indicator: BoxDecoration(
          color: AppColors.deepHealthBlue,
          borderRadius: BorderRadius.circular(9),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepHealthBlue.withValues(alpha: 0.22),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: [
          for (final type in TariffType.values)
            Tab(
              icon: Icon(
                type == TariffType.exam
                    ? Icons.science_rounded
                    : Icons.medical_services_rounded,
                size: 17,
              ),
              text: type.label,
              iconMargin: const EdgeInsets.only(bottom: 3),
            ),
        ],
      ),
    );
  }
}

// ─── Tab content ─────────────────────────────────────────────────────────────

class _TariffTab extends StatefulWidget {
  const _TariffTab({
    required this.session,
    required this.tariffGateway,
    required this.type,
  });

  final AuthSession session;
  final TariffGateway tariffGateway;
  final TariffType type;

  @override
  State<_TariffTab> createState() => _TariffTabState();
}

class _TariffTabState extends State<_TariffTab>
    with AutomaticKeepAliveClientMixin {
  List<TariffItem> _items = const [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final filtered = _searchQuery.trim().isEmpty
        ? _items
        : _items
            .where((item) =>
                item.name
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                item.code
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                (item.category
                        ?.toLowerCase()
                        .contains(_searchQuery.toLowerCase()) ??
                    false))
            .toList();

    // Group by category
    final Map<String, List<TariffItem>> grouped = {};
    for (final item in filtered) {
      final cat = item.category?.isNotEmpty == true
          ? item.category!
          : 'Sans catégorie';
      grouped.putIfAbsent(cat, () => []).add(item);
    }
    final sortedCategories = grouped.keys.toList()..sort();

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
            children: [
              const SizedBox(height: 6),
              _SearchBar(
                onChanged: (q) => setState(() => _searchQuery = q),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _LoadError(message: _error!, onRetry: _load)
              else if (_items.isEmpty)
                _EmptyState(type: widget.type)
              else if (filtered.isEmpty)
                _NoResultState(query: _searchQuery)
              else
                for (final cat in sortedCategories) ...[
                  _CategoryHeader(label: cat, count: grouped[cat]!.length),
                  const SizedBox(height: 8),
                  for (final item in grouped[cat]!) ...[
                    _TariffCard(
                      item: item,
                      onTap: () => _openForm(item),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 8),
                ],
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'add-tariff-${widget.type.name}',
            key: ValueKey('add-tariff-${widget.type.name}'),
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add_rounded),
            label: Text('Ajouter ${widget.type.singularLabel.toLowerCase()}'),
            backgroundColor: AppColors.deepHealthBlue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.tariffGateway.listItems(
        session: widget.session,
        type: widget.type,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _message(error);
      });
    }
  }

  Future<void> _openForm([TariffItem? item]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TariffFormScreen(
          session: widget.session,
          tariffGateway: widget.tariffGateway,
          type: widget.type,
          item: item,
        ),
      ),
    );
    if (saved == true) await _load();
  }

  String _message(Object error) {
    if (error is ApiException) return error.message;
    return 'Impossible de charger la grille tarifaire.';
  }
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Rechercher par nom, code, catégorie…',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        filled: true,
        fillColor: AppColors.lightBackground,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.45)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.45)),
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.deepHealthBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.deepHealthBlue.withValues(alpha: 0.14),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.deepHealthBlue,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count acte${count > 1 ? 's' : ''}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _TariffCard extends StatelessWidget {
  const _TariffCard({required this.item, required this.onTap});

  final TariffItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item.active
                  ? AppColors.border.withValues(alpha: 0.45)
                  : AppColors.border.withValues(alpha: 0.20),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.deepHealthBlue.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _CodeBadge(code: item.code, active: item.active),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: item.active
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    if (!item.active)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Inactif',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.error.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _PriceBadge(price: item.price),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeBadge extends StatelessWidget {
  const _CodeBadge({required this.code, required this.active});

  final String code;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.medicalGreen : AppColors.textSecondary;
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        code,
        maxLines: 2,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          height: 1.2,
        ),
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({required this.price});

  final double price;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _formatPrice(price),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.deepHealthBlue,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          'FCFA',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    final n = price.toInt();
    // Thousands separator
    final s = n.toString();
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write(' ');
      result.write(s[i]);
    }
    return result.toString();
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.type});

  final TariffType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(
            type == TariffType.exam
                ? Icons.science_outlined
                : Icons.medical_services_outlined,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Aucun ${type.singularLabel.toLowerCase()} enregistré',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Utilisez le bouton ci-dessous pour ajouter un acte.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 40, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            'Aucun résultat pour "$query"',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
