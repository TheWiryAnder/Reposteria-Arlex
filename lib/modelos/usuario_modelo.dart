import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../modelos/base_modelo.dart';

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

class UsuarioModelo extends BaseModelo {
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
  final String? codigoValidacion; // Código para recuperación de contraseña
  final String? nuevaPasswordTemporal; // Nueva contraseña pendiente de aplicar

  UsuarioModelo({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
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
    this.codigoValidacion,
    this.nuevaPasswordTemporal,
  });

  @override
  Map<String, dynamic> toFirestore() {
    return TimestampMixin.addTimestamps({
      'email': email,
      'nombre': nombre,
      'telefono': telefono,
      'rol': rol.name,
      'estado': estado.name,
      'avatar': avatar,
      'ultimoLogin': ultimoLogin?.toIso8601String(),
      'fechaVerificacion': fechaVerificacion?.toIso8601String(),
      'preferencias': preferencias,
      'direccion': direccion,
      'emailVerificado': emailVerificado,
      'telefonoVerificado': telefonoVerificado,
      'codigoValidacion': codigoValidacion,
      'nuevaPasswordTemporal': nuevaPasswordTemporal,
    });
  }

  static UsuarioModelo fromFirestore(firestore.DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return fromMap(doc.id, data);
  }

  static UsuarioModelo fromMap(String id, Map<String, dynamic> data) {
    return UsuarioModelo(
      id: id,
      createdAt: TimestampMixin.parseTimestamp(data['createdAt']),
      updatedAt: TimestampMixin.parseTimestamp(data['updatedAt']),
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
      codigoValidacion: data['codigoValidacion'],
      nuevaPasswordTemporal: data['nuevaPasswordTemporal'],
    );
  }

  @override
  UsuarioModelo copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? email,
    String? nombre,
    String? telefono,
    RolUsuario? rol,
    EstadoUsuario? estado,
    String? avatar,
    DateTime? ultimoLogin,
    DateTime? fechaVerificacion,
    Map<String, dynamic>? preferencias,
    String? direccion,
    bool? emailVerificado,
    bool? telefonoVerificado,
    String? codigoValidacion,
    String? nuevaPasswordTemporal,
  }) {
    return UsuarioModelo(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      rol: rol ?? this.rol,
      estado: estado ?? this.estado,
      avatar: avatar ?? this.avatar,
      ultimoLogin: ultimoLogin ?? this.ultimoLogin,
      fechaVerificacion: fechaVerificacion ?? this.fechaVerificacion,
      preferencias: preferencias ?? this.preferencias,
      direccion: direccion ?? this.direccion,
      emailVerificado: emailVerificado ?? this.emailVerificado,
      telefonoVerificado: telefonoVerificado ?? this.telefonoVerificado,
      codigoValidacion: codigoValidacion ?? this.codigoValidacion,
      nuevaPasswordTemporal: nuevaPasswordTemporal ?? this.nuevaPasswordTemporal,
    );
  }

  // M�todos de utilidad
  bool get esAdmin => rol == RolUsuario.admin;
  bool get esEmpleado => rol == RolUsuario.empleado || esAdmin;
  bool get esCliente => rol == RolUsuario.cliente;
  bool get estaActivo => estado == EstadoUsuario.activo;
  bool get estaSuspendido => estado == EstadoUsuario.suspendido;
  bool get necesitaVerificacion => estado == EstadoUsuario.pendienteVerificacion;

  String get nombreCompleto => nombre;
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
        return 'Pendiente de verificaci�n';
    }
  }

  bool get puedeRealizarPedidos => estaActivo && (esCliente || esAdmin);
  bool get puedeAccederAdmin => esEmpleado;

  // Preferencias predefinidas
  bool get notificacionesPush => preferencias?['notificacionesPush'] ?? true;
  bool get notificacionesEmail => preferencias?['notificacionesEmail'] ?? true;
  bool get temaModoOscuro => preferencias?['temaModoOscuro'] ?? false;
  String get idioma => preferencias?['idioma'] ?? 'es';

  Map<String, dynamic> get preferenciasPredeterminadas => {
    'notificacionesPush': true,
    'notificacionesEmail': true,
    'temaModoOscuro': false,
    'idioma': 'es',
  };

  UsuarioModelo conPreferenciasPredeterminadas() {
    return copyWith(
      preferencias: {...preferenciasPredeterminadas, ...?preferencias},
    );
  }

  UsuarioModelo actualizarUltimoLogin() {
    return copyWith(ultimoLogin: DateTime.now());
  }

  UsuarioModelo marcarComoVerificado() {
    return copyWith(
      emailVerificado: true,
      fechaVerificacion: DateTime.now(),
      estado: EstadoUsuario.activo,
    );
  }

  @override
  String toString() {
    return 'UsuarioModelo(id: $id, email: $email, nombre: $nombre, rol: ${rol.name}, estado: ${estado.name})';
  }
}

// Clase para datos de registro
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

// Clase para datos de login
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

// Respuesta de autenticaci�n
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
      usuario: UsuarioModelo.fromMap(
        json['usuario']['id'] as String,
        json['usuario'] as Map<String, dynamic>,
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