import 'package:flutter/material.dart';

import '../../../patients/presentation/patient_filter.dart';
import 'quick_action_tile.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({
    required this.isTablet,
    required this.onCreatePatient,
    required this.onOpenPatients,
    required this.onOpenConsultations,
    required this.onOpenCashDesk,
    super.key,
  });

  final bool isTablet;
  final VoidCallback onCreatePatient;
  final ValueChanged<PatientFilter> onOpenPatients;
  final VoidCallback onOpenConsultations;
  final VoidCallback onOpenCashDesk;

  @override
  Widget build(BuildContext context) {
    final actions = _actions();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 4 : 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 62,
      ),
      itemBuilder: (context, index) => actions[index],
    );
  }

  List<QuickActionTile> _actions() {
    return [
      QuickActionTile(
        icon: Icons.person_add_alt_1_rounded,
        label: 'Patient',
        onTap: onCreatePatient,
      ),
      QuickActionTile(
        icon: Icons.add_box_rounded,
        label: 'Visite',
        onTap: () => onOpenPatients(PatientFilter.waiting),
      ),
      QuickActionTile(
        icon: Icons.receipt_long_rounded,
        label: 'Ordonnance',
        onTap: onOpenConsultations,
      ),
      QuickActionTile(
        icon: Icons.point_of_sale_rounded,
        label: 'Caisse',
        onTap: onOpenCashDesk,
      ),
    ];
  }
}
