/// Type de grille tarifaire.
enum TariffType {
  /// Examens de laboratoire
  exam,

  /// Actes de soins / bénéfices
  benefit,
}

extension TariffTypeLabel on TariffType {
  String get label => switch (this) {
        TariffType.exam => 'Examens labo',
        TariffType.benefit => 'Actes de soins',
      };

  String get singularLabel => switch (this) {
        TariffType.exam => 'Examen labo',
        TariffType.benefit => 'Acte de soin',
      };

  String get apiPath => switch (this) {
        TariffType.exam => 'exams',
        TariffType.benefit => 'benefits',
      };
}
