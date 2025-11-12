import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio para gestionar notificaciones de usuarios
class NotificacionesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Crear una notificación para un usuario específico
  Future<void> crearNotificacion({
    required String userId,
    required String titulo,
    required String mensaje,
    String? tipo, // 'pedido', 'admin', 'promocion'
    String? pedidoId,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notificaciones').add({
        'userId': userId,
        'titulo': titulo,
        'mensaje': mensaje,
        'tipo': tipo ?? 'admin',
        'pedidoId': pedidoId,
        'leida': false,
        'fecha': FieldValue.serverTimestamp(),
        'data': data,
      });
    } catch (e) {
      print('Error al crear notificación: $e');
      rethrow;
    }
  }

  /// Crear notificación para todos los usuarios registrados
  Future<void> crearNotificacionMasiva({
    required String titulo,
    required String mensaje,
    String? tipo,
  }) async {
    try {
      // Obtener todos los usuarios (excepto administradores)
      final usuarios = await _firestore
          .collection('usuarios')
          .where('rol', isNotEqualTo: 'admin')
          .get();

      // Crear batch para escribir todas las notificaciones
      final batch = _firestore.batch();

      for (var doc in usuarios.docs) {
        final notifRef = _firestore.collection('notificaciones').doc();
        batch.set(notifRef, {
          'userId': doc.id,
          'titulo': titulo,
          'mensaje': mensaje,
          'tipo': tipo ?? 'admin',
          'leida': false,
          'fecha': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error al crear notificación masiva: $e');
      rethrow;
    }
  }

  /// Marcar notificación como leída
  Future<void> marcarComoLeida(String notificacionId) async {
    try {
      await _firestore.collection('notificaciones').doc(notificacionId).update({
        'leida': true,
      });
    } catch (e) {
      print('Error al marcar notificación como leída: $e');
      rethrow;
    }
  }

  /// Marcar todas las notificaciones de un usuario como leídas
  Future<void> marcarTodasComoLeidas(String userId) async {
    try {
      final notificaciones = await _firestore
          .collection('notificaciones')
          .where('userId', isEqualTo: userId)
          .where('leida', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in notificaciones.docs) {
        batch.update(doc.reference, {'leida': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error al marcar todas como leídas: $e');
      rethrow;
    }
  }

  /// Obtener notificaciones de un usuario (Stream)
  Stream<QuerySnapshot> obtenerNotificacionesUsuario(String userId) {
    return _firestore
        .collection('notificaciones')
        .where('userId', isEqualTo: userId)
        .orderBy('fecha', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Obtener cantidad de notificaciones no leídas
  Stream<int> obtenerCantidadNoLeidas(String userId) {
    return _firestore
        .collection('notificaciones')
        .where('userId', isEqualTo: userId)
        .where('leida', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Eliminar notificación
  Future<void> eliminarNotificacion(String notificacionId) async {
    try {
      await _firestore.collection('notificaciones').doc(notificacionId).delete();
    } catch (e) {
      print('Error al eliminar notificación: $e');
      rethrow;
    }
  }

  /// Eliminar todas las notificaciones de un usuario
  Future<void> eliminarTodasNotificaciones(String userId) async {
    try {
      final notificaciones = await _firestore
          .collection('notificaciones')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in notificaciones.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error al eliminar todas las notificaciones: $e');
      rethrow;
    }
  }

  /// Notificar cambio de estado de pedido
  Future<void> notificarCambioEstadoPedido({
    required String userId,
    required String pedidoId,
    required String numeroPedido,
    required String estadoAnterior,
    required String estadoNuevo,
  }) async {
    String titulo = '';
    String mensaje = '';

    switch (estadoNuevo.toLowerCase()) {
      case 'pendiente':
        titulo = '📋 Pedido Recibido';
        mensaje = 'Tu pedido #$numeroPedido ha sido recibido y está pendiente de confirmación';
        break;
      case 'confirmado':
        titulo = '✅ Pedido Confirmado';
        mensaje = 'Tu pedido #$numeroPedido ha sido confirmado';
        break;
      case 'en preparacion':
      case 'en_proceso':
        titulo = '🔄 Pedido en Preparación';
        mensaje = 'Tu pedido #$numeroPedido está siendo preparado';
        break;
      case 'listo':
        titulo = '✅ Pedido Listo';
        mensaje = 'Tu pedido #$numeroPedido está listo para recoger';
        break;
      case 'en camino':
        titulo = '🚗 Pedido en Camino';
        mensaje = 'Tu pedido #$numeroPedido está en camino';
        break;
      case 'entregado':
        titulo = '🎉 Pedido Entregado';
        mensaje = 'Tu pedido #$numeroPedido ha sido entregado. ¡Gracias por tu compra!';
        break;
      case 'cancelado':
        titulo = '❌ Pedido Cancelado';
        mensaje = 'Tu pedido #$numeroPedido ha sido cancelado';
        break;
      default:
        titulo = '📦 Actualización de Pedido';
        mensaje = 'Tu pedido #$numeroPedido ha sido actualizado';
    }

    await crearNotificacion(
      userId: userId,
      titulo: titulo,
      mensaje: mensaje,
      tipo: 'pedido',
      pedidoId: pedidoId,
      data: {
        'estadoAnterior': estadoAnterior,
        'estadoNuevo': estadoNuevo,
        'numeroPedido': numeroPedido,
      },
    );
  }
}
