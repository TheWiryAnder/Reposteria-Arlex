import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Servicio de autenticación con Firebase
/// Maneja todo lo relacionado con login, registro, logout y gestión de usuarios
class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream del estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuario actual
  User? get currentUser => _auth.currentUser;

  /// Registrar nuevo usuario
  /// Crea el usuario en Firebase Auth y su documento en Firestore
  Future<Map<String, dynamic>> registrarUsuario({
    required String nombre,
    required String email,
    required String password,
    required String telefono,
    String? direccion,
    String rol = 'cliente',
  }) async {
    try {
      // 1. Crear usuario en Firebase Auth
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user == null) {
        return {
          'success': false,
          'message': 'Error al crear el usuario',
        };
      }

      // 2. Crear documento del usuario en Firestore
      await _firestore.collection('usuarios').doc(user.uid).set({
        'id': user.uid,
        'nombre': nombre,
        'email': email,
        'telefono': telefono,
        'rol': rol,
        'estado': 'activo',
        'emailVerificado': false,
        'direccion': direccion ?? '',
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'ultimoAcceso': FieldValue.serverTimestamp(),
        'preferencias': {
          'notificaciones': true,
          'newsletter': false,
        },
      });

      // 3. Enviar email de verificación
      await user.sendEmailVerification();

      return {
        'success': true,
        'message': 'Usuario registrado exitosamente',
        'userId': user.uid,
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Error al registrar usuario';

      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Este correo ya está registrado';
          break;
        case 'invalid-email':
          errorMessage = 'Correo electrónico inválido';
          break;
        case 'weak-password':
          errorMessage = 'La contraseña es muy débil. Debe tener al menos 6 caracteres';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Operación no permitida';
          break;
        default:
          errorMessage = 'Error: ${e.message}';
      }

      return {
        'success': false,
        'message': errorMessage,
        'code': e.code,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error inesperado: $e',
      };
    }
  }

  /// Iniciar sesión con email y contraseña
  Future<Map<String, dynamic>> iniciarSesion({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Verificar si hay una nueva contraseña temporal pendiente
      final querySnapshot = await _firestore
          .collection('usuarios')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();

      String? nuevaPasswordTemporal;

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        nuevaPasswordTemporal = userData['nuevaPasswordTemporal'] as String?;
      }

      // 2. Intentar login con la contraseña proporcionada
      // Si hay contraseña temporal, intentar primero con ella
      String passwordToUse = password;
      if (nuevaPasswordTemporal != null) {
        passwordToUse = nuevaPasswordTemporal;
      }

      UserCredential? userCredential;
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: passwordToUse,
        );
      } on FirebaseAuthException catch (e) {
        // Si falló con la nueva contraseña, intentar con la original
        if (nuevaPasswordTemporal != null && e.code == 'wrong-password') {
          userCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      final User? user = userCredential.user;

      if (user == null) {
        return {
          'success': false,
          'message': 'Error al iniciar sesión',
        };
      }

      // 3. Si hay contraseña temporal y se autenticó con ella, actualizar en Firebase Auth
      if (nuevaPasswordTemporal != null && passwordToUse == nuevaPasswordTemporal) {
        await user.updatePassword(nuevaPasswordTemporal);

        // Limpiar la contraseña temporal
        await _firestore.collection('usuarios').doc(user.uid).update({
          'nuevaPasswordTemporal': FieldValue.delete(),
        });
      }

      // 4. Actualizar último acceso en Firestore
      await _firestore.collection('usuarios').doc(user.uid).update({
        'ultimoAcceso': FieldValue.serverTimestamp(),
      });

      // 5. Obtener datos del usuario
      final userData = await obtenerDatosUsuario(user.uid);

      return {
        'success': true,
        'message': 'Sesión iniciada exitosamente',
        'userId': user.uid,
        'userData': userData,
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Error al iniciar sesión';

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No existe una cuenta con este correo';
          break;
        case 'wrong-password':
          errorMessage = 'Contraseña incorrecta';
          break;
        case 'invalid-email':
          errorMessage = 'Correo electrónico inválido';
          break;
        case 'user-disabled':
          errorMessage = 'Esta cuenta ha sido deshabilitada';
          break;
        case 'invalid-credential':
          errorMessage = 'Credenciales inválidas';
          break;
        default:
          errorMessage = 'Error: ${e.message}';
      }

      return {
        'success': false,
        'message': errorMessage,
        'code': e.code,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error inesperado: $e',
      };
    }
  }

  /// Cerrar sesión
  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }

  /// Obtener datos del usuario desde Firestore
  Future<Map<String, dynamic>?> obtenerDatosUsuario(String userId) async {
    try {
      final doc = await _firestore.collection('usuarios').doc(userId).get(
        const GetOptions(source: Source.serverAndCache),
      );

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      // Silenciar errores temporales de red
      if (!e.toString().contains('PERMISSION_DENIED')) {
        debugPrint('Error al obtener datos del usuario: $e');
      }
      return null;
    }
  }

  /// Stream de datos del usuario actual
  Stream<Map<String, dynamic>?> streamDatosUsuarioActual() {
    final user = currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _firestore.collection('usuarios').doc(user.uid).snapshots().map(
          (doc) => doc.exists ? doc.data() : null,
        );
  }

  /// Actualizar perfil del usuario
  Future<Map<String, dynamic>> actualizarPerfil({
    required String userId,
    String? nombre,
    String? telefono,
    String? direccion,
    DateTime? fechaNacimiento,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'fechaActualizacion': FieldValue.serverTimestamp(),
      };

      if (nombre != null) updates['nombre'] = nombre;
      if (telefono != null) updates['telefono'] = telefono;
      if (direccion != null) updates['direccion'] = direccion;
      if (fechaNacimiento != null) {
        updates['fechaNacimiento'] = Timestamp.fromDate(fechaNacimiento);
      }

      await _firestore.collection('usuarios').doc(userId).update(updates);

      return {
        'success': true,
        'message': 'Perfil actualizado exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al actualizar perfil: $e',
      };
    }
  }

  /// Cambiar contraseña
  Future<Map<String, dynamic>> cambiarPassword({
    required String passwordActual,
    required String passwordNueva,
  }) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) {
        return {
          'success': false,
          'message': 'No hay usuario autenticado',
        };
      }

      // 1. Re-autenticar usuario
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: passwordActual,
      );

      await user.reauthenticateWithCredential(credential);

      // 2. Cambiar contraseña
      await user.updatePassword(passwordNueva);

      return {
        'success': true,
        'message': 'Contraseña actualizada exitosamente',
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Error al cambiar contraseña';

      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'La contraseña actual es incorrecta';
          break;
        case 'weak-password':
          errorMessage = 'La nueva contraseña es muy débil';
          break;
        default:
          errorMessage = 'Error: ${e.message}';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error inesperado: $e',
      };
    }
  }

  /// Recuperar contraseña
  Future<Map<String, dynamic>> recuperarPassword({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);

      return {
        'success': true,
        'message': 'Se ha enviado un correo para restablecer tu contraseña',
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Error al enviar correo';

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No existe una cuenta con este correo';
          break;
        case 'invalid-email':
          errorMessage = 'Correo electrónico inválido';
          break;
        default:
          errorMessage = 'Error: ${e.message}';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error inesperado: $e',
      };
    }
  }

  /// Enviar email de verificación
  Future<Map<String, dynamic>> enviarEmailVerificacion() async {
    try {
      final user = currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'No hay usuario autenticado',
        };
      }

      if (user.emailVerified) {
        return {
          'success': false,
          'message': 'El correo ya está verificado',
        };
      }

      await user.sendEmailVerification();

      return {
        'success': true,
        'message': 'Correo de verificación enviado',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al enviar correo: $e',
      };
    }
  }

  /// Recargar usuario (para actualizar emailVerified)
  Future<void> recargarUsuario() async {
    await currentUser?.reload();
  }

  /// Verificar si el email está verificado
  Future<bool> isEmailVerificado() async {
    await recargarUsuario();
    return currentUser?.emailVerified ?? false;
  }

  /// Eliminar cuenta
  Future<Map<String, dynamic>> eliminarCuenta({
    required String password,
  }) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) {
        return {
          'success': false,
          'message': 'No hay usuario autenticado',
        };
      }

      // 1. Re-autenticar
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // 2. Eliminar documento de Firestore
      await _firestore.collection('usuarios').doc(user.uid).delete();

      // 3. Eliminar cuenta de Auth
      await user.delete();

      return {
        'success': true,
        'message': 'Cuenta eliminada exitosamente',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error inesperado: $e',
      };
    }
  }
}
