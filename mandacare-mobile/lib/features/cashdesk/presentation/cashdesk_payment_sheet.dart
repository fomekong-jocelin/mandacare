import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/widgets/compact_form_field.dart';
import '../../patients/data/patient_gateway.dart';

Future<CreateCashDeskPaymentPayload?> showCashDeskPaymentSheet(
  BuildContext context, {
  required String patientName,
  required String targetLabel,
}) {
  return showModalBottomSheet<CreateCashDeskPaymentPayload>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _CashDeskPaymentSheet(
        patientName: patientName,
        targetLabel: targetLabel,
      );
    },
  );
}

class _CashDeskPaymentSheet extends StatefulWidget {
  const _CashDeskPaymentSheet({
    required this.patientName,
    required this.targetLabel,
  });

  final String patientName;
  final String targetLabel;

  @override
  State<_CashDeskPaymentSheet> createState() => _CashDeskPaymentSheetState();
}

class _CashDeskPaymentSheetState extends State<_CashDeskPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  _PaymentModeOption _mode = _PaymentModeOption.cash;

  @override
  void dispose() {
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
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
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
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.deepHealthBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Orientation ${widget.targetLabel}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                CompactTextFormField(
                  key: const ValueKey('cashdesk-payment-amount'),
                  controller: _amountController,
                  label: 'Montant encaissé',
                  icon: Icons.payments_rounded,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  helperText: 'Montant payé par le patient',
                  validator: _amountValidator,
                ),
                const SizedBox(height: 12),
                CompactDropdownField(
                  label: 'Mode de paiement',
                  value: _mode.label,
                  items: _PaymentModeOption.labels,
                  icon: Icons.account_balance_wallet_rounded,
                  onChanged: (value) {
                    setState(() => _mode = _PaymentModeOption.fromLabel(value));
                  },
                ),
                const SizedBox(height: 12),
                CompactTextFormField(
                  key: const ValueKey('cashdesk-payment-reference'),
                  controller: _referenceController,
                  label: 'Référence / reçu',
                  icon: Icons.confirmation_number_rounded,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 16),
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
