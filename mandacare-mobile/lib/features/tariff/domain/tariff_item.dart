/// Représente un item de grille tarifaire : examen labo ou acte de soin.
class TariffItem {
  const TariffItem({
    required this.id,
    required this.code,
    required this.name,
    this.category,
    required this.price,
    required this.active,
  });

  final String id;
  final String code;
  final String name;
  final String? category;
  final double price;
  final bool active;

  TariffItem copyWith({
    String? name,
    String? category,
    double? price,
    bool? active,
  }) {
    return TariffItem(
      id: id,
      code: code,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      active: active ?? this.active,
    );
  }
}
