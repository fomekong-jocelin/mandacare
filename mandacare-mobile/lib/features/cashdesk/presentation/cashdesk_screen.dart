import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/layout/adaptive_layout.dart';
import '../../../shared/presentation/widgets/action_tile.dart';
import '../../../shared/presentation/widgets/feature_header.dart';
import '../../../shared/presentation/widgets/metric_strip.dart';

class CashDeskScreen extends StatelessWidget {
  const CashDeskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          FeatureHeader(
            title: 'Caisse',
            subtitle: 'Encaissements et reçus',
            actionIcon: Icons.add_card_rounded,
            actionTooltip: 'Nouvel encaissement',
            onActionPressed: () {},
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    14,
                    16,
                    AdaptiveLayout.bottomContentPadding(context),
                  ),
                  sliver: SliverList.list(
                    children: const [
                      _RevenueCard(),
                      SizedBox(height: 14),
                      MetricStrip(
                        items: [
                          MetricStripItem(
                            value: '12',
                            label: 'reçus',
                            color: AppColors.deepHealthBlue,
                          ),
                          MetricStripItem(
                            value: '42K',
                            label: 'reste dû',
                            color: AppColors.warning,
                          ),
                          MetricStripItem(
                            value: '98%',
                            label: 'traçabilité',
                            color: AppColors.medicalGreen,
                          ),
                        ],
                      ),
                      SizedBox(height: 18),
                      _SectionTitle(title: 'Actions rapides'),
                      SizedBox(height: 10),
                      _QuickCashGrid(),
                      SizedBox(height: 18),
                      _SectionTitle(title: 'Dernières opérations'),
                      SizedBox(height: 10),
                      _TransactionTile(
                        patient: 'Awa Diop',
                        label: 'Consultation + échographie',
                        amount: '35 000 FCFA',
                        time: '09:02',
                        paid: true,
                      ),
                      SizedBox(height: 10),
                      _TransactionTile(
                        patient: 'Mamadou Sarr',
                        label: 'Consultation médicale',
                        amount: '15 000 FCFA',
                        time: '09:24',
                        paid: true,
                      ),
                      SizedBox(height: 10),
                      _TransactionTile(
                        patient: 'Ibrahima Diallo',
                        label: 'Examens labo',
                        amount: '22 000 FCFA',
                        time: '09:41',
                        paid: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F0DE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.premiumGold.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Aujourd'hui",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '185 000',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'FCFA encaissés',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.premiumGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: AppColors.premiumGold,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickCashGrid extends StatelessWidget {
  const _QuickCashGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        return GridView.builder(
          itemCount: _items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 122,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) => _items[index],
        );
      },
    );
  }

  static const _items = [
    ActionTile(
      icon: Icons.price_check_rounded,
      title: 'Encaisser',
      subtitle: 'Paiement patient',
    ),
    ActionTile(
      icon: Icons.receipt_rounded,
      title: 'Facture',
      subtitle: 'Créer un reçu',
    ),
    ActionTile(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Dépense',
      subtitle: 'Sortie de caisse',
    ),
    ActionTile(
      icon: Icons.summarize_rounded,
      title: 'Journal',
      subtitle: 'Clôture du jour',
    ),
  ];
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppColors.deepHealthBlue,
        fontSize: 15.5,
        fontWeight: FontWeight.w700,
        height: 1.12,
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.patient,
    required this.label,
    required this.amount,
    required this.time,
    required this.paid,
  });

  final String patient;
  final String label;
  final String amount;
  final String time;
  final bool paid;

  @override
  Widget build(BuildContext context) {
    final color = paid ? AppColors.success : AppColors.warning;
    return ActionTile(
      icon: paid ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
      title: patient,
      subtitle: '$label · $time',
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            amount,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            paid ? 'Payé' : 'À solder',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
