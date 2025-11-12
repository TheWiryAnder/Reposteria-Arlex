import 'package:cloud_firestore/cloud_firestore.dart';

class ActividadesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'actividades_sistema';

  // Registrar una nueva actividad
  Future<void> registrarActividad({
    required String tipo,
    required String descripcion,
    required String usuarioId,
    String? usuarioNombre,
    Map<String, dynamic>? detalles,
  }) async {
    try {
      await _firestore.collection(_collection).add({
        'tipo': tipo, // 'pedido', 'registro', 'credenciales', 'notificacion', etc.
        'descripcion': descripcion,
        'usuarioId': usuarioId,
        'usuarioNombre': usuarioNombre,
        'detalles': detalles ?? {},
        'fecha': FieldValue.serverTimestamp(),
        'fechaCreacion': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error al registrar actividad: $e');
    }
  }

  // Obtener actividades recientes (stream)
  Stream<QuerySnapshot> obtenerActividadesRecientes({int limit = 5}) {
    return _firestore
        .collection(_collection)
        .orderBy('fecha', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Obtener todas las actividades (stream)
  Stream<QuerySnapshot> obtenerTodasLasActividades() {
    return _firestore
        .collection(_collection)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  // Obtener actividades por tipo
  Stream<QuerySnapshot> obtenerActividadesPorTipo(String tipo) {
    return _firestore
        .collection(_collection)
        .where('tipo', isEqualTo: tipo)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  // Obtener actividades de un usuario específico
  Stream<QuerySnapshot> obtenerActividadesPorUsuario(String usuarioId) {
    return _firestore
        .collection(_collection)
        .where('usuarioId', isEqualTo: usuarioId)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  // Limpiar actividades antiguas (opcional - más de 90 días)
  Future<void> limpiarActividadesAntiguas() async {
    try {
      final fechaLimite = DateTime.now().subtract(const Duration(days: 90));
      final snapshot = await _firestore
          .collection(_collection)
          .where('fecha', isLessThan: Timestamp.fromDate(fechaLimite))
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error al limpiar actividades antiguas: $e');
    }
  }
}
