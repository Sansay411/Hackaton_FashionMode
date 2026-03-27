class AppConfig {
  AppConfig({
    required this.apiBaseUrl,
    required this.useMock,
    required this.syncIntervalSeconds,
  });

  factory AppConfig.fromEnvironment() {
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    );
    const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);
    const syncValue = String.fromEnvironment(
      'SYNC_INTERVAL_SECONDS',
      defaultValue: '2',
    );

    return AppConfig(
      apiBaseUrl: apiBaseUrl,
      useMock: useMock,
      syncIntervalSeconds: int.tryParse(syncValue) ?? 2,
    );
  }

  final String apiBaseUrl;
  final bool useMock;
  final int syncIntervalSeconds;
}
