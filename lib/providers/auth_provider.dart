import 'package:flutter/material.dart';
import '../modelos/usuario_modelo.dart';
import '../servicios/base_datos_local.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  static AuthProvider? _instance;
  static AuthProvider get instance => _instance ??= AuthProvider._();

  AuthProvider._();

  // Estado de autenticación
  AuthState _authState = AuthState.initial;
  UsuarioModelo? _currentUser;
  String? _token;
  String? _refreshToken;
  DateTime? _tokenExpiration;
  String? _errorMessage;

  // Servicio de almacenamiento local
  late final BaseDatosLocal _storage;

  // Getters públicos
  AuthState get authState => _authState;
  UsuarioModelo? get currentUser => _currentUser;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  DateTime? get tokenExpiration => _tokenExpiration;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _authState == AuthState.authenticated && _currentUser != null && _token != null;
  bool get isLoading => _authState == AuthState.loading;
  bool get hasError => _authState == AuthState.error;

  // Información del usuario actual
  bool get isAdmin => _currentUser?.esAdmin ?? false;
  bool get isEmployee => _currentUser?.esEmpleado ?? false;
  bool get isClient => _currentUser?.esCliente ?? false;
  bool get isActive => _currentUser?.estaActivo ?? false;
  bool get needsVerification => _currentUser?.necesitaVerificacion ?? false;

  // Inicializar el provider
  Future<void> initialize() async {
    _authState = AuthState.loading;
    notifyListeners();

    try {
      _storage = BaseDatosLocal.instance;
      await _loadStoredAuth();
    } catch (e) {
      _setErrorState('Error al inicializar autenticación');
    }
  }

  // Cargar autenticación almacenada
  Future<void> _loadStoredAuth() async {
    try {
      final userData = await _storage.getMap('user_data');
      final token = await _storage.getString('auth_token');
      final refreshToken = await _storage.getString('refresh_token');
      final expirationStr = await _storage.getString('token_expiration');

      if (userData != null && token != null) {
        // Recrear el usuario desde los datos almacenados
        _currentUser = UsuarioModelo.fromFirestore(
          _MockDocumentSnapshot(userData['id'], userData),
        );
        _token = token;
        _refreshToken = refreshToken;

        if (expirationStr != null) {
          _tokenExpiration = DateTime.parse(expirationStr);
        }

        // Verificar si el token aún es válido
        if (_tokenExpiration != null && DateTime.now().isAfter(_tokenExpiration!)) {
          // Token expirado, intentar renovar o hacer logout
          await _handleExpiredToken();
        } else {
          _setAuthenticatedState();
        }
      } else {
        _setUnauthenticatedState();
      }
    } catch (e) {
      debugPrint('Error cargando autenticación almacenada: $e');
      await _clearStoredAuth();
      _setUnauthenticatedState();
    }
  }

  // Manejar token expirado
  Future<void> _handleExpiredToken() async {
    if (_refreshToken != null) {
      // TODO: Implementar renovación de token cuando esté disponible la API
      // Por ahora, hacer logout
      await logout();
    } else {
      await logout();
    }
  }

  // Establecer usuario autenticado
  Future<void> setAuthenticatedUser(
    UsuarioModelo user,
    String token,
    String? refreshToken,
  ) async {
    try {
      _currentUser = user.actualizarUltimoLogin();
      _token = token;
      _refreshToken = refreshToken;
      _tokenExpiration = DateTime.now().add(const Duration(hours: 24));

      // Guardar en almacenamiento local
      await _storeAuthData();

      _setAuthenticatedState();
    } catch (e) {
      _setErrorState('Error al establecer usuario autenticado');
    }
  }

  // Actualizar información del usuario
  Future<void> updateUserInfo(UsuarioModelo updatedUser) async {
    try {
      _currentUser = updatedUser;
      await _storeAuthData();
      notifyListeners();
    } catch (e) {
      _setErrorState('Error al actualizar información del usuario');
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    try {
      await _clearStoredAuth();
      _currentUser = null;
      _token = null;
      _refreshToken = null;
      _tokenExpiration = null;
      _setUnauthenticatedState();
    } catch (e) {
      _setErrorState('Error al cerrar sesión');
    }
  }

  // Verificar si el usuario tiene permisos específicos
  bool hasPermission(String permission) {
    if (_currentUser == null || !isAuthenticated) return false;

    switch (permission) {
      case 'admin_access':
        return isAdmin;
      case 'employee_access':
        return isEmployee;
      case 'manage_products':
        return isAdmin || isEmployee;
      case 'manage_orders':
        return isAdmin || isEmployee;
      case 'view_analytics':
        return isAdmin;
      case 'place_orders':
        return isActive && (isClient || isAdmin);
      default:
        return false;
    }
  }

  // Verificar si puede acceder a una ruta específica
  bool canAccessRoute(String routeName) {
    if (!isAuthenticated) {
      // Rutas públicas que no requieren autenticación
      const publicRoutes = [
        '/login',
        '/register',
        '/forgot-password',
        '/home',
        '/products',
        '/about',
      ];
      return publicRoutes.contains(routeName);
    }

    // Si está autenticado pero necesita verificación
    if (needsVerification) {
      const verificationRoutes = [
        '/verify-email',
        '/logout',
      ];
      return verificationRoutes.contains(routeName);
    }

    // Rutas que requieren roles específicos
    if (routeName.startsWith('/admin')) {
      return hasPermission('admin_access');
    }

    if (routeName.startsWith('/employee')) {
      return hasPermission('employee_access');
    }

    // Otras rutas autenticadas
    return isActive;
  }

  // Obtener la ruta de redirección después del login
  String getRedirectRoute() {
    if (_currentUser == null) return '/login';

    if (needsVerification) return '/verify-email';

    if (isAdmin) return '/admin/dashboard';
    if (isEmployee) return '/employee/dashboard';
    if (isClient) return '/client/dashboard';

    return '/home';
  }

  // Métodos privados para cambiar el estado
  void _setAuthenticatedState() {
    _authState = AuthState.authenticated;
    _errorMessage = null;
    notifyListeners();
  }

  void _setUnauthenticatedState() {
    _authState = AuthState.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoadingState() {
    _authState = AuthState.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setErrorState(String error) {
    _authState = AuthState.error;
    _errorMessage = error;
    notifyListeners();
  }

  // Almacenar datos de autenticación
  Future<void> _storeAuthData() async {
    if (_currentUser != null && _token != null) {
      await _storage.setMap('user_data', _currentUser!.toFirestore());
      await _storage.setString('auth_token', _token!);

      if (_refreshToken != null) {
        await _storage.setString('refresh_token', _refreshToken!);
      }

      if (_tokenExpiration != null) {
        await _storage.setString('token_expiration', _tokenExpiration!.toIso8601String());
      }
    }
  }

  // Limpiar datos almacenados
  Future<void> _clearStoredAuth() async {
    await Future.wait([
      _storage.remove('user_data'),
      _storage.remove('auth_token'),
      _storage.remove('refresh_token'),
      _storage.remove('token_expiration'),
    ]);
  }

  // Limpiar mensaje de error
  void clearError() {
    if (_authState == AuthState.error) {
      _authState = AuthState.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    }
  }

  // Verificar si el token está próximo a expirar
  bool get isTokenNearExpiration {
    if (_tokenExpiration == null) return false;
    final now = DateTime.now();
    final difference = _tokenExpiration!.difference(now);
    return difference.inMinutes < 15; // Menos de 15 minutos
  }

  // Refrescar token si es necesario
  Future<void> refreshTokenIfNeeded() async {
    if (isTokenNearExpiration && _refreshToken != null) {
      // TODO: Implementar renovación de token cuando esté disponible la API
      debugPrint('Token próximo a expirar, debería renovarse');
    }
  }

  // Método para debug - mostrar información del estado actual
  void debugState() {
    debugPrint('=== AUTH PROVIDER STATE ===');
    debugPrint('State: $_authState');
    debugPrint('User: ${_currentUser?.email ?? "null"}');
    debugPrint('Token: ${_token != null ? "Present" : "null"}');
    debugPrint('Authenticated: $isAuthenticated');
    debugPrint('Error: $_errorMessage');
    debugPrint('==========================');
  }
}

// Mock DocumentSnapshot para compatibilidad
class _MockDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic> _data;

  _MockDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  bool get exists => true;
}