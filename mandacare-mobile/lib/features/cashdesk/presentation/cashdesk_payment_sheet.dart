import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/widgets/compact_form_field.dart';
import '../../patients/data/patient_gateway.dart';

import '../../auth/domain/auth_session.dart';
import '../domain/invoice_preview.dart';

Future<CreateCashDeskPaymentPayload?> showCashDeskPaymentSheet(
  BuildContext context, {
  required String patientName,
  required String targetLabel,
  required PatientGateway patientGateway,
  required AuthSession session,
  required String visitId,
}) {
  return showModalBottomSheet<CreateCashDeskPaymentPayload>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _CashDeskPaymentSheet(
        patientName: patientName,
        targetLabel: targetLabel,
        patientGateway: patientGateway,
        session: session,
        visitId: visitId,
      );
    },
  );
}

class _CashDeskPaymentSheet extends StatefulWidget {
  const _CashDeskPaymentSheet({
    required this.patientName,
    required this.targetLabel,
    required this.patientGateway,
    required this.session,
    required this.visitId,
  });

  final String patientName;
  final String targetLabel;
  final PatientGateway patientGateway;
  final AuthSession session;
  final String visitId;

  @override
  State<_CashDeskPaymentSheet> createState() => _CashDeskPaymentSheetState();
}

class _CashDeskPaymentSheetState extends State<_CashDeskPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  _PaymentModeOption _mode = _PaymentModeOption.cash;

  InvoicePreview? _preview;
  bool _loadingPreview = true;
  String? _previewError;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
    _fetchPreview();
  }

  void _onAmountChanged() {
    setState(() {});
  }

  Future<void> _fetchPreview() async {
    setState(() {
      _loadingPreview = true;
      _previewError = null;
    });
    try {
      final preview = await widget.patientGateway.getInvoicePreview(
        session: widget.session,
        visitId: widget.visitId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _preview = preview;
        _loadingPreview = false;
        _amountController.text = preview.netAmount.toInt().toString();
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingPreview = false;
        _previewError = 'Impossible de récupérer la facture de soins.';
      });
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.premiumGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.payments_rounded,
                        color: AppColors.premiumGold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.patientName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.deepHealthBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Orientation ${widget.targetLabel}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_loadingPreview)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_previewError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.warning,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _previewError!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _fetchPreview,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  Text(
                    'Détail des prestations',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.deepHealthBlue,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.border.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      children: [
                        for (final item in _preview!.items) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(
                                  item.type == 'EXAM'
                                      ? Icons.science_rounded
                                      : Icons.medical_services_rounded,
                                  size: 16,
                                  color: item.type == 'EXAM'
                                      ? Colors.purple
                                      : AppColors.deepHealthBlue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                Text(
                                  '${item.quantity} x ${item.price.toInt()} Frs',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (item != _preview!.items.last)
                            Divider(
                              height: 1,
                              color: AppColors.border.withValues(alpha: 0.25),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.medicalGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.medicalGreen.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total net à payer :',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.medicalGreen,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text(
                          '${_preview!.netAmount.toInt()} Frs',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.medicalGreen,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CompactTextFormField(
                          key: const ValueKey('cashdesk-payment-amount'),
                          controller: _amountController,
                          label: 'Montant encaissé',
                          icon: Icons.payments_rounded,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          helperText: 'Montant payé par le patient (pré-rempli)',
                          validator: _amountValidator,
                        ),
                        const SizedBox(height: 8),
                        _buildPaymentFeedback(),
                        const SizedBox(height: 8),
                        CompactDropdownField(
                          label: 'Mode de paiement',
                          value: _mode.label,
                          items: _PaymentModeOption.labels,
                          icon: Icons.account_balance_wallet_rounded,
                          onChanged: (value) {
                            setState(() => _mode = _PaymentModeOption.fromLabel(value));
                          },
                        ),
                        const SizedBox(height: 8),
                        CompactTextFormField(
                          key: const ValueKey('cashdesk-payment-reference'),
                          controller: _referenceController,
                          label: 'Référence / reçu',
                          icon: Icons.confirmation_number_rounded,
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          key: const ValueKey('cashdesk-payment-submit'),
                          onPressed: _submit,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Encaisser et orienter'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            backgroundColor: AppColors.medicalGreen,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _amountValidator(String? value) {
    final amount = _parseAmount(value);
    if (amount == null || amount <= 0) {
      return 'Montant requis';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      CreateCashDeskPaymentPayload(
        amount: _parseAmount(_amountController.text)!,
        mode: _mode.apiValue,
        reference: _referenceController.text,
      ),
    );
  }

  double? _parseAmount(String? value) {
    if (value == null) {
      return null;
    }
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  Widget _buildPaymentFeedback() {
    if (_preview == null) return const SizedBox.shrink();
    
    final enteredText = _amountController.text.trim();
    if (enteredText.isEmpty) return const SizedBox.shrink();
    
    final enteredAmount = double.tryParse(enteredText.replaceAll(',', '.')) ?? 0;
    final netAmount = _preview!.netAmount;
    
    if (enteredAmount == netAmount) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.medicalGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Compte juste - Paiement complet',
          style: TextStyle(
            color: AppColors.medicalGreen,
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      );
    } else if (enteredAmount < netAmount) {
      final remainder = netAmount - enteredAmount;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Paiement partiel - Reste à payer : ${remainder.toInt()} FCFA',
          style: const TextStyle(
            color: AppColors.warning,
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      );
    } else {
      final change = enteredAmount - netAmount;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Sur-paiement - Monnaie à rendre : ${change.toInt()} FCFA',
          style: const TextStyle(
            color: AppColors.info,
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      );
    }
  }
}

enum _PaymentModeOption {
  cash('Espèces', 'CASH'),
  mobileMoney('Mobile Money', 'MOBILE_MONEY'),
  card('Carte bancaire', 'CARD'),
  bankTransfer('Virement', 'BANK_TRANSFER');

  const _PaymentModeOption(this.label, this.apiValue);

  final String label;
  final String apiValue;

  static List<String> get labels =>
      values.map((option) => option.label).toList(growable: false);

  static _PaymentModeOption fromLabel(String? label) {
    return values.firstWhere(
      (option) => option.label == label,
      orElse: () => _PaymentModeOption.cash,
    );
  }
}
