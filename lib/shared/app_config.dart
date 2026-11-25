enum AppEnv { dev, staging, prod }

class AppConfig {
  AppConfig._();

  static const String _rawEnv = String.fromEnvironment('ENV', defaultValue: 'dev');

  static AppEnv get env {
    switch (_rawEnv.toLowerCase()) {
      case 'prod':
      case 'production':
        return AppEnv.prod;
      case 'staging':
        return AppEnv.staging;
      default:
        return AppEnv.dev;
    }
  }

  static bool get isProduction => env == AppEnv.prod;

  /// Background duration after which PIN-locked sessions re-lock on resume.
  static const Duration autoLockGracePeriod = Duration(minutes: 2);
}
