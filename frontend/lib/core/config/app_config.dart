class AppConfig {
  AppConfig({
    required this.apiBaseUrl,
    required this.useMock,
    required this.syncIntervalSeconds,
    required this.enableRealtime,
  });

  factory AppConfig.fromEnvironment() {
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000',
    );
    const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);
    const syncValue = String.fromEnvironment(
      'SYNC_INTERVAL_SECONDS',
      defaultValue: '20',
    );
    const enableRealtime = bool.fromEnvironment(
      'ENABLE_REALTIME',
      defaultValue: true,
    );

    return AppConfig(
      apiBaseUrl: apiBaseUrl,
      useMock: useMock,
      syncIntervalSeconds: int.tryParse(syncValue) ?? 2,
      enableRealtime: enableRealtime,
    );
  }

  final String apiBaseUrl;
  final bool useMock;
  final int syncIntervalSeconds;
  final bool enableRealtime;
}
