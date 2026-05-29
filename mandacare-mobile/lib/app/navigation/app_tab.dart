import 'package:flutter/material.dart';

enum AppTab {
  home(Icons.home_rounded, 'Accueil'),
  patients(Icons.groups_rounded, 'Patients'),
  consultations(Icons.add_box_rounded, 'Consult.'),
  cashDesk(Icons.point_of_sale_rounded, 'Caisse'),
  more(Icons.more_horiz_rounded, 'Plus');

  const AppTab(this.icon, this.label);

  final IconData icon;
  final String label;
}
