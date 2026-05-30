import '../../../app/api/api_client.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/tariff_item.dart';
import '../domain/tariff_payload.dart';
import '../domain/tariff_type.dart';

abstract class TariffGateway {
  Future<List<TariffItem>> listItems({
    required AuthSession session,
    required TariffType type,
  });

  Future<TariffItem> createItem({
    required AuthSession session,
    required TariffType type,
    required TariffPayload payload,
  });

  Future<TariffItem> updateItem({
    required AuthSession session,
    required TariffType type,
    required String id,
    required UpdateTariffPayload payload,
  });
}

class BackendTariffGateway implements TariffGateway {
  const BackendTariffGateway(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<List<TariffItem>> listItems({
    required AuthSession session,
    required TariffType type,
  }) async {
    final response = await apiClient.getJsonList(
      '/tariff/${type.apiPath}',
      token: session.accessToken,
    );
    return response
        .whereType<Map<String, dynamic>>()
        .map(_itemFromJson)
        .toList(growable: false);
  }

  @override
  Future<TariffItem> createItem({
    required AuthSession session,
    required TariffType type,
    required TariffPayload payload,
  }) async {
    final response = await apiClient.postJson(
      '/tariff/${type.apiPath}',
      payload.toCreateJson(),
      token: session.accessToken,
    );
    return _itemFromJson(response);
  }

  @override
  Future<TariffItem> updateItem({
    required AuthSession session,
    required TariffType type,
    required String id,
    required UpdateTariffPayload payload,
  }) async {
    final response = await apiClient.patchJson(
      '/tariff/${type.apiPath}/$id',
      payload.toJson(),
      token: session.accessToken,
    );
    return _itemFromJson(response);
  }

  static TariffItem _itemFromJson(Map<String, dynamic> json) {
    return TariffItem(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      price: (json['price'] as num).toDouble(),
      active: json['active'] as bool,
    );
  }
}
