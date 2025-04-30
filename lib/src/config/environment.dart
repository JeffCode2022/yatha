import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  // Odoo API Configuration
  static String get apiUrl => dotenv.env['ODOO_API_URL'] ?? '';
  static String get dbName => dotenv.env['ODOO_DB_NAME'] ?? '';
  static String get staticPassword => dotenv.env['ODOO_STATIC_PASSWORD'] ?? '';

  // App Configuration
  static String get appName => dotenv.env['APP_NAME'] ?? 'Yatha App';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '0.1.0';
  static String get environment =>
      dotenv.env['APP_ENVIRONMENT'] ?? 'development';

  // API Endpoints
  static String get authEndpoint => '/api/roles/auth';
  static String get loanEndpoint => '/api/loan';
  static String get paymentEndpoint => '/api/payment';
  static String get kpiEndpoint => '/api/kpi';
  static String get clientEndpoint => '/api/client';

  // API Methods
  static String get searchReadMethod => 'search_read';
  static String get writeMethod => 'write';
  static String get createMethod => 'create';
  static String get unlinkMethod => 'unlink';

  // Models
  static String get loanManagementModel => 'loan.management';
  static String get loanPaymentModel => 'loan.payment';
  static String get partnerModel => 'res.partner';

  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
  }
}
