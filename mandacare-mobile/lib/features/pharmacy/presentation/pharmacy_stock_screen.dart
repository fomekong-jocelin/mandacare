import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/widgets/compact_form_field.dart';
import '../../../shared/presentation/widgets/form_dialog.dart';
import '../../../shared/presentation/widgets/metric_strip.dart';
import '../../../shared/presentation/widgets/page_header.dart';
import '../../auth/domain/auth_session.dart';
import '../../patients/data/patient_gateway.dart';
import '../../patients/domain/pharmacy_item.dart';

class PharmacyStockScreen extends StatefulWidget {
  const PharmacyStockScreen({
    required this.session,
    required this.patientGateway,
    super.key,
  });

  final AuthSession session;
  final PatientGateway patientGateway;

  @override
  State<PharmacyStockScreen> createState() => _PharmacyStockScreenState();
}

class _PharmacyStockScreenState extends State<PharmacyStockScreen> {
  List<PharmacyItem> _items = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.patientGateway.getPharmacyItems(
        session: widget.session,
      );
      if (!mounted) return;
      setState(() {
        _items = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = "Impossible de charger la pharmacie.";
        _loading = false;
      });
    }
  }

  List<PharmacyItem> get _filteredItems {
    if (_searchQuery.trim().isEmpty) return _items;
    final query = _searchQuery.toLowerCase();
    return _items.where((item) {
      return item.label.toLowerCase().contains(query) ||
          item.code.toLowerCase().contains(query);
    }).toList();
  }

  bool get _canManageCatalog {
    return widget.session.roleCode == 'ADMIN' ||
        widget.session.roleCode == 'MEDECIN';
  }

  void _showAddDialog() {
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController();
    final labelController = TextEditingController();
    final dosageController = TextEditingController();
    final priceController = TextEditingController();
    final thresholdController = TextEditingController(text: '5');
    bool saving = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AppFormDialog(
              title: 'Nouveau médicament',
              subtitle: 'Ajouter une référence au catalogue pharmacie',
              icon: Icons.local_pharmacy_rounded,
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CompactTextFormField(
                      controller: codeController,
                      label: 'Code',
                      hintText: 'Ex: PARACET500',
                      icon: Icons.qr_code_rounded,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.characters,
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    CompactTextFormField(
                      controller: labelController,
                      label: 'Nom du médicament',
                      icon: Icons.label_important_rounded,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    CompactTextFormField(
                      controller: dosageController,
                      label: 'Dosage',
                      hintText: 'Ex: 500mg, 1g',
                      icon: Icons.scale_rounded,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CompactTextFormField(
                            controller: priceController,
                            label: 'Prix de vente',
                            hintText: 'FCFA',
                            icon: Icons.payments_rounded,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            validator: _positiveNumberRequired,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CompactTextFormField(
                            controller: thresholdController,
                            label: 'Seuil alerte',
                            icon: Icons.warning_amber_rounded,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            validator: _integerRequired,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => saving = true);
                          try {
                            await widget.patientGateway.createPharmacyItem(
                              session: widget.session,
                              code: codeController.text.trim(),
                              label: labelController.text.trim(),
                              dosage: dosageController.text.trim().isEmpty
                                  ? null
                                  : dosageController.text.trim(),
                              price: double.parse(priceController.text.trim()),
                              alertThreshold: int.parse(
                                thresholdController.text.trim(),
                              ),
                            );
                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();
                            await _loadItems();
                          } catch (_) {
                            setDialogState(() => saving = false);
                          }
                        },
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(saving ? 'Création...' : 'Créer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showItemActions(PharmacyItem item) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.deepHealthBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Code : ${item.code}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.swap_vert_rounded),
                  title: const Text('Ajuster le stock'),
                  subtitle: const Text('Entrée ou sortie de quantité'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showAdjustStockDialog(item);
                  },
                ),
                if (_canManageCatalog)
                  ListTile(
                    leading: const Icon(Icons.edit_rounded),
                    title: const Text('Modifier le médicament'),
                    subtitle: const Text('Prix, dosage, seuil et libellé'),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _showEditDialog(item);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(PharmacyItem item) {
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController(text: item.code);
    final labelController = TextEditingController(text: item.label);
    final dosageController = TextEditingController(text: item.dosage ?? '');
    final priceController = TextEditingController(
      text: item.price.toStringAsFixed(0),
    );
    final thresholdController = TextEditingController(
      text: item.alertThreshold.toString(),
    );
    bool saving = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AppFormDialog(
              title: 'Modifier médicament',
              subtitle: item.label,
              icon: Icons.medication_rounded,
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CompactTextFormField(
                      controller: codeController,
                      label: 'Code',
                      icon: Icons.qr_code_rounded,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.characters,
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    CompactTextFormField(
                      controller: labelController,
                      label: 'Nom du médicament',
                      icon: Icons.label_important_rounded,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    CompactTextFormField(
                      controller: dosageController,
                      label: 'Dosage',
                      hintText: 'Ex: 500mg, 1g',
                      icon: Icons.scale_rounded,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CompactTextFormField(
                            controller: priceController,
                            label: 'Prix de vente',
                            hintText: 'FCFA',
                            icon: Icons.payments_rounded,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            validator: _positiveNumberRequired,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CompactTextFormField(
                            controller: thresholdController,
                            label: 'Seuil alerte',
                            icon: Icons.warning_amber_rounded,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            validator: _integerRequired,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => saving = true);
                          try {
                            await widget.patientGateway.updatePharmacyItem(
                              session: widget.session,
                              id: item.id,
                              code: codeController.text.trim(),
                              label: labelController.text.trim(),
                              dosage: dosageController.text.trim().isEmpty
                                  ? null
                                  : dosageController.text.trim(),
                              price: double.parse(priceController.text.trim()),
                              alertThreshold: int.parse(
                                thresholdController.text.trim(),
                              ),
                            );
                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();
                            await _loadItems();
                          } catch (_) {
                            setDialogState(() => saving = false);
                          }
                        },
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(saving ? 'Enregistrement...' : 'Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAdjustStockDialog(PharmacyItem item) {
    final formKey = GlobalKey<FormState>();
    final quantityController = TextEditingController();
    final reasonController = TextEditingController();
    bool saving = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AppFormDialog(
              title: 'Ajuster le stock',
              subtitle: item.label,
              icon: Icons.edit_note_rounded,
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CurrentStockBanner(item: item),
                    const SizedBox(height: 14),
                    CompactTextFormField(
                      controller: quantityController,
                      label: 'Quantité',
                      hintText: 'Ex: 10 ou -5',
                      helperText:
                          'Utiliser une valeur négative pour une sortie.',
                      icon: Icons.swap_vert_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                      ),
                      textInputAction: TextInputAction.next,
                      validator: _stockQuantityValidator,
                    ),
                    const SizedBox(height: 12),
                    CompactTextFormField(
                      controller: reasonController,
                      label: "Motif de l'ajustement",
                      icon: Icons.notes_rounded,
                      textInputAction: TextInputAction.done,
                      textCapitalization: TextCapitalization.sentences,
                      validator: _required,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => saving = true);
                          try {
                            await widget.patientGateway.adjustPharmacyStock(
                              session: widget.session,
                              id: item.id,
                              quantity: int.parse(
                                quantityController.text.trim(),
                              ),
                              reason: reasonController.text.trim(),
                            );
                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();
                            await _loadItems();
                          } catch (_) {
                            setDialogState(() => saving = false);
                          }
                        },
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(saving ? 'Enregistrement...' : 'Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Requis';
    }
    return null;
  }

  String? _positiveNumberRequired(String? value) {
    final requiredError = _required(value);
    if (requiredError != null) return requiredError;
    final parsed = double.tryParse(value!.trim());
    if (parsed == null || parsed < 0) {
      return 'Nombre invalide';
    }
    return null;
  }

  String? _integerRequired(String? value) {
    final requiredError = _required(value);
    if (requiredError != null) return requiredError;
    if (int.tryParse(value!.trim()) == null) {
      return 'Entier invalide';
    }
    return null;
  }

  String? _stockQuantityValidator(String? value) {
    final requiredError = _required(value);
    if (requiredError != null) return requiredError;
    final parsed = int.tryParse(value!.trim());
    if (parsed == null) return 'Nombre entier requis';
    if (parsed == 0) return 'La quantité ne peut pas être 0';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;
    final criticalCount = _items.where((item) => item.critical).length;
    final totalStock = _items.fold<int>(
      0,
      (total, item) => total + item.stockQuantity,
    );

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: 'Stock Pharmacie',
              subtitle: 'Gestion du catalogue et ajustements',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _loadItems,
                    tooltip: 'Rafraîchir',
                  ),
                  if (_canManageCatalog)
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppColors.medicalGreen,
                      ),
                      onPressed: _showAddDialog,
                      tooltip: 'Nouveau médicament',
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                children: [
                  TextField(
                    textInputAction: TextInputAction.search,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(fontSize: 15),
                    decoration: compactInputDecoration(
                      context,
                      hintText: 'Rechercher un médicament (nom ou code)...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                  if (!_loading && _error == null) ...[
                    const SizedBox(height: 12),
                    MetricStrip(
                      items: [
                        MetricStripItem(
                          value: _items.length.toString(),
                          label: 'Références',
                          color: AppColors.deepHealthBlue,
                        ),
                        MetricStripItem(
                          value: totalStock.toString(),
                          label: 'Unités',
                          color: AppColors.medicalGreen,
                        ),
                        MetricStripItem(
                          value: criticalCount.toString(),
                          label: 'Critiques',
                          color: criticalCount > 0
                              ? AppColors.error
                              : AppColors.success,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _PharmacyStockContent(
                loading: _loading,
                error: _error,
                items: filtered,
                onRetry: _loadItems,
                onItemTap: _showItemActions,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PharmacyStockContent extends StatelessWidget {
  const _PharmacyStockContent({
    required this.loading,
    required this.error,
    required this.items,
    required this.onRetry,
    required this.onItemTap,
  });

  final bool loading;
  final String? error;
  final List<PharmacyItem> items;
  final Future<void> Function() onRetry;
  final ValueChanged<PharmacyItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return _StockStateView(
        icon: Icons.cloud_off_rounded,
        title: 'Chargement impossible',
        message: error!,
        color: AppColors.error,
        actionLabel: 'Réessayer',
        onActionPressed: () => onRetry(),
      );
    }

    if (items.isEmpty) {
      return const _StockStateView(
        icon: Icons.search_off_rounded,
        title: 'Aucun médicament trouvé.',
        message: 'Ajustez la recherche ou ajoutez une référence au catalogue.',
        color: AppColors.medicalGreen,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return _PharmacyItemCard(item: item, onTap: () => onItemTap(item));
      },
    );
  }
}

class _PharmacyItemCard extends StatelessWidget {
  const _PharmacyItemCard({required this.item, required this.onTap});

  final PharmacyItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stockColor = item.critical ? AppColors.error : AppColors.success;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item.critical
                  ? AppColors.error.withValues(alpha: 0.28)
                  : AppColors.border.withValues(alpha: 0.40),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.deepHealthBlue.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            leading: _MedicineIcon(critical: item.critical),
            title: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.deepHealthBlue,
                fontWeight: FontWeight.w700,
                height: 1.12,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _itemDetails(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _SoftChip(
                        label: '${item.price.toStringAsFixed(0)} FCFA',
                        color: AppColors.medicalGreen,
                      ),
                      if (item.critical)
                        const _SoftChip(
                          label: 'Stock critique !',
                          color: AppColors.error,
                          icon: Icons.warning_amber_rounded,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            trailing: _StockQuantityBadge(
              quantity: item.stockQuantity,
              color: stockColor,
            ),
          ),
        ),
      ),
    );
  }

  String _itemDetails(PharmacyItem item) {
    final dosage = item.dosage;
    if (dosage == null || dosage.trim().isEmpty) {
      return 'Code : ${item.code}';
    }
    return 'Code : ${item.code} · Dosage : $dosage';
  }
}

class _MedicineIcon extends StatelessWidget {
  const _MedicineIcon({required this.critical});

  final bool critical;

  @override
  Widget build(BuildContext context) {
    final color = critical ? AppColors.error : AppColors.medicalGreen;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.medication_rounded, color: color, size: 21),
    );
  }
}

class _StockQuantityBadge extends StatelessWidget {
  const _StockQuantityBadge({required this.quantity, required this.color});

  final int quantity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$quantity U',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'En stock',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentStockBanner extends StatelessWidget {
  const _CurrentStockBanner({required this.item});

  final PharmacyItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.critical ? AppColors.error : AppColors.success;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Stock actuel : ${item.stockQuantity} unités',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockStateView extends StatelessWidget {
  const _StockStateView({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    this.actionLabel,
    this.onActionPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (actionLabel != null && onActionPressed != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onActionPressed,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
