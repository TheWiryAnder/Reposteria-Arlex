import '../servicios/base/repository_base.dart';
import '../configuracion/firebase_config.dart' as config;

// Enums required for UsuarioModelo
enum RolUsuario {
  admin,
  empleado,
  cliente,
}

enum EstadoUsuario {
  activo,
  inactivo,
  suspendido,
  pendienteVerificacion,
}

// UsuarioModelo definition with all required fields
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

  UsuarioModelo({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.email,
    required this.nombre,
    this.telefono,
    required this.rol,
    required this.estado,
    this.avatar,
    this.ultimoLogin,
    this.fechaVerificacion,
    this.preferencias,
    this.direccion,
    required this.emailVerificado,
    required this.telefonoVerificado,
  });

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
    );
  }

  factory UsuarioModelo.fromFirestore(Map<String, dynamic> data, String id) {
    return UsuarioModelo(
      id: id,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'])
          : DateTime.now(),
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

  Map<String, dynamic> toFirestore() {
    return {
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
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
    };
  }

  bool get esAdmin => rol == RolUsuario.admin;
  bool get esEmpleado => rol == RolUsuario.empleado;
  bool get esCliente => rol == RolUsuario.cliente;
  bool get estaActivo => estado == EstadoUsuario.activo;
  bool get necesitaVerificacion => estado == EstadoUsuario.pendienteVerificacion;
}

// Repository exception class
class RepositoryException implements Exception {
  final String message;
  RepositoryException(this.message);

  @override
  String toString() => 'RepositoryException: $message';
}

// Cache mixin placeholder
mixin CacheRepositoryMixin<T> {
  Map<String, T> get cache => {};
  Map<String, DateTime> get cacheTimestamps => {};
}

class UsuarioRepository extends RepositoryBase<UsuarioModelo> with CacheRepositoryMixin<UsuarioModelo> {
  static UsuarioRepository? _instance;
  static UsuarioRepository get instance => _instance ??= UsuarioRepository._();

  UsuarioRepository._();

  @override
  String get collectionName => config.FirebaseConfig.coleccionUsuarios;

  @override
  UsuarioModelo fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UsuarioModelo.fromFirestore(data, doc.id);
  }

  @override
  Map<String, dynamic> toFirestore(UsuarioModelo model) {
    return model.toFirestore();
  }

  // Basic repository methods
  Future<UsuarioModelo?> buscarPorEmail(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      // Mock implementation for development
      if (normalizedEmail == 'admin@reposteriaarlex.com') {
        return UsuarioModelo(
          id: '1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          email: normalizedEmail,
          nombre: 'Administrador Arlex',
          rol: RolUsuario.admin,
          estado: EstadoUsuario.activo,
          emailVerificado: true,
          telefonoVerificado: false,
        );
      } else if (normalizedEmail == 'cliente@test.com') {
        return UsuarioModelo(
          id: '2',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          email: normalizedEmail,
          nombre: 'Cliente de Prueba',
          rol: RolUsuario.cliente,
          estado: EstadoUsuario.activo,
          emailVerificado: true,
          telefonoVerificado: false,
        );
      }

      return null;
    } catch (e) {
      throw RepositoryException('Error buscando usuario por email: $e');
    }
  }

  Future<UsuarioModelo> crear(UsuarioModelo usuario) async {
    try {
      // Mock implementation
      return usuario.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      throw RepositoryException('Error creando usuario: $e');
    }
  }

  Future<UsuarioModelo> actualizar(UsuarioModelo usuario) async {
    try {
      // Mock implementation
      return usuario.copyWith(updatedAt: DateTime.now());
    } catch (e) {
      throw RepositoryException('Error actualizando usuario: $e');
    }
  }

  Future<void> eliminar(String id) async {
    try {
      // Mock implementation
      return;
    } catch (e) {
      throw RepositoryException('Error eliminando usuario: $e');
    }
  }
}