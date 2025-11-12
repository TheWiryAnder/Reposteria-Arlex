// TODO: Uncomment when Firebase packages are added to pubspec.yaml
// import 'package:firebase_core/firebase_core.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'app_config.dart';

// Placeholder types until Firebase packages are properly configured
abstract class FirebaseApp {}

abstract class FirebaseOptions {
  const FirebaseOptions({
    required String apiKey,
    required String appId,
    required String messagingSenderId,
    required String projectId,
    String? authDomain,
    String? storageBucket,
  });
}

class _MockFirebaseOptions implements FirebaseOptions {
  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String? authDomain;
  final String? storageBucket;

  const _MockFirebaseOptions({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    this.authDomain,
    this.storageBucket,
  });
}

abstract class FirebaseFirestore {
  static FirebaseFirestore instanceFor({required FirebaseApp app}) {
    throw UnimplementedError('Firebase not configured');
  }

  set settings(Settings settings) {}
  Future<void> enableNetwork() async {}
  CollectionReference collection(String path) {
    throw UnimplementedError('Firebase not configured');
  }
}

abstract class FirebaseAuth {
  static FirebaseAuth instanceFor({required FirebaseApp app}) {
    throw UnimplementedError('Firebase not configured');
  }

  Future<void> setPersistence(Persistence persistence) async {}
  void setLanguageCode(String languageCode) {}
}

abstract class FirebaseStorage {
  static FirebaseStorage instanceFor({required FirebaseApp app}) {
    throw UnimplementedError('Firebase not configured');
  }

  Reference ref() {
    throw UnimplementedError('Firebase not configured');
  }
}

abstract class FirebaseMessaging {
  static FirebaseMessaging get instance {
    throw UnimplementedError('Firebase not configured');
  }

  static Stream<RemoteMessage> get onMessage {
    throw UnimplementedError('Firebase not configured');
  }

  static Stream<RemoteMessage> get onMessageOpenedApp {
    throw UnimplementedError('Firebase not configured');
  }

  Future<NotificationSettings> requestPermission({
    bool? alert,
    bool? announcement,
    bool? badge,
    bool? carPlay,
    bool? criticalAlert,
    bool? provisional,
    bool? sound,
  }) async {
    throw UnimplementedError('Firebase not configured');
  }

  Future<String?> getToken() async {
    throw UnimplementedError('Firebase not configured');
  }
}

class Firebase {
  static Future<FirebaseApp> initializeApp({FirebaseOptions? options}) async {
    throw UnimplementedError('Firebase not configured');
  }
}

abstract class CollectionReference {
  CollectionReference limit(int limit) {
    throw UnimplementedError('Firebase not configured');
  }
  Future<QuerySnapshot> get() async {
    throw UnimplementedError('Firebase not configured');
  }
}

abstract class QuerySnapshot {}

abstract class Reference {
  Reference child(String path) {
    throw UnimplementedError('Firebase not configured');
  }
}

abstract class Settings {
  const Settings({
    bool? persistenceEnabled,
    int? cacheSizeBytes,
  });

  static const int cacheSizeUnlimited = -1;
}

class _MockSettings implements Settings {
  final bool? persistenceEnabled;
  final int? cacheSizeBytes;

  const _MockSettings({
    this.persistenceEnabled,
    this.cacheSizeBytes,
  });
}

enum Persistence { local }

abstract class NotificationSettings {
  AuthorizationStatus get authorizationStatus;
}

enum AuthorizationStatus { authorized, denied, notDetermined, provisional }

abstract class RemoteMessage {
  RemoteNotification? get notification;
}

abstract class RemoteNotification {
  String? get title;
  String? get body;
}

class FirebaseConfig {
  static FirebaseApp? _app;
  static FirebaseFirestore? _firestore;
  static FirebaseAuth? _auth;
  static FirebaseStorage? _storage;
  static FirebaseMessaging? _messaging;

  // Configuración de Firestore
  static const String coleccionUsuarios = 'usuarios';
  static const String coleccionProductos = 'productos';
  static const String coleccionCategorias = 'categorias';
  static const String coleccionPedidos = 'pedidos';
  static const String coleccionCarritos = 'carritos';
  static const String coleccionPromociones = 'promociones';
  static const String coleccionTransacciones = 'transacciones';
  static const String coleccionNotificaciones = 'notificaciones';
  static const String coleccionConfiguracion = 'configuracion';

  // Configuración de Storage
  static const String bucketImagenesProductos = 'productos';
  static const String bucketImagenesUsuarios = 'usuarios';
  static const String bucketImagenesPromociones = 'promociones';
  static const String bucketDocumentos = 'documentos';

  // Inicializar Firebase
  static Future<void> initialize() async {
    try {
      _app = await Firebase.initializeApp(
        options: _getFirebaseOptions(),
      );

      // Configurar Firestore
      _firestore = FirebaseFirestore.instanceFor(app: _app!);
      await _configureFirestore();

      // Configurar Authentication
      _auth = FirebaseAuth.instanceFor(app: _app!);
      await _configureAuth();

      // Configurar Storage
      _storage = FirebaseStorage.instanceFor(app: _app!);

      // Configurar Messaging
      if (AppConfig.enablePushNotifications) {
        _messaging = FirebaseMessaging.instance;
        await _configureMessaging();
      }

      print('Firebase inicializado correctamente');
    } catch (e) {
      print('Error al inicializar Firebase: $e');
      rethrow;
    }
  }

  static FirebaseOptions _getFirebaseOptions() {
    return _MockFirebaseOptions(
      apiKey: AppConfig.firebaseApiKey,
      appId: AppConfig.firebaseAppId,
      messagingSenderId: AppConfig.firebaseMessagingSenderId,
      projectId: AppConfig.firebaseProjectId,
      authDomain: '${AppConfig.firebaseProjectId}.firebaseapp.com',
      storageBucket: '${AppConfig.firebaseProjectId}.appspot.com',
    );
  }

  static Future<void> _configureFirestore() async {
    if (_firestore == null) return;

    // Configurar settings
    _firestore!.settings = const _MockSettings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.cacheSizeUnlimited,
    );

    // Habilitar red si es necesario
    await _firestore!.enableNetwork();
  }

  static Future<void> _configureAuth() async {
    if (_auth == null) return;

    // Configurar persistencia
    await _auth!.setPersistence(Persistence.local);

    // Configurar idioma
    _auth!.setLanguageCode('es');
  }

  static Future<void> _configureMessaging() async {
    if (_messaging == null) return;

    // Solicitar permisos
    NotificationSettings settings = await _messaging!.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('Permisos de notificación: ${settings.authorizationStatus}');

    // Configurar token
    String? token = await _messaging!.getToken();
    print('Token FCM: $token');

    // Configurar listeners
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    print('Mensaje recibido en primer plano: ${message.notification?.title}');
    // TODO: Mostrar notificación local
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    print('App abierta desde notificación: ${message.notification?.title}');
    // TODO: Navegar a la pantalla correspondiente
  }

  // Getters para instancias
  static FirebaseFirestore get firestore {
    if (_firestore == null) {
      throw Exception('Firebase no ha sido inicializado. Llama a FirebaseConfig.initialize() primero.');
    }
    return _firestore!;
  }

  static FirebaseAuth get auth {
    if (_auth == null) {
      throw Exception('Firebase no ha sido inicializado. Llama a FirebaseConfig.initialize() primero.');
    }
    return _auth!;
  }

  static FirebaseStorage get storage {
    if (_storage == null) {
      throw Exception('Firebase no ha sido inicializado. Llama a FirebaseConfig.initialize() primero.');
    }
    return _storage!;
  }

  static FirebaseMessaging? get messaging => _messaging;

  // Utilidades para referencias comunes
  static CollectionReference get usuariosRef => firestore.collection(coleccionUsuarios);
  static CollectionReference get productosRef => firestore.collection(coleccionProductos);
  static CollectionReference get categoriasRef => firestore.collection(coleccionCategorias);
  static CollectionReference get pedidosRef => firestore.collection(coleccionPedidos);
  static CollectionReference get carritosRef => firestore.collection(coleccionCarritos);
  static CollectionReference get promocionesRef => firestore.collection(coleccionPromociones);
  static CollectionReference get transaccionesRef => firestore.collection(coleccionTransacciones);
  static CollectionReference get notificacionesRef => firestore.collection(coleccionNotificaciones);
  static CollectionReference get configuracionRef => firestore.collection(coleccionConfiguracion);

  // Utilidades para Storage
  static Reference get imagenesProductosRef => storage.ref().child(bucketImagenesProductos);
  static Reference get imagenesUsuariosRef => storage.ref().child(bucketImagenesUsuarios);
  static Reference get imagenesPromocionesRef => storage.ref().child(bucketImagenesPromociones);
  static Reference get documentosRef => storage.ref().child(bucketDocumentos);

  // Configuración de índices compuestos recomendados para Firestore
  static Map<String, List<Map<String, String>>> get indicesRecomendados => {
    coleccionProductos: [
      {'categoria': 'ascending', 'activo': 'ascending', 'fechaCreacion': 'descending'},
      {'precio': 'ascending', 'activo': 'ascending'},
      {'nombre': 'ascending', 'activo': 'ascending'},
    ],
    coleccionPedidos: [
      {'usuarioId': 'ascending', 'fechaCreacion': 'descending'},
      {'estado': 'ascending', 'fechaCreacion': 'descending'},
      {'fechaEntrega': 'ascending', 'estado': 'ascending'},
    ],
    coleccionTransacciones: [
      {'usuarioId': 'ascending', 'fecha': 'descending'},
      {'tipo': 'ascending', 'fecha': 'descending'},
      {'estado': 'ascending', 'fecha': 'descending'},
    ],
  };

  // Reglas de seguridad recomendadas
  static String get reglasSeguridad => '''
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Usuarios pueden leer y escribir sus propios datos
    match /usuarios/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Productos son de solo lectura para usuarios autenticados
    match /productos/{productId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
        exists(/databases/\$(database)/documents/usuarios/\$(request.auth.uid)) &&
        get(/databases/\$(database)/documents/usuarios/\$(request.auth.uid)).data.rol == 'admin';
    }

    // Pedidos solo para el usuario propietario o admin
    match /pedidos/{pedidoId} {
      allow read, write: if request.auth != null &&
        (resource.data.usuarioId == request.auth.uid ||
         get(/databases/\$(database)/documents/usuarios/\$(request.auth.uid)).data.rol == 'admin');
    }

    // Carritos solo para el usuario propietario
    match /carritos/{carritoId} {
      allow read, write: if request.auth != null &&
        resource.data.usuarioId == request.auth.uid;
    }
  }
}
''';

  // Configuración de Storage Security Rules
  static String get reglasStorage => '''
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Imágenes de productos solo admin puede escribir
    match /productos/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
        firestore.get(/databases/(default)/documents/usuarios/\$(request.auth.uid)).data.rol == 'admin';
    }

    // Imágenes de usuarios solo el propietario
    match /usuarios/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
''';

  // Método para verificar conexión
  static Future<bool> verificarConexion() async {
    try {
      await firestore.collection('test').limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Método para cleanup
  static Future<void> cleanup() async {
    // await _firestore?.terminate();
    // await _firestore?.clearPersistence();
    // TODO: Implement when Firebase is configured
  }
}