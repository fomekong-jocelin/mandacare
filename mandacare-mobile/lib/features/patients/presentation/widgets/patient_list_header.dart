import 'package:flutter/material.dart';

import '../../../../shared/presentation/widgets/feature_header.dart';
import '../../../../shared/presentation/widgets/compact_form_field.dart';

class PatientListHeader extends StatelessWidget {
  const PatientListHeader({
    required this.searchController,
    required this.onSearchChanged,
    required this.onAddPressed,
    super.key,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return FeatureHeader(
      title: 'Patients',
      subtitle: 'Dossiers actifs et file du jour',
      actionIcon: Icons.person_add_alt_1_rounded,
      actionTooltip: 'Ajouter un patient',
      onActionPressed: onAddPressed,
      bottom: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        textInputAction: TextInputAction.search,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15),
        decoration: compactInputDecoration(
          context,
          hintText: 'Rechercher un patient',
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
        ),
      ),
    );
  }
}
