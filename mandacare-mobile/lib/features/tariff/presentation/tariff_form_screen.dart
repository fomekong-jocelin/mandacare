import 'package:flutter/material.dart';

import '../../../app/api/api_exception.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/widgets/compact_form_field.dart';
import '../../../shared/presentation/widgets/form_section.dart';
import '../../../shared/presentation/widgets/page_header.dart';
import '../../auth/domain/auth_session.dart';
import '../data/tariff_gateway.dart';
import '../domain/tariff_item.dart';
import '../domain/tariff_payload.dart';
import '../domain/tariff_type.dart';

class TariffFormScreen extends StatefulWidget {
  const TariffFormScreen({
    required this.session,
    required this.tariffGateway,
    required this.type,
    this.item,
    super.key,
  });

  final AuthSession session;
  final TariffGateway tariffGateway;
  final TariffType type;
  final TariffItem? item;

  @override
  State<TariffFormScreen> createState() => _TariffFormScreenState();
}

class _TariffFormScreenState extends State<TariffFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _priceController;
  late bool _active;
  bool _saving = false;

  bool get _editing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _codeController = TextEditingController(text: item?.code ?? '');
    _nameController = TextEditingController(text: item?.name ?? '');
    _categoryController = TextEditingController(text: item?.category ?? '');
    _priceController = TextEditingController(
      text: item != null ? item.price.toStringAsFixed(0) : '',
    );
    _active = item?.active ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: _editing
                  ? 'Modifier ${widget.type.singularLabel.toLowerCase()}'
                  : 'Nouvel ${widget.type.singularLabel.toLowerCase()}',
              subtitle: _editing
                  ? 'Mettre à jour le tarif et le statut'
                  : 'Ajouter à la grille tarifaire',
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
                  children: [
                    FormSection(
                      title: 'Identification',
                      children: [
                        CompactTextFormField(
                          controller: _codeController,
                          label: 'Code',
                          icon: Icons.tag_rounded,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.characters,
                          readOnly: _editing,
                          validator: _required,
                          helperText: _editing
                              ? 'Le code ne peut pas être modifié.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        CompactTextFormField(
                          controller: _nameController,
                          label: 'Désignation',
                          icon: Icons.medical_services_outlined,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.sentences,
                          validator: _required,
                        ),
                        const SizedBox(height: 12),
                        CompactTextFormField(
                          controller: _categoryController,
                          label: 'Catégorie',
                          icon: Icons.folder_outlined,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.characters,
                          helperText: 'Ex: BIOCHIMIE, HEMATOLOGIE, SEROLOGIE...',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    FormSection(
                      title: 'Tarif',
                      children: [
                        CompactTextFormField(
                          controller: _priceController,
                          label: 'Prix (FCFA)',
                          icon: Icons.payments_outlined,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.done,
                          validator: _priceValidator,
                        ),
                        if (_editing) ...[
                          const SizedBox(height: 12),
                          _ActiveSwitch(
                            active: _active,
                            onChanged: (v) => setState(() => _active = v),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  key: const ValueKey('save-tariff-button'),
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    _saving ? 'Enregistrement...' : 'Enregistrer',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final price = double.parse(
        _priceController.text.trim().replaceAll(',', '.'),
      );
      if (_editing) {
        await widget.tariffGateway.updateItem(
          session: widget.session,
          type: widget.type,
          id: widget.item!.id,
          payload: UpdateTariffPayload(
            name: _nameController.text.trim(),
            category: _optional(_categoryController.text),
            price: price,
            active: _active,
          ),
        );
      } else {
        await widget.tariffGateway.createItem(
          session: widget.session,
          type: widget.type,
          payload: TariffPayload(
            code: _codeController.text.trim(),
            name: _nameController.text.trim(),
            category: _optional(_categoryController.text),
            price: price,
          ),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editing ? 'Tarif mis à jour' : 'Acte ajouté à la grille',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message(error))),
      );
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Champ requis';
    return null;
  }

  String? _priceValidator(String? value) {
    final err = _required(value);
    if (err != null) return err;
    final n = double.tryParse(value!.trim().replaceAll(',', '.'));
    if (n == null || n < 0) return 'Prix invalide';
    return null;
  }

  String? _optional(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  String _message(Object error) {
    if (error is ApiException) return error.message;
    return "Impossible d'enregistrer cet acte.";
  }
}

class _ActiveSwitch extends StatelessWidget {
  const _ActiveSwitch({required this.active, required this.onChanged});

  final bool active;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.lightBackground.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.60)),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle_outline_rounded : Icons.block_rounded,
            color: active ? AppColors.success : AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              active ? 'Acte actif (visible en consultation)' : 'Acte inactif',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch(value: active, onChanged: onChanged),
        ],
      ),
    );
  }
}
