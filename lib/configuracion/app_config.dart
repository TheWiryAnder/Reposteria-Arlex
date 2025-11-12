class AppConfig {
  static const String appName = 'Repostería Arlex';
  static const String appVersion = '1.0.0';

  // Configuración de Firebase
  static const String firebaseProjectId = 'reposteria-arlex';
  static const String firebaseApiKey = 'YOUR_API_KEY_HERE';
  static const String firebaseAppId = 'YOUR_APP_ID_HERE';
  static const String firebaseMessagingSenderId = 'YOUR_MESSAGING_SENDER_ID_HERE';

  // Configuración de API
  static const String baseApiUrl = 'https://api.reposteriaarlex.com';
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;

  // Configuración de caché
  static const int cacheExpirationMinutes = 30;
  static const int maxCacheSize = 100; // MB

  // Configuración de paginación
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Configuración de imágenes
  static const int maxImageSizeMB = 5;
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  static const int imageQuality = 85;

  // Configuración de autenticación
  static const int sessionTimeoutMinutes = 60;
  static const int maxLoginAttempts = 5;
  static const int lockoutDurationMinutes = 15;

  // Configuración de notificaciones
  static const bool enablePushNotifications = true;
  static const bool enableEmailNotifications = true;

  // Configuración de debugging
  static const bool enableLogging = true;
  static const bool enableCrashReporting = true;

  // URLs importantes
  static const String privacyPolicyUrl = 'https://reposteriaarlex.com/privacy';
  static const String termsOfServiceUrl = 'https://reposteriaarlex.com/terms';
  static const String supportEmail = 'soporte@reposteriaarlex.com';
  static const String supportPhone = '+57 300 123 4567';

  // Redes sociales
  static const String facebookUrl = 'https://facebook.com/reposteriaarlex';
  static const String instagramUrl = 'https://instagram.com/reposteriaarlex';
  static const String whatsappUrl = 'https://wa.me/573001234567';

  // Configuración de pagos
  static const List<String> enabledPaymentMethods = [
    'efectivo',
    'transferencia',
    'tarjeta',
  ];
  static const double minOrderAmount = 20000; // COP
  static const double maxOrderAmount = 5000000; // COP

  // Configuración de entrega
  static const double deliveryRadius = 15; // km
  static const double deliveryFee = 5000; // COP
  static const double freeDeliveryThreshold = 100000; // COP

  // Configuración de horarios
  static const Map<String, Map<String, String>> businessHours = {
    'lunes': {'open': '08:00', 'close': '18:00'},
    'martes': {'open': '08:00', 'close': '18:00'},
    'miercoles': {'open': '08:00', 'close': '18:00'},
    'jueves': {'open': '08:00', 'close': '18:00'},
    'viernes': {'open': '08:00', 'close': '18:00'},
    'sabado': {'open': '08:00', 'close': '16:00'},
    'domingo': {'open': 'cerrado', 'close': 'cerrado'},
  };

  // Configuración de validaciones
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;
  static const int maxEmailLength = 100;

  // Configuración de productos
  static const int minProductNameLength = 3;
  static const int maxProductNameLength = 100;
  static const int maxProductDescriptionLength = 500;
  static const double minProductPrice = 1000; // COP
  static const double maxProductPrice = 10000000; // COP

  // Configuración de categorías
  static const List<String> defaultCategories = [
    'Tortas y Pasteles',
    'Postres Individuales',
    'Galletas y Bocaditos',
    'Panadería',
    'Helados y Fríos',
    'Bebidas',
    'Catering',
  ];

  // Configuración de ambiente
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  static bool get isDevelopment => !isProduction;

  // Configuración de features flags
  static const bool enableBiometricAuth = true;
  static const bool enableOfflineMode = false;
  static const bool enableAnalytics = true;
  static const bool enableA11y = true;

  // Configuración de idiomas soportados
  static const List<String> supportedLanguages = ['es', 'en'];
  static const String defaultLanguage = 'es';

  // Configuración de monedas
  static const String defaultCurrency = 'COP';
  static const String currencySymbol = '\$';

  // Método para obtener configuración por ambiente
  static Map<String, dynamic> getEnvironmentConfig() {
    if (isProduction) {
      return {
        'apiUrl': 'https://api.reposteriaarlex.com',
        'enableLogging': false,
        'enableCrashReporting': true,
      };
    } else {
      return {
        'apiUrl': 'https://dev-api.reposteriaarlex.com',
        'enableLogging': true,
        'enableCrashReporting': false,
      };
    }
  }
}