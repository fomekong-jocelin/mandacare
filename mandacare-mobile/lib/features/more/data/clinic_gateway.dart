import '../../../app/api/api_client.dart';
import '../../auth/domain/auth_session.dart';

class ClinicSettings {
  const ClinicSettings({
    required this.name,
    required this.slogan,
    this.phone,
    this.email,
    required this.city,
    this.address,
    this.poBox,
    this.rccm,
    this.taxpayerNumber,
  });

  final String name;
  final String slogan;
  final String? phone;
  final String? email;
  final String city;
  final String? address;
  final String? poBox;
  final String? rccm;
  final String? taxpayerNumber;

  factory ClinicSettings.fromJson(Map<String, dynamic> json) {
    return ClinicSettings(
      name: json['name'] as String? ?? '',
      slogan: json['slogan'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      city: json['city'] as String? ?? '',
      address: json['address'] as String?,
      poBox: json['poBox'] as String?,
      rccm: json['rccm'] as String?,
      taxpayerNumber: json['taxpayerNumber'] as String?,
    );
  }
}

abstract class ClinicGateway {
  Future<ClinicSettings> getSettings({required AuthSession session});
  Future<ClinicSettings> updateSettings({
    required AuthSession session,
    required ClinicSettings settings,
  });
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

  @override
  Future<ClinicSettings> updateSettings({
    required AuthSession session,
    required ClinicSettings settings,
  }) async {
    final json = await apiClient.putJson('/settings/center', {
      'name': settings.name,
      'slogan': settings.slogan,
      'phone': settings.phone,
      'email': settings.email,
      'city': settings.city,
      'address': settings.address,
      'poBox': settings.poBox,
      'rccm': settings.rccm,
      'taxpayerNumber': settings.taxpayerNumber,
    }, token: session.accessToken);
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
      phone: "+237 691 501 780",
      city: "Logbessou",
      address: "Logbessou, Douala",
    );
  }

  @override
  Future<ClinicSettings> updateSettings({
    required AuthSession session,
    required ClinicSettings settings,
  }) async {
    return settings;
  }
}
