class TariffPayload {
  const TariffPayload({
    required this.code,
    required this.name,
    this.category,
    required this.price,
  });

  final String code;
  final String name;
  final String? category;
  final double price;

  Map<String, dynamic> toCreateJson() {
    return {
      'code': code,
      'name': name,
      if (category != null && category!.isNotEmpty) 'category': category,
      'price': price,
    };
  }
}

class UpdateTariffPayload {
  const UpdateTariffPayload({
    required this.name,
    this.category,
    required this.price,
    required this.active,
  });

  final String name;
  final String? category;
  final double price;
  final bool active;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (category != null && category!.isNotEmpty) 'category': category,
      'price': price,
      'active': active,
    };
  }
}
