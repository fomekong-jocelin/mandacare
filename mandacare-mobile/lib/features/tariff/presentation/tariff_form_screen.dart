import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/api/api_exception.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/widgets/compact_form_field.dart';
import '../../../shared/presentation/widgets/form_section.dart';
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
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _priceCtrl;
  late bool _active;
  bool _saving = false;

  bool get _editing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _codeCtrl = TextEditingController(text: item?.code ?? '');
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _categoryCtrl = TextEditingController(text: item?.category ?? '');
    _priceCtrl = TextEditingController(
      text: item != null ? item.price.toStringAsFixed(0) : '',
    );
    _active = item?.active ?? true;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            _FormHeader(
              editing: _editing,
              type: widget.type,
              item: widget.item,
            ),

            // ── Corps ─────────────────────────────────────────────────────
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    // ── Code ─────────────────────────────────────────────
                    FormSection(
                      title: 'Identification',
                      children: [
                        if (_editing)
                          _ReadonlyCodeField(code: widget.item!.code)
                        else
                          CompactTextFormField(
                            controller: _codeCtrl,
                            label: 'Code unique',
                            icon: Icons.tag_rounded,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.characters,
                            helperText: 'Identifiant court, ex: NFS, GLYCEMIE…',
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Le code est requis'
                                    : null,
                          ),
                        const SizedBox(height: 12),
                        CompactTextFormField(
                          controller: _nameCtrl,
                          label: 'Désignation',
                          icon: Icons.label_outline_rounded,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.sentences,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'La désignation est requise'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        CompactTextFormField(
                          controller: _categoryCtrl,
                          label: 'Catégorie (optionnelle)',
                          icon: Icons.folder_open_rounded,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.characters,
                          helperText: 'Ex : BIOCHIMIE, HÉMATOLOGIE…',
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // ── Prix ─────────────────────────────────────────────
                    FormSection(
                      title: 'Tarification',
                      children: [
                        _PriceField(controller: _priceCtrl),
                      ],
                    ),

                    // ── Statut (édition uniquement) ───────────────────────
                    if (_editing) ...[
                      const SizedBox(height: 18),
                      FormSection(
                        title: 'Statut',
                        children: [
                          _ActiveToggle(
                            active: _active,
                            onChanged: (v) => setState(() => _active = v),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── Bouton ────────────────────────────────────────────
                    _SubmitButton(
                      saving: _saving,
                      editing: _editing,
                      onPressed: _submit,
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final raw = _priceCtrl.text.trim().replaceAll(' ', '').replaceAll(',', '.');
      final price = double.parse(raw);

      if (_editing) {
        await widget.tariffGateway.updateItem(
          session: widget.session,
          type: widget.type,
          id: widget.item!.id,
          payload: UpdateTariffPayload(
            name: _nameCtrl.text.trim(),
            category: _optional(_categoryCtrl.text),
            price: price,
            active: _active,
          ),
        );
      } else {
        await widget.tariffGateway.createItem(
          session: widget.session,
          type: widget.type,
          payload: TariffPayload(
            code: _codeCtrl.text.trim(),
            name: _nameCtrl.text.trim(),
            category: _optional(_categoryCtrl.text),
            price: price,
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(_editing ? 'Tarif mis à jour' : 'Acte ajouté à la grille'),
            ],
          ),
          backgroundColor: AppColors.medicalGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(_message(error))),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  String? _optional(String v) {
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  String _message(Object error) {
    if (error is ApiException) return error.message;
    return "Impossible d'enregistrer cet acte.";
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _FormHeader extends StatelessWidget {
  const _FormHeader({
    required this.editing,
    required this.type,
    required this.item,
  });

  final bool editing;
  final TariffType type;
  final TariffItem? item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.lightBackground.withValues(alpha: 0.98),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepHealthBlue.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: 'Retour',
                  iconSize: 22,
                  constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        editing
                            ? 'Modifier le tarif'
                            : 'Nouvel acte tarifaire',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.deepHealthBlue,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              height: 1.05,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        editing
                            ? type.label
                            : 'Ajouter à la grille · ${type.label}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Breadcrumb de l'acte en cours d'édition
            if (editing && item != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.deepHealthBlue.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.medicalGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          item!.code,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.medicalGreen,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          item!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Champ code en lecture seule ──────────────────────────────────────────────

class _ReadonlyCodeField extends StatelessWidget {
  const _ReadonlyCodeField({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'Code unique',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.deepHealthBlue.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.lightBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: AppColors.border.withValues(alpha: 0.50)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.tag_rounded,
                size: 18,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 10),
              Text(
                code,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Non modifiable',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Champ prix ───────────────────────────────────────────────────────────────

class _PriceField extends StatelessWidget {
  const _PriceField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'Prix en FCFA',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.deepHealthBlue.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.35),
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
            filled: true,
            fillColor: AppColors.card,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 8, 0),
              child: Icon(
                Icons.payments_outlined,
                size: 20,
                color: AppColors.medicalGreen,
              ),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 44, minHeight: 44),
            suffixText: 'FCFA',
            suffixStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.60)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.60)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: AppColors.medicalGreen, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: AppColors.error.withValues(alpha: 0.7)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Le prix est requis';
            final n = double.tryParse(v.trim());
            if (n == null || n < 0) return 'Prix invalide';
            return null;
          },
        ),
      ],
    );
  }
}

// ─── Toggle actif/inactif ─────────────────────────────────────────────────────

class _ActiveToggle extends StatelessWidget {
  const _ActiveToggle({required this.active, required this.onChanged});

  final bool active;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.medicalGreen : AppColors.textSecondary;
    final bg = active
        ? AppColors.medicalGreen.withValues(alpha: 0.07)
        : AppColors.lightBackground;

    return GestureDetector(
      onTap: () => onChanged(!active),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? AppColors.medicalGreen.withValues(alpha: 0.25)
                : AppColors.border.withValues(alpha: 0.55),
          ),
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                active
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                key: ValueKey(active),
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    active ? 'Acte actif' : 'Acte inactif',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    active
                        ? 'Visible lors des demandes d\'examens et devis'
                        : 'Masqué — n\'apparaîtra pas dans les sélections',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: active,
              onChanged: onChanged,
              activeThumbColor: AppColors.medicalGreen,
              activeTrackColor: AppColors.medicalGreen.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bouton de soumission ─────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.saving,
    required this.editing,
    required this.onPressed,
  });

  final bool saving;
  final bool editing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      key: const ValueKey('save-tariff-button'),
      onPressed: saving ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: AppColors.deepHealthBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: saving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  editing ? Icons.save_rounded : Icons.add_circle_outline_rounded,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  editing ? 'Enregistrer les modifications' : 'Ajouter à la grille',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
    );
  }
}
