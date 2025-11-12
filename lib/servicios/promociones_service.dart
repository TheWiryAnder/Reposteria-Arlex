import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_firestore_service.dart';

/// Servicio para gestión de promociones del carrusel
class PromocionesService {
  static final PromocionesService _instance = PromocionesService._internal();
  factory PromocionesService() => _instance;
  PromocionesService._internal();

  final FirebaseFirestoreService _firestore = FirebaseFirestoreService();
  static const String _coleccion = 'promociones';

  /// Obtener promociones del carrusel activas
  Future<List<Map<String, dynamic>>> obtenerPromocionesCarrusel() async {
    try {
      final datos = await _firestore.consultarDonde(
        coleccion: _coleccion,
        campo: 'activa',
        valor: true,
        orderBy: 'orden',
      );

      return datos;
    } catch (e) {
      return [];
    }
  }

  /// Stream de promociones del carrusel
  Stream<List<Map<String, dynamic>>> streamPromocionesCarrusel() {
    return _firestore
        .streamDonde(
      coleccion: _coleccion,
      campo: 'activa',
      valor: true,
      orderBy: 'orden',
    )
        .map((lista) => lista);
  }

  /// Obtener todas las promociones
  Future<List<Map<String, dynamic>>> obtenerTodasPromociones() async {
    try {
      return await _firestore.obtenerTodos(
        coleccion: _coleccion,
        orderBy: 'fechaCreacion',
        descending: true,
      );
    } catch (e) {
      return [];
    }
  }

  /// Crear promoción
  Future<Map<String, dynamic>> crearPromocion(
      Map<String, dynamic> datos) async {
    try {
      datos['fechaCreacion'] = FieldValue.serverTimestamp();

      return await _firestore.crear(
        coleccion: _coleccion,
        documentId: datos['id'],
        datos: datos,
      );
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al crear promoción: $e',
      };
    }
  }

  /// Actualizar promoción
  Future<Map<String, dynamic>> actualizarPromocion({
    required String promocionId,
    required Map<String, dynamic> cambios,
  }) async {
    return await _firestore.actualizar(
      coleccion: _coleccion,
      documentId: promocionId,
      datos: cambios,
    );
  }

  /// Eliminar promoción
  Future<Map<String, dynamic>> eliminarPromocion(String promocionId) async {
    return await _firestore.eliminar(
      coleccion: _coleccion,
      documentId: promocionId,
    );
  }

  /// Activar/desactivar promoción
  Future<Map<String, dynamic>> cambiarEstadoPromocion({
    required String promocionId,
    required bool activa,
  }) async {
    return await actualizarPromocion(
      promocionId: promocionId,
      cambios: {'activa': activa},
    );
  }
}
