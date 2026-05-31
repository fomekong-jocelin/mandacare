import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/widgets/compact_form_field.dart';
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
      final data = await widget.patientGateway.getPharmacyItems(session: widget.session);
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
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.add_business_rounded, color: AppColors.medicalGreen, size: 28),
                              const SizedBox(width: 10),
                              Text(
                                'Nouveau médicament',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.deepHealthBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          CompactTextFormField(
                            controller: codeController,
                            label: 'Code (ex: PARACET500)',
                            icon: Icons.qr_code_rounded,
                            textCapitalization: TextCapitalization.characters,
                            validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                          ),
                          const SizedBox(height: 12),
                          CompactTextFormField(
                            controller: labelController,
                            label: 'Nom du médicament',
                            icon: Icons.label_important_rounded,
                            textCapitalization: TextCapitalization.sentences,
                            validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                          ),
                          const SizedBox(height: 12),
                          CompactTextFormField(
                            controller: dosageController,
                            label: 'Dosage (ex: 500mg, 1g)',
                            icon: Icons.scale_rounded,
                          ),
                          const SizedBox(height: 12),
                          CompactTextFormField(
                            controller: priceController,
                            label: 'Prix de vente (FCFA)',
                            icon: Icons.payments_rounded,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Requis';
                              if (double.tryParse(v) == null) return 'Nombre invalide';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          CompactTextFormField(
                            controller: thresholdController,
                            label: 'Seuil alerte critique',
                            icon: Icons.warning_amber_rounded,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Requis';
                              if (int.tryParse(v) == null) return 'Entier invalide';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: saving ? null : () => Navigator.of(dialogContext).pop(),
                                child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
                              ),
                              const SizedBox(width: 8),
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
                                            dosage: dosageController.text.isEmpty ? null : dosageController.text.trim(),
                                            price: double.parse(priceController.text),
                                            alertThreshold: int.parse(thresholdController.text),
                                          );
                                          Navigator.of(dialogContext).pop();
                                          _loadItems();
                                        } catch (_) {
                                          setDialogState(() => saving = false);
                                        }
                                      },
                                style: FilledButton.styleFrom(backgroundColor: AppColors.medicalGreen),
                                icon: saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.check_rounded, size: 18),
                                label: const Text('Créer'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.edit_note_rounded, color: AppColors.medicalGreen, size: 28),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Ajuster Stock - ${item.label}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.deepHealthBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                            ),
                            child: Center(
                              child: Text(
                                'Stock actuel : ${item.stockQuantity} unités',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: item.critical ? AppColors.error : AppColors.success,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          CompactTextFormField(
                            controller: quantityController,
                            label: 'Quantité (ex: 10 pour ajouter, -5 pour retirer)',
                            icon: Icons.plus_one_rounded,
                            keyboardType: const TextInputType.numberWithOptions(signed: true),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Requis';
                              final parsed = int.tryParse(v);
                              if (parsed == null) return 'Nombre entier requis';
                              if (parsed == 0) return 'La quantité ne peut pas être 0';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          CompactTextFormField(
                            controller: reasonController,
                            label: "Motif de l'ajustement",
                            icon: Icons.notes_rounded,
                            textCapitalization: TextCapitalization.sentences,
                            validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: saving ? null : () => Navigator.of(dialogContext).pop(),
                                child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
                              ),
                              const SizedBox(width: 8),
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
                                            quantity: int.parse(quantityController.text),
                                            reason: reasonController.text.trim(),
                                          );
                                          Navigator.of(dialogContext).pop();
                                          _loadItems();
                                        } catch (_) {
                                          setDialogState(() => saving = false);
                                        }
                                      },
                                style: FilledButton.styleFrom(backgroundColor: AppColors.medicalGreen),
                                icon: saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.check_rounded, size: 18),
                                label: const Text('Enregistrer'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

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
                  if (widget.session.roleCode == 'ADMIN' || widget.session.roleCode == 'MEDECIN')
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.medicalGreen),
                      onPressed: _showAddDialog,
                      tooltip: 'Nouveau médicament',
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: TextField(
                textInputAction: TextInputAction.search,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15),
                decoration: compactInputDecoration(
                  context,
                  hintText: 'Rechercher un médicament (nom ou code)...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.medicalGreen)))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                              const SizedBox(height: 16),
                              Text(_error!, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadItems,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Réessayer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.medicalGreen,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : filtered.isEmpty
                          ? const Center(
                              child: Text(
                                'Aucun médicament trouvé.',
                                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                const radius = BorderRadius.all(Radius.circular(12));

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: radius,
                                    border: Border.all(
                                      color: item.critical 
                                          ? AppColors.error.withValues(alpha: 0.5) 
                                          : AppColors.border.withValues(alpha: 0.40),
                                      width: item.critical ? 1.5 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (item.critical ? AppColors.error : AppColors.deepHealthBlue)
                                            .withValues(alpha: 0.035),
                                        blurRadius: 12,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: radius,
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.label,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: AppColors.deepHealthBlue,
                                              ),
                                            ),
                                          ),
                                          if (item.critical)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.error.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  Icon(Icons.warning_rounded, size: 14, color: AppColors.error),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Stock critique !',
                                                    style: TextStyle(
                                                      color: AppColors.error,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 8),
                                          Text(
                                            'Code : ${item.code} ${item.dosage != null ? "· Dosage : ${item.dosage}" : ""}',
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${item.price.toStringAsFixed(0)} FCFA',
                                            style: const TextStyle(
                                              color: AppColors.medicalGreen,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${item.stockQuantity} U',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: item.critical ? AppColors.error : AppColors.success,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'En stock',
                                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                      onTap: () => _showAdjustStockDialog(item),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
