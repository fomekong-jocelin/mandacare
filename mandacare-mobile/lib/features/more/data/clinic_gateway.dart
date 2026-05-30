import '../../../app/api/api_client.dart';
import '../../auth/domain/auth_session.dart';

class ClinicSettings {
  const ClinicSettings({
    required this.name,
    required this.slogan,
    required this.city,
  });

  final String name;
  final String slogan;
  final String city;

  factory ClinicSettings.fromJson(Map<String, dynamic> json) {
    return ClinicSettings(
      name: json['name'] as String? ?? '',
      slogan: json['slogan'] as String? ?? '',
      city: json['city'] as String? ?? '',
    );
  }
}

abstract class ClinicGateway {
  Future<ClinicSettings> getSettings({required AuthSession session});
}

class BackendClinicGateway implements ClinicGateway {
  const BackendClinicGateway(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<ClinicSettings> getSettings({required AuthSession session}) async {
    final json = await apiClient.getJson(
      '/settings/center',
      token: session.accessToken,
    );
    return ClinicSettings.fromJson(json);
  }
}

class FakeClinicGateway implements ClinicGateway {
  const FakeClinicGateway();

  @override
  Future<ClinicSettings> getSettings({required AuthSession session}) async {
    return const ClinicSettings(
      name: "Cabinet de Soins Manda Nsappe",
      slogan: "Soigner mieux, gérer simplement",
      city: "Logbessou",
    );
  }
}
