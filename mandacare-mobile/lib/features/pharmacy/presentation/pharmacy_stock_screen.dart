import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
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
            return AlertDialog(
              title: const Text('Nouveau médicament'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: codeController,
                        decoration: const InputDecoration(labelText: 'Code (ex: PARACET500)'),
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: labelController,
                        decoration: const InputDecoration(labelText: 'Nom du médicament'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: dosageController,
                        decoration: const InputDecoration(labelText: 'Dosage (ex: 500mg, 1g)'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: 'Prix de vente (FCFA)'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requis';
                          if (double.tryParse(v) == null) return 'Nombre invalide';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: thresholdController,
                        decoration: const InputDecoration(labelText: 'Seuil alerte critique'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requis';
                          if (int.tryParse(v) == null) return 'Entier invalide';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => saving = true);
                          try {
                            await widget.patientGateway.createPharmacyItem(
                              session: widget.session,
                              code: codeController.text,
                              label: labelController.text,
                              dosage: dosageController.text.isEmpty ? null : dosageController.text,
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
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : const Text('Créer'),
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
            return AlertDialog(
              title: Text('Ajuster Stock - ${item.label}'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Stock actuel : ${item.stockQuantity} unités',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantité (ex: 10 pour ajouter, -5 pour retirer)',
                        helperText: 'Valeur positive = Entrée, Négative = Sortie',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(signed: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requis';
                        final parsed = int.tryParse(v);
                        if (parsed == null) return 'Nombre entier requis';
                        if (parsed == 0) return 'La quantité ne peut pas être 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: reasonController,
                      decoration: const InputDecoration(labelText: 'Motif de l\'ajustement'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton(
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
                              reason: reasonController.text,
                            );
                            Navigator.of(dialogContext).pop();
                            _loadItems();
                          } catch (_) {
                            setDialogState(() => saving = false);
                          }
                        },
                  style: FilledButton.styleFrom(backgroundColor: AppColors.medicalGreen),
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : const Text('Enregistrer'),
                ),
              ],
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
      appBar: AppBar(
        title: const Text('Stock Pharmacie'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadItems,
          ),
          if (widget.session.roleCode == 'ADMIN' || widget.session.roleCode == 'MEDECIN')
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.medicalGreen),
              onPressed: _showAddDialog,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.medicalGreen)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadItems, child: const Text('Réessayer')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Rechercher un médicament (nom ou code)...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('Aucun médicament trouvé.'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                return Card(
                                  elevation: item.critical ? 2 : 1,
                                  color: item.critical ? Colors.red[50] : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: item.critical ? Colors.red[200]! : Colors.grey[200]!,
                                      width: item.critical ? 1.5 : 1,
                                    ),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.label,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ),
                                        if (item.critical)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.red[100],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: const [
                                                Icon(Icons.warning, size: 14, color: Colors.red),
                                                SizedBox(width: 4),
                                                Text('Stock critique !', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 8),
                                        Text('Code : ${item.code} ${item.dosage != null ? "· Dosage : ${item.dosage}" : ""}'),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Prix : ${item.price.toStringAsFixed(0)} FCFA',
                                          style: const TextStyle(color: AppColors.deepHealthBlue, fontWeight: FontWeight.w600),
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
                                            color: item.critical ? Colors.red : Colors.green[700],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text('En stock', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      ],
                                    ),
                                    onTap: () => _showAdjustStockDialog(item),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
