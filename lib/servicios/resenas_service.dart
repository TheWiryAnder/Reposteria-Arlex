import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/resena_modelo.dart';

/// Servicio para gestionar las reseñas/comentarios de los clientes
class ResenasService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _coleccion = 'resenas';

  /// Obtener todas las reseñas ordenadas por fecha (más recientes primero)
  Stream<List<ResenaModelo>> streamResenas({int? limite}) {
    Query query = _firestore
        .collection(_coleccion)
        .orderBy('fecha', descending: true);

    if (limite != null) {
      query = query.limit(limite);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ResenaModelo.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  /// Obtener reseñas de un usuario específico
  Stream<List<ResenaModelo>> streamResenasPorUsuario(String usuarioId) {
    return _firestore
        .collection(_coleccion)
        .where('usuarioId', isEqualTo: usuarioId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ResenaModelo.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  /// Agregar una nueva reseña
  Future<String> agregarResena({
    required String usuarioId,
    required String usuarioNombre,
    required String comentario,
    required int valoracion,
    String? productoId,
    String? productoNombre,
    String? productoImagen,
  }) async {
    try {
      // Validaciones
      if (comentario.trim().isEmpty) {
        throw Exception('El comentario no puede estar vacío');
      }

      if (valoracion < 1 || valoracion > 5) {
        throw Exception('La valoración debe estar entre 1 y 5 estrellas');
      }

      // Crear la reseña
      final resena = ResenaModelo(
        id: '', // Se generará automáticamente
        usuarioId: usuarioId,
        usuarioNombre: usuarioNombre,
        comentario: comentario.trim(),
        valoracion: valoracion,
        fecha: DateTime.now(),
        productoId: productoId,
        productoNombre: productoNombre,
        productoImagen: productoImagen,
      );

      // Guardar en Firebase
      final docRef = await _firestore
          .collection(_coleccion)
          .add(resena.toMap());

      print('✅ Reseña agregada: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error al agregar reseña: $e');
      rethrow;
    }
  }

  /// Actualizar una reseña existente
  Future<void> actualizarResena({
    required String resenaId,
    required String comentario,
    required int valoracion,
  }) async {
    try {
      if (comentario.trim().isEmpty) {
        throw Exception('El comentario no puede estar vacío');
      }

      if (valoracion < 1 || valoracion > 5) {
        throw Exception('La valoración debe estar entre 1 y 5 estrellas');
      }

      await _firestore.collection(_coleccion).doc(resenaId).update({
        'comentario': comentario.trim(),
        'valoracion': valoracion,
      });

      print('✅ Reseña actualizada: $resenaId');
    } catch (e) {
      print('❌ Error al actualizar reseña: $e');
      rethrow;
    }
  }

  /// Eliminar una reseña
  Future<void> eliminarResena(String resenaId) async {
    try {
      await _firestore.collection(_coleccion).doc(resenaId).delete();
      print('✅ Reseña eliminada: $resenaId');
    } catch (e) {
      print('❌ Error al eliminar reseña: $e');
      rethrow;
    }
  }

  /// Verificar si un usuario ya dejó una reseña
  Future<bool> usuarioTieneResena(String usuarioId) async {
    try {
      final snapshot = await _firestore
          .collection(_coleccion)
          .where('usuarioId', isEqualTo: usuarioId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error al verificar reseña del usuario: $e');
      return false;
    }
  }

  /// Obtener la reseña de un usuario
  Future<ResenaModelo?> obtenerResenaPorUsuario(String usuarioId) async {
    try {
      final snapshot = await _firestore
          .collection(_coleccion)
          .where('usuarioId', isEqualTo: usuarioId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return ResenaModelo.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    } catch (e) {
      print('❌ Error al obtener reseña del usuario: $e');
      return null;
    }
  }

  /// Calcular valoración promedio
  Future<Map<String, dynamic>> obtenerEstadisticas() async {
    try {
      final snapshot = await _firestore.collection(_coleccion).get();

      if (snapshot.docs.isEmpty) {
        return {
          'total': 0,
          'promedio': 0.0,
          'distribucion': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      int total = snapshot.docs.length;
      int sumaValoraciones = 0;
      Map<int, int> distribucion = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final valoracion = (data['valoracion'] ?? 0) as int;
        sumaValoraciones += valoracion;
        distribucion[valoracion] = (distribucion[valoracion] ?? 0) + 1;
      }

      return {
        'total': total,
        'promedio': sumaValoraciones / total,
        'distribucion': distribucion,
      };
    } catch (e) {
      print('❌ Error al obtener estadísticas: $e');
      return {
        'total': 0,
        'promedio': 0.0,
        'distribucion': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }
  }
}
