import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../servicios/firebase_auth_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class UsuarioModelo {
  final String id;
  final String email;
  final String nombre;
  final String? telefono;
  final String? direccion;
  final String rol;
  final String estado;

  UsuarioModelo({
    required this.id,
    required this.email,
    required this.nombre,
    this.telefono,
    this.direccion,
    required this.rol,
    required this.estado,
  });

  String get iniciales {
    final parts = nombre.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';
  }

  String get rolDescripcion {
    switch (rol) {
      case 'admin':
        return 'Administrador';
      case 'empleado':
        return 'Empleado';
      case 'cliente':
        return 'Cliente';
      default:
        return 'Usuario';
    }
  }

  String get estadoDescripcion {
    switch (estado) {
      case 'activo':
        return 'Activo';
      case 'inactivo':
        return 'Inactivo';
      case 'suspendido':
        return 'Suspendido';
      default:
        return 'Desconocido';
    }
  }
}

class AuthProvider extends ChangeNotifier {
  static AuthProvider? _instance;
  static AuthProvider get instance => _instance ??= AuthProvider._();

  AuthProvider._();

  AuthState _authState = AuthState.initial;
  UsuarioModelo? _currentUser;
  String? _errorMessage;

  AuthState get authState => _authState;
  UsuarioModelo? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get needsVerification => false;

  Future<void> initialize() async {
    try {
      _authState = AuthState.loading;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 800));

      // Verificar si Firebase Auth tiene un usuario activo
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null) {
        // Hay un usuario autenticado, obtener sus datos
        print('AUTH INIT - Usuario de Firebase Auth detectado: ${firebaseUser.uid}');

        final firebaseAuth = FirebaseAuthService();
        final userData = await firebaseAuth.obtenerDatosUsuario(firebaseUser.uid);

        if (userData != null) {
          _currentUser = UsuarioModelo(
            id: firebaseUser.uid,  // Usar directamente el UID de Firebase Auth
            email: userData['email'] ?? firebaseUser.email ?? '',
            nombre: userData['nombre'] ?? 'Usuario',
            telefono: userData['telefono'],
            direccion: userData['direccion'],
            rol: userData['rol'] ?? 'cliente',
            estado: userData['estado'] ?? 'activo',
          );
          _authState = AuthState.authenticated;
          print('AUTH INIT - Usuario restaurado: ${_currentUser!.nombre}');
        } else {
          _authState = AuthState.unauthenticated;
          print('AUTH INIT - No se encontraron datos del usuario en Firestore');
        }
      } else {
        _authState = AuthState.unauthenticated;
        print('AUTH INIT - No hay usuario autenticado');
      }

      notifyListeners();
    } catch (e) {
      print('AUTH INIT ERROR: $e');
      _authState = AuthState.error;
      _errorMessage = 'Error al inicializar la aplicación';
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _authState = AuthState.loading;
    notifyListeners();

    try {
      // Usar Firebase Authentication en lugar de datos hardcoded
      final firebaseAuth = FirebaseAuthService();
      final result = await firebaseAuth.iniciarSesion(
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        // Obtener datos del usuario desde Firestore
        final userData = result['userData'] as Map<String, dynamic>?;

        if (userData != null) {
          _currentUser = UsuarioModelo(
            id: userData['id'] ?? result['userId'],
            email: userData['email'] ?? email,
            nombre: userData['nombre'] ?? 'Usuario',
            telefono: userData['telefono'],
            direccion: userData['direccion'],
            rol: userData['rol'] ?? 'cliente',
            estado: userData['estado'] ?? 'activo',
          );
          _authState = AuthState.authenticated;
          _errorMessage = null;
          notifyListeners();
          return true;
        } else {
          _errorMessage = 'No se encontraron datos del usuario en Firestore';
          _authState = AuthState.error;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = result['message'] ?? 'Error al iniciar sesión';
        _authState = AuthState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      _authState = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
    String email,
    String password,
    String nombre,
    String telefono, {
    String? direccion,
  }) async {
    _authState = AuthState.loading;
    notifyListeners();

    try {
      // Usar Firebase Authentication para registrar usuario
      final firebaseAuth = FirebaseAuthService();
      final result = await firebaseAuth.registrarUsuario(
        nombre: nombre,
        email: email,
        password: password,
        telefono: telefono,
        direccion: direccion,
        rol: 'cliente',
      );

      if (result['success'] == true) {
        // Usuario registrado exitosamente
        // Ahora hacer login automático
        final loginResult = await firebaseAuth.iniciarSesion(
          email: email,
          password: password,
        );

        if (loginResult['success'] == true) {
          final userData = loginResult['userData'] as Map<String, dynamic>?;

          if (userData != null) {
            _currentUser = UsuarioModelo(
              id: userData['id'] ?? loginResult['userId'],
              email: userData['email'] ?? email,
              nombre: userData['nombre'] ?? nombre,
              telefono: userData['telefono'],
              direccion: userData['direccion'],
              rol: userData['rol'] ?? 'cliente',
              estado: userData['estado'] ?? 'activo',
            );
            _authState = AuthState.authenticated;
            _errorMessage = null;
            notifyListeners();
            return true;
          }
        }
      }

      // Si algo falla, mostrar el error
      _errorMessage = result['message'] ?? 'Error al registrar usuario';
      _authState = AuthState.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      _authState = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _authState = AuthState.loading;
    notifyListeners();

    try {
      // Usar Firebase Authentication para recuperar contraseña
      final firebaseAuth = FirebaseAuthService();
      final result = await firebaseAuth.recuperarPassword(email: email);

      if (result['success'] == true) {
        _authState = AuthState.unauthenticated;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Error al enviar correo';
        _authState = AuthState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      _authState = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      // Cerrar sesión en Firebase
      final firebaseAuth = FirebaseAuthService();
      await firebaseAuth.cerrarSesion();
    } catch (e) {
      // Ignorar errores en logout, siempre limpiar el estado local
    }

    _currentUser = null;
    _authState = AuthState.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  bool hasPermission(String permission) {
    if (_currentUser == null) return false;
    if (_currentUser!.rol == 'admin') return true;
    return false;
  }

  // Actualizar información del usuario actual
  void actualizarUsuarioActual(UsuarioModelo usuario) {
    _currentUser = usuario;
    notifyListeners();
  }
}
