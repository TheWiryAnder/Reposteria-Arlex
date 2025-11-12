import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'configuracion/app_config.dart';
import 'providers/auth_provider_simple.dart';
import 'pantallas/auth/login_vista.dart';
import 'pantallas/auth/registro_vista.dart';
import 'pantallas/auth/recuperar_password_vista.dart';
import 'pantallas/principal/main_app_view.dart';
import 'pantallas/dashboards/admin_dashboard.dart';
import 'pantallas/dashboards/client_dashboard.dart';
import 'servicios/informacion_negocio_service.dart';
import 'modelos/informacion_negocio_modelo.dart';

class InformacionNegocioProvider extends ChangeNotifier {
  static InformacionNegocioProvider? _instance;
  static InformacionNegocioProvider get instance =>
      _instance ??= InformacionNegocioProvider._();

  InformacionNegocioProvider._() {
    _inicializar();
  }

  // Valor por defecto compatible con el modelo completo
  InformacionNegocio _info = InformacionNegocio.fromMap({});
  bool _cargando = true;
  String? _error;

  InformacionNegocio get info => _info;
  bool get cargando => _cargando;
  String? get error => _error;

  // Inicializar y cargar datos desde Firebase
  Future<void> _inicializar() async {
    print('🚀 Iniciando carga de información del negocio...');
    try {
      _cargando = true;
      notifyListeners();

      // Usar el servicio de Firebase para cargar información
      final servicio = InformacionNegocioService();
      print('📡 Conectando con Firebase...');

      // Intentar cargar datos desde Firebase
      final datos = await servicio.obtenerInformacion();
      print(
        '📥 Respuesta de Firebase recibida: ${datos != null ? "Datos encontrados" : "No hay datos"}',
      );

      if (datos != null) {
        print('✅ Parseando datos de Firebase...');
        _info = InformacionNegocio.fromMap(datos);
        _error = null;
        print('✅ Información del negocio cargada: ${_info.galeria.nombre}');
      } else {
        // Si no hay datos en Firebase, mantener valores por defecto
        _error =
            'No se encontró información en Firebase. Usando valores por defecto.';
        print('⚠️ $_error');
      }
    } catch (e, stackTrace) {
      _error = 'Error al cargar información: $e';
      print('❌ Error al cargar información del negocio: $e');
      print('Stack trace: $stackTrace');
      // Mantener valores por defecto en caso de error
    } finally {
      _cargando = false;
      print('✅ Carga finalizada. Estado: ${_error ?? "OK"}');
      notifyListeners();
    }
  }

  // Recargar información desde Firebase
  Future<void> recargar() async {
    await _inicializar();
  }

  Future<void> actualizarInformacion(InformacionNegocio nuevaInfo) async {
    try {
      print('💾 Guardando información en Firebase...');

      // Actualizar primero en memoria (para UI inmediata)
      _info = nuevaInfo;
      notifyListeners();

      // Guardar en Firebase usando toFirestore()
      await FirebaseFirestore.instance
          .collection('informacion_negocio')
          .doc('config')
          .set(nuevaInfo.toFirestore());

      print('✅ Información guardada en Firebase exitosamente');

      // Recargar desde Firebase para asegurar sincronización
      await recargar();
    } catch (e) {
      print('❌ Error al guardar en Firebase: $e');
      _error = 'Error al guardar: $e';
      notifyListeners();
      rethrow;
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configurar Firestore para mejor manejo de errores
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB8956C), // Café/Dorado del logo
          primary: const Color(0xFFB8956C), // Café/Dorado principal
          secondary: const Color(0xFFD4A574), // Dorado claro
          surface: const Color(0xFFFFF5F0), // Beige muy claro
          brightness: Brightness.light,
        ),
        primaryColor: const Color(0xFFB8956C), // Café/Dorado del logo
        scaffoldBackgroundColor: const Color(0xFFFFFAF5), // Fondo beige muy suave
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
          backgroundColor: Color(0xFFB8956C), // Café/Dorado del logo
          foregroundColor: Colors.white, // Texto blanco para buen contraste
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF8BBD0), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      // TEMPORAL: Comentado después de inicializar datos
      //home: const FirebaseInitRunner(), // Ya no es necesario
      home:
          const AuthenticationWrapper(), // ORIGINAL: Restaurado después de inicializar
      routes: {
        '/login': (context) => const LoginVista(),
        '/register': (context) => const RegistroVista(),
        '/forgot-password': (context) => const RecuperarPasswordVista(),
        '/home': (context) => const MainAppView(),
        '/admin/dashboard': (context) => const AdminDashboard(),
        '/client/dashboard': (context) => const ClientDashboard(),
      },
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Solo inicializar si está en estado inicial
    if (AuthProvider.instance.authState == AuthState.initial) {
      await AuthProvider.instance.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthProvider.instance,
      builder: (context, child) {
        final authProvider = AuthProvider.instance;

        switch (authProvider.authState) {
          case AuthState.initial:
          case AuthState.loading:
            return const LoadingScreen();

          case AuthState.authenticated:
            if (authProvider.needsVerification) {
              return const EmailVerificationScreen();
            }
            return const MainAppView();

          case AuthState.unauthenticated:
          case AuthState.error:
            return const MainAppView(); // Permitir acceso sin login
        }
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Icon(Icons.cake, size: 80, color: Colors.white),
              SizedBox(height: 20),
              Text(
                AppConfig.appName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                'Cargando...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar Email'),
        actions: [
          TextButton(
            onPressed: () async {
              authProvider.logout();
              await Future.delayed(const Duration(milliseconds: 300));
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MainAppView()),
                  (route) => false,
                );
              }
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              'Verifica tu email',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'Hemos enviado un enlace de verificación a:\n${authProvider.currentUser?.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // TODO: Implementar reenvío de email de verificación
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Center(
                      child: Text('Email de verificación reenviado'),
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.only(
                      bottom: MediaQuery.of(context).size.height - 100,
                      left: 20,
                      right: 20,
                    ),
                  ),
                );
              },
              child: const Text('Reenviar Email'),
            ),
          ],
        ),
      ),
    );
  }
}
