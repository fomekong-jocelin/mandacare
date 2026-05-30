class ApiConfig {
  const ApiConfig._();

  static const baseUrl = String.fromEnvironment(
    'MANDACARE_API_BASE_URL',
    defaultValue: 'http://161.97.181.177:8082/api/v1',
  );
}
