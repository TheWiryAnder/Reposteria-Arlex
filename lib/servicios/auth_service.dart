import '../servicios/base/api_service_base.dart';
import '../configuracion/app_config.dart';

class AuthService extends ApiServiceBase {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._() : super(
    baseUrl: AppConfig.baseApiUrl,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-API-Version': '1.0',
    },
  );

  // Login con email y contraseña
  Future<ApiResponse<AuthResponse>> login(DatosLogin datos) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/auth/login',
        body: datos.toJson(),
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data!);
        return ApiResponse.success(authResponse);
      } else {
        return ApiResponse.error(response.error ??
          ApiException('Error desconocido en login', ApiErrorType.unknown));
      }
    } catch (e) {
      return ApiResponse.error(
        ApiException('Error de conexión en login: $e', ApiErrorType.network),
      );
    }
  }

  // Registro de nuevo usuario
  Future<ApiResponse<AuthResponse>> register(DatosRegistro datos) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/auth/register',
        body: datos.toJson(),
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data!);
        return ApiResponse.success(authResponse);
      } else {
        return ApiResponse.error(response.error ??
          ApiException('Error desconocido en registro', ApiErrorType.unknown));
      }
    } catch (e) {
      return ApiResponse.error(
        ApiException('Error de conexión en registro: $e', ApiErrorType.network),
      );
    }
  }

  // Logout
  Future<ApiResponse<void>> logout(String token) async {
    try {
      final response = await post<void>(
        '/auth/logout',
        headers: {'Authorization': 'Bearer $token'},
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        ApiException('Error en logout: $e', ApiErrorType.network),
      );
    }
  }

  // Verificar token actual
  Future<ApiResponse<UsuarioModelo>> verifyToken(String token) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/auth/verify',
        headers: {'Authorization': 'Bearer $token'},
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        final usuario = UsuarioModelo.fromFirestore(
          _MockDocumentSnapshot(
            response.data!['id'],
            response.data!,
          ),
        );
        return ApiResponse.success(usuario);
      } else {
        return ApiResponse.error(response.error ??
          ApiException('Token inválido', ApiErrorType.unauthorized));
      }
    } catch (e) {
      return ApiResponse.error(
        ApiException('Error verificando token: $e', ApiErrorType.network),
      );
    }
  }

  // Refrescar token
  Future<ApiResponse<AuthResponse>> refreshToken(String refreshToken) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/auth/refresh',
        body: {'refreshToken': refreshToken},
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data!);
        return ApiResponse.success(authResponse);
      } else {
        return ApiResponse.error(response.error ??
          ApiException('Error refrescando token', ApiErrorType.unauthorized));
      }
    } catch (e) {
      return ApiResponse.error(
        ApiException('Error refrescando token: $e', ApiErrorType.network),
      );
    }
  }

  // Verificar si email existe
  Future<ApiResponse<bool>> checkEmailExists(String email) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/auth/check-email',
        queryParameters: {'email': email},
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        final exists = response.data!['exists'] ?? false;
        return ApiResponse.success(exists);
      } else {
        return ApiResponse.error(response.error ??
          ApiException('Error verificando email', ApiErrorType.unknown));
      }
    } catch (e) {
      return ApiResponse.error(
        ApiException('Error verificando email: $e', ApiErrorType.network),
      );
    }
  }

  // Solicitar recuperación de contraseña
  Future<ApiResponse<void>> requestPasswordReset(String email) async {
    try {
      final response = await post<void>(
        '/auth/forgot-password',
        body: {'email': email},
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        ApiException('Error solicitando recuperación: $e', ApiErrorType.network),
      );
    }
  }

  // Restablecer contraseña con código
  Future<ApiResponse<void>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await post<void>(
        '/auth/reset-password',
        body: {
          'email': email,
          'code': code,
          'newPassword': newPassword,
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        ApiException('Error restableciendo contraseña: $e', ApiErrorType.network),
      );
    }
  }

  // Cambiar contraseña (usuario autenticado)
  Future<ApiResponse<void>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await post<void>(
        '/auth/change-password',
        headers: {'Authorization': 'Bearer $token'},
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        ApiException('Error cambiando contraseña: $e', ApiErrorType.network),
      );
    }
  }

  // Verificar email con código
  Future<ApiResponse<void>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await post<void>(
        '/auth/verify-email',
        body: {
          'email': email,
          'code': code,
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        ApiException('Error verificando email: $e', ApiErrorType.network),
      );
    }
  }

  // Reenviar código de verificación
  Future<ApiResponse<void>> resendVerificationCode(String email) async {
    try {
      final response = await post<void>(
        '/auth/resend-verification',
        body: {'email': email},
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        ApiException('Error reenviando código: $e', ApiErrorType.network),
      );
    }
  }

  // Actualizar perfil de usuario
  Future<ApiResponse<UsuarioModelo>> updateProfile({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await put<Map<String, dynamic>>(
        '/auth/profile',
        headers: {'Authorization': 'Bearer $token'},
        body: data,
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        final usuario = UsuarioModelo.fromFirestore(
          _MockDocumentSnapshot(
            response.data!['id'],
            response.data!,
          ),
        );
        return ApiResponse.success(usuario);
      } else {
        return ApiResponse.error(response.error ??
          ApiException('Error actualizando perfil', ApiErrorType.unknown));
      }
    } catch (e) {
      return ApiResponse.error(
        ApiException('Error actualizando perfil: $e', ApiErrorType.network),
      );
    }
  }

  // Eliminar cuenta
  Future<ApiResponse<void>> deleteAccount({
    required String token,
    required String password,
  }) async {
    try {
      final response = await delete<void>(
        '/auth/account',
        headers: {'Authorization': 'Bearer $token'},
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        ApiException('Error eliminando cuenta: $e', ApiErrorType.network),
      );
    }
  }

  // Login con redes sociales (placeholder para futuro)
  Future<ApiResponse<AuthResponse>> loginWithGoogle(String googleToken) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/auth/google',
        body: {'token': googleToken},
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data!);
        return ApiResponse.success(authResponse);
      } else {
        return ApiResponse.error(response.error ??
          ApiException('Error en login con Google', ApiErrorType.unknown));
      }
    } catch (e) {
      return ApiResponse.error(
        ApiException('Error en login con Google: $e', ApiErrorType.network),
      );
    }
  }

  Future<ApiResponse<AuthResponse>> loginWithFacebook(String facebookToken) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/auth/facebook',
        body: {'token': facebookToken},
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data!);
        return ApiResponse.success(authResponse);
      } else {
        return ApiResponse.error(response.error ??
          ApiException('Error en login con Facebook', ApiErrorType.unknown));
      }
    } catch (e) {
      return ApiResponse.error(
        ApiException('Error en login con Facebook: $e', ApiErrorType.network),
      );
    }
  }

  // Métodos para desarrollo/testing
  Future<ApiResponse<AuthResponse>> loginMock(DatosLogin datos) async {
    // Simular delay de red
    await Future.delayed(const Duration(milliseconds: 1500));

    // Simular respuesta exitosa para desarrollo
    if (datos.email == 'admin@reposteriaarlex.com' && datos.password == 'admin123') {
      final usuario = UsuarioModelo(
        id: '1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        email: datos.email,
        nombre: 'Administrador',
        rol: RolUsuario.admin,
        estado: EstadoUsuario.activo,
        emailVerificado: true,
      );

      final authResponse = AuthResponse(
        usuario: usuario,
        token: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'mock_refresh_token',
        expiracion: DateTime.now().add(const Duration(hours: 24)),
      );

      return ApiResponse.success(authResponse);
    } else if (datos.email == 'cliente@test.com' && datos.password == '123456') {
      final usuario = UsuarioModelo(
        id: '2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        email: datos.email,
        nombre: 'Cliente de Prueba',
        telefono: '+57 300 123 4567',
        rol: RolUsuario.cliente,
        estado: EstadoUsuario.activo,
        emailVerificado: true,
      );

      final authResponse = AuthResponse(
        usuario: usuario,
        token: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'mock_refresh_token',
        expiracion: DateTime.now().add(const Duration(hours: 24)),
      );

      return ApiResponse.success(authResponse);
    } else {
      return ApiResponse.error(
        ApiException('Email o contraseña incorrectos', ApiErrorType.unauthorized),
      );
    }
  }

  Future<ApiResponse<AuthResponse>> registerMock(DatosRegistro datos) async {
    // Simular delay de red
    await Future.delayed(const Duration(milliseconds: 2000));

    // Simular verificación de email existente
    if (datos.email == 'admin@reposteriaarlex.com' ||
        datos.email == 'cliente@test.com') {
      return ApiResponse.error(
        ApiException('Este email ya está registrado', ApiErrorType.badRequest),
      );
    }

    // Simular registro exitoso
    final usuario = UsuarioModelo(
      id: 'new_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      email: datos.email,
      nombre: datos.nombre,
      telefono: datos.telefono,
      direccion: datos.direccion,
      rol: RolUsuario.cliente,
      estado: EstadoUsuario.pendienteVerificacion,
      emailVerificado: false,
    );

    final authResponse = AuthResponse(
      usuario: usuario,
      token: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'mock_refresh_token',
      expiracion: DateTime.now().add(const Duration(hours: 24)),
    );

    return ApiResponse.success(authResponse);
  }
}

// Definiciones temporales para resolver errores de importación en Windows
abstract class DocumentSnapshot<T> {
  String get id;
  T? data();
  bool get exists;
}
enum RolUsuario {
  cliente,
  admin,
  empleado,
}

enum EstadoUsuario {
  activo,
  inactivo,
  suspendido,
  pendienteVerificacion,
}

class DatosLogin {
  final String email;
  final String password;
  final bool recordarme;

  const DatosLogin({
    required this.email,
    required this.password,
    this.recordarme = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'recordarme': recordarme,
    };
  }
}

class DatosRegistro {
  final String email;
  final String password;
  final String nombre;
  final String? telefono;
  final String? direccion;
  final bool aceptaTerminos;

  const DatosRegistro({
    required this.email,
    required this.password,
    required this.nombre,
    this.telefono,
    this.direccion,
    required this.aceptaTerminos,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'nombre': nombre,
      'telefono': telefono,
      'direccion': direccion,
      'aceptaTerminos': aceptaTerminos,
    };
  }
}

class AuthResponse {
  final UsuarioModelo usuario;
  final String token;
  final String? refreshToken;
  final DateTime expiracion;

  const AuthResponse({
    required this.usuario,
    required this.token,
    this.refreshToken,
    required this.expiracion,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      usuario: UsuarioModelo.fromFirestore(
        _MockDocumentSnapshot(json['usuario']['id'], json['usuario']),
      ),
      token: json['token'],
      refreshToken: json['refreshToken'],
      expiracion: DateTime.parse(json['expiracion']),
    );
  }

  bool get tokenExpirado => DateTime.now().isAfter(expiracion);
  bool get proximoAExpirar =>
      expiracion.difference(DateTime.now()).inMinutes < 15;
}

class UsuarioModelo {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String email;
  final String nombre;
  final String? telefono;
  final RolUsuario rol;
  final EstadoUsuario estado;
  final String? avatar;
  final DateTime? ultimoLogin;
  final DateTime? fechaVerificacion;
  final Map<String, dynamic>? preferencias;
  final String? direccion;
  final bool emailVerificado;
  final bool telefonoVerificado;

  const UsuarioModelo({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.email,
    required this.nombre,
    this.telefono,
    this.rol = RolUsuario.cliente,
    this.estado = EstadoUsuario.pendienteVerificacion,
    this.avatar,
    this.ultimoLogin,
    this.fechaVerificacion,
    this.preferencias,
    this.direccion,
    this.emailVerificado = false,
    this.telefonoVerificado = false,
  });

  static UsuarioModelo fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    return UsuarioModelo(
      id: doc.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      email: data['email'] ?? '',
      nombre: data['nombre'] ?? '',
      telefono: data['telefono'],
      rol: RolUsuario.values.firstWhere(
        (r) => r.name == data['rol'],
        orElse: () => RolUsuario.cliente,
      ),
      estado: EstadoUsuario.values.firstWhere(
        (e) => e.name == data['estado'],
        orElse: () => EstadoUsuario.pendienteVerificacion,
      ),
      avatar: data['avatar'],
      ultimoLogin: data['ultimoLogin'] != null
          ? DateTime.parse(data['ultimoLogin'])
          : null,
      fechaVerificacion: data['fechaVerificacion'] != null
          ? DateTime.parse(data['fechaVerificacion'])
          : null,
      preferencias: data['preferencias']?.cast<String, dynamic>(),
      direccion: data['direccion'],
      emailVerificado: data['emailVerificado'] ?? false,
      telefonoVerificado: data['telefonoVerificado'] ?? false,
    );
  }

  UsuarioModelo actualizarUltimoLogin() {
    return UsuarioModelo(
      id: id,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      email: email,
      nombre: nombre,
      telefono: telefono,
      rol: rol,
      estado: estado,
      avatar: avatar,
      ultimoLogin: DateTime.now(),
      fechaVerificacion: fechaVerificacion,
      preferencias: preferencias,
      direccion: direccion,
      emailVerificado: emailVerificado,
      telefonoVerificado: telefonoVerificado,
    );
  }

  bool get esAdmin => rol == RolUsuario.admin;
  bool get esEmpleado => rol == RolUsuario.empleado || esAdmin;
  bool get esCliente => rol == RolUsuario.cliente;
  bool get estaActivo => estado == EstadoUsuario.activo;
  bool get necesitaVerificacion => estado == EstadoUsuario.pendienteVerificacion;

  String get iniciales {
    final parts = nombre.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';
  }

  String get rolDescripcion {
    switch (rol) {
      case RolUsuario.admin:
        return 'Administrador';
      case RolUsuario.empleado:
        return 'Empleado';
      case RolUsuario.cliente:
        return 'Cliente';
    }
  }

  String get estadoDescripcion {
    switch (estado) {
      case EstadoUsuario.activo:
        return 'Activo';
      case EstadoUsuario.inactivo:
        return 'Inactivo';
      case EstadoUsuario.suspendido:
        return 'Suspendido';
      case EstadoUsuario.pendienteVerificacion:
        return 'Pendiente de verificación';
    }
  }
}

// Mock DocumentSnapshot para desarrollo
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