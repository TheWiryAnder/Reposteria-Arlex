# Guía de Integración Firebase - Paso a Paso

## 📋 Estado Actual

✅ **Completado:**
1. Dependencias agregadas en `pubspec.yaml`
2. Servicios de Firebase creados:
   - `firebase_auth_service.dart` - Autenticación
   - `firebase_firestore_service.dart` - Operaciones CRUD genéricas
   - `productos_service.dart` - Gestión de productos
   - `pedidos_service.dart` - Gestión de pedidos
   - `carrito_firebase_service.dart` - Carrito sincronizado
   - `informacion_negocio_service.dart` - Info del negocio
3. Modelo `CarritoModelo` actualizado para soportar Firebase

## 🚀 Pasos para Completar la Integración

### Paso 1: Instalar Dependencias

```bash
cd "c:\Users\USUARIO\Documents\CLASES 2025-2\INGENIERIA DE SOFTWARE 2\Project\reposteria_arlex"
flutter pub get
```

### Paso 2: Configurar Firebase en el Proyecto

#### Opción A: Usar FlutterFire CLI (Recomendado)

```bash
# 1. Instalar Firebase CLI
npm install -g firebase-tools

# 2. Instalar FlutterFire CLI
dart pub global activate flutterfire_cli

# 3. Iniciar sesión
firebase login

# 4. Configurar el proyecto
flutterfire configure
```

Esto creará automáticamente el archivo `lib/firebase_options.dart`.

#### Opción B: Configuración Manual

Si FlutterFire CLI no funciona, crea manualmente `lib/firebase_options.dart`:

```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'TU_API_KEY',
    authDomain: 'tu-proyecto.firebaseapp.com',
    projectId: 'tu-proyecto',
    storageBucket: 'tu-proyecto.appspot.com',
    messagingSenderId: '123456789',
    appId: '1:123456789:web:abcdef',
    measurementId: 'G-XXXXXXXXXX',
  );

  // Agrega las opciones para otras plataformas si es necesario
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'TU_ANDROID_API_KEY',
    appId: '1:123456789:android:abcdef',
    messagingSenderId: '123456789',
    projectId: 'tu-proyecto',
    storageBucket: 'tu-proyecto.appspot.com',
  );

  // ... iOS, macOS, Windows
}
```

Obtén estos valores desde Firebase Console → Configuración del proyecto → Tu app web.

### Paso 3: Actualizar main.dart

Actualiza tu `lib/main.dart` para inicializar Firebase:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'configuracion/app_config.dart';
import 'providers/auth_provider_simple.dart';
import 'providers/carrito_provider.dart';
import 'pantallas/auth/login_vista.dart';
import 'pantallas/auth/registro_vista.dart';
import 'pantallas/auth/recuperar_password_vista.dart';
import 'pantallas/principal/main_app_view.dart';
import 'pantallas/dashboards/admin_dashboard.dart';
import 'pantallas/dashboards/client_dashboard.dart';

void main() async {
  // Asegurar que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider de autenticación
        ChangeNotifierProvider(
          create: (_) => AuthProvider.instance,
        ),
        // Provider del carrito
        ChangeNotifierProvider(
          create: (_) => CarritoProvider.instance,
        ),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppConfig.primaryColor,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const MainAppView(),
        routes: {
          '/login': (context) => const LoginVista(),
          '/register': (context) => const RegistroVista(),
          '/forgot-password': (context) => const RecuperarPasswordVista(),
          '/admin/dashboard': (context) => const AdminDashboard(),
          '/client/dashboard': (context) => const ClientDashboard(),
        },
      ),
    );
  }
}
```

### Paso 4: Migrar AuthProvider a Firebase

Actualiza `lib/providers/auth_provider_simple.dart` para usar el servicio de Firebase:

```dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../servicios/firebase_auth_service.dart';

enum AuthState {
  loading,
  authenticated,
  unauthenticated,
  needsVerification
}

class Usuario {
  final String uid;
  final String nombre;
  final String email;
  final String rol;

  Usuario({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  String get iniciales {
    final partes = nombre.split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';
  }
}

class AuthProvider extends ChangeNotifier {
  static final AuthProvider _instance = AuthProvider._internal();
  factory AuthProvider() => _instance;
  static AuthProvider get instance => _instance;

  AuthProvider._internal() {
    _init();
  }

  final FirebaseAuthService _authService = FirebaseAuthService();

  AuthState _authState = AuthState.loading;
  Usuario? _currentUser;

  AuthState get authState => _authState;
  Usuario? get currentUser => _currentUser;

  void _init() {
    // Escuchar cambios de autenticación
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _authState = AuthState.unauthenticated;
      _currentUser = null;
    } else {
      // Obtener datos del usuario desde Firestore
      final userData = await _authService.obtenerDatosUsuario(firebaseUser.uid);

      if (userData != null) {
        _currentUser = Usuario(
          uid: firebaseUser.uid,
          nombre: userData['nombre'] ?? 'Usuario',
          email: userData['email'] ?? firebaseUser.email ?? '',
          rol: userData['rol'] ?? 'cliente',
        );

        if (firebaseUser.emailVerified) {
          _authState = AuthState.authenticated;
        } else {
          _authState = AuthState.needsVerification;
        }
      }
    }

    notifyListeners();
  }

  // Registrar nuevo usuario
  Future<Map<String, dynamic>> registrar({
    required String nombre,
    required String email,
    required String password,
    required String telefono,
    String? direccion,
  }) async {
    _authState = AuthState.loading;
    notifyListeners();

    final result = await _authService.registrarUsuario(
      nombre: nombre,
      email: email,
      password: password,
      telefono: telefono,
      direccion: direccion,
    );

    if (!result['success']) {
      _authState = AuthState.unauthenticated;
      notifyListeners();
    }

    return result;
  }

  // Iniciar sesión
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    _authState = AuthState.loading;
    notifyListeners();

    final result = await _authService.iniciarSesion(
      email: email,
      password: password,
    );

    if (!result['success']) {
      _authState = AuthState.unauthenticated;
      notifyListeners();
    }

    return result;
  }

  // Cerrar sesión
  Future<void> logout() async {
    await _authService.cerrarSesion();
  }

  // Verificar permisos
  bool hasPermission(String permission) {
    if (_currentUser == null) return false;

    final rol = _currentUser!.rol;

    switch (permission) {
      case 'admin_access':
        return rol == 'admin';
      case 'employee_access':
        return rol == 'empleado' || rol == 'admin';
      case 'client_access':
        return rol == 'cliente' || rol == 'admin' || rol == 'empleado';
      default:
        return false;
    }
  }
}
```

### Paso 5: Actualizar CarritoProvider para Firebase

Modifica `lib/providers/carrito_provider.dart` para sincronizar con Firebase:

```dart
import 'package:flutter/foundation.dart';
import '../modelos/producto_modelo.dart';
import '../modelos/carrito_modelo.dart';
import '../servicios/carrito_firebase_service.dart';
import 'auth_provider_simple.dart';

class CarritoProvider extends ChangeNotifier {
  static final CarritoProvider _instance = CarritoProvider._internal();
  factory CarritoProvider() => _instance;
  static CarritoProvider get instance => _instance;

  CarritoProvider._internal();

  final CarritoFirebaseService _carritoService = CarritoFirebaseService();
  final AuthProvider _authProvider = AuthProvider.instance;

  CarritoModelo _carrito = CarritoModelo(items: []);

  CarritoModelo get carrito => _carrito;
  double get total => _carrito.total;
  int get cantidadTotal => _carrito.cantidadTotal;
  bool get estaVacio => _carrito.estaVacio;

  // Agregar producto
  Future<void> agregarProducto(
    ProductoModelo producto, {
    int cantidad = 1,
    String? notas,
  }) async {
    final usuarioId = _authProvider.currentUser?.uid;

    if (usuarioId == null) {
      // Usuario no autenticado - solo local
      _agregarLocal(producto, cantidad, notas);
      return;
    }

    // Usuario autenticado - sincronizar con Firebase
    await _carritoService.agregarProducto(
      usuarioId: usuarioId,
      producto: producto,
      cantidad: cantidad,
      notasEspeciales: notas,
    );

    await _cargarCarrito();
  }

  // Eliminar producto
  Future<void> eliminarProducto(String productoId) async {
    final usuarioId = _authProvider.currentUser?.uid;

    if (usuarioId == null) {
      _eliminarLocal(productoId);
      return;
    }

    await _carritoService.eliminarProducto(
      usuarioId: usuarioId,
      productoId: productoId,
    );

    await _cargarCarrito();
  }

  // Actualizar cantidad
  Future<void> actualizarCantidad(String productoId, int nuevaCantidad) async {
    final usuarioId = _authProvider.currentUser?.uid;

    if (usuarioId == null) {
      _actualizarCantidadLocal(productoId, nuevaCantidad);
      return;
    }

    await _carritoService.actualizarCantidad(
      usuarioId: usuarioId,
      productoId: productoId,
      nuevaCantidad: nuevaCantidad,
    );

    await _cargarCarrito();
  }

  // Limpiar carrito
  Future<void> limpiarCarrito() async {
    final usuarioId = _authProvider.currentUser?.uid;

    if (usuarioId == null) {
      _carrito = CarritoModelo(items: []);
      notifyListeners();
      return;
    }

    await _carritoService.limpiarCarrito(usuarioId);
    await _cargarCarrito();
  }

  // Cargar carrito desde Firebase
  Future<void> _cargarCarrito() async {
    final usuarioId = _authProvider.currentUser?.uid;

    if (usuarioId == null) return;

    final carritoFirebase = await _carritoService.obtenerCarrito(usuarioId);

    if (carritoFirebase != null) {
      _carrito = carritoFirebase;
      notifyListeners();
    }
  }

  // Métodos locales (para usuarios no autenticados)
  void _agregarLocal(ProductoModelo producto, int cantidad, String? notas) {
    final items = List<ItemCarrito>.from(_carrito.items);
    final indice = items.indexWhere((item) => item.producto.id == producto.id);

    if (indice != -1) {
      items[indice].cantidad += cantidad;
    } else {
      items.add(ItemCarrito(
        producto: producto,
        cantidad: cantidad,
        notasEspeciales: notas,
      ));
    }

    _carrito = CarritoModelo(items: items);
    notifyListeners();
  }

  void _eliminarLocal(String productoId) {
    final items = _carrito.items.where((item) => item.producto.id != productoId).toList();
    _carrito = CarritoModelo(items: items);
    notifyListeners();
  }

  void _actualizarCantidadLocal(String productoId, int nuevaCantidad) {
    if (nuevaCantidad <= 0) {
      _eliminarLocal(productoId);
      return;
    }

    final items = List<ItemCarrito>.from(_carrito.items);
    final indice = items.indexWhere((item) => item.producto.id == productoId);

    if (indice != -1) {
      items[indice].cantidad = nuevaCantidad;
      _carrito = CarritoModelo(items: items);
      notifyListeners();
    }
  }
}
```

### Paso 6: Probar la Conexión

Ejecuta la aplicación:

```bash
flutter run -d chrome
```

Si todo está bien, deberías ver la aplicación cargando sin errores.

### Paso 7: Crear Usuario Admin Inicial

Después de ejecutar la app, ve a Firebase Console:

1. **Authentication → Users → Add user**
   - Email: admin@reposteriaarlex.com
   - Password: (tu contraseña)
   - Copia el UID generado

2. **Firestore Database → Start collection**
   - Collection ID: `usuarios`
   - Document ID: (pega el UID)
   - Campos:
     ```
     id: (UID)
     nombre: "Administrador"
     email: "admin@reposteriaarlex.com"
     telefono: "+573001234567"
     rol: "admin"
     estado: "activo"
     emailVerificado: true
     fechaCreacion: (timestamp now)
     fechaActualizacion: (timestamp now)
     ultimoAcceso: (timestamp now)
     preferencias: { notificaciones: true, newsletter: false }
     ```

3. **Crear información del negocio**
   - Collection: `informacion_negocio`
   - Document ID: `config`
   - Usa el servicio `InformacionNegocioService().crearInformacionInicial()`

### Paso 8: Verificación Final

✅ Checklist de verificación:

- [ ] `flutter pub get` ejecutado sin errores
- [ ] Firebase inicializado en `main.dart`
- [ ] `firebase_options.dart` creado
- [ ] App carga sin errores
- [ ] Puedes iniciar sesión
- [ ] Puedes registrar usuarios
- [ ] El carrito sincroniza con Firebase
- [ ] Reglas de seguridad configuradas en Firebase Console

## 🔧 Troubleshooting

### Error: "Firebase options not configured"
- Verifica que `firebase_options.dart` existe
- Asegúrate de haber ejecutado `flutterfire configure`

### Error: "Permission denied"
- Verifica las reglas de seguridad en Firebase Console
- Asegúrate de que el usuario esté autenticado

### Error: "Module not found"
- Ejecuta `flutter clean`
- Ejecuta `flutter pub get`
- Reinicia el servidor con `flutter run`

## 📚 Próximos Pasos

Una vez completada la integración básica:

1. Migrar ProductsScreen para cargar productos desde Firebase
2. Implementar pantallas de administración de productos
3. Configurar Firebase Storage para imágenes
4. Implementar notificaciones push (opcional)
5. Configurar Firebase Analytics (opcional)

## 🎯 Servicios Disponibles

Todos los servicios están en `lib/servicios/`:

- `firebase_auth_service.dart` - Autenticación completa
- `firebase_firestore_service.dart` - CRUD genérico
- `productos_service.dart` - Gestión de productos
- `pedidos_service.dart` - Gestión de pedidos
- `carrito_firebase_service.dart` - Carrito sincronizado
- `informacion_negocio_service.dart` - Info del negocio

Ejemplo de uso:

```dart
// Obtener todos los productos
final productosService = ProductosService();
final productos = await productosService.obtenerTodosLosProductos();

// Stream de productos (tiempo real)
StreamBuilder<List<ProductoModelo>>(
  stream: productosService.streamProductos(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return ListView.builder(
        itemCount: snapshot.data!.length,
        itemBuilder: (context, index) {
          final producto = snapshot.data![index];
          return Text(producto.nombre);
        },
      );
    }
    return CircularProgressIndicator();
  },
)
```

---

**¡Firebase está listo para usarse! 🎉**
