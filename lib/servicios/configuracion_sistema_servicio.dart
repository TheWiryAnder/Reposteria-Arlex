import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/configuracion_sistema_modelo.dart';

class ConfiguracionSistemaServicio {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _coleccion = 'configuracion_sistema';
  final String _documentoConfig = 'config';

  /// Obtener la configuración actual del sistema
  Future<ConfiguracionSistema?> obtenerConfiguracion() async {
    try {
      final doc = await _firestore
          .collection(_coleccion)
          .doc(_documentoConfig)
          .get();

      if (!doc.exists) {
        // Si no existe, crear configuración por defecto
        await crearConfiguracionPorDefecto();
        return await obtenerConfiguracion();
      }

      return ConfiguracionSistema.fromFirestore(doc);
    } catch (e) {
      print('Error al obtener configuración del sistema: $e');
      rethrow;
    }
  }

  /// Stream para escuchar cambios en tiempo real
  Stream<ConfiguracionSistema?> streamConfiguracion() {
    return _firestore
        .collection(_coleccion)
        .doc(_documentoConfig)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return null;
      }
      return ConfiguracionSistema.fromFirestore(doc);
    });
  }

  /// Actualizar toda la configuración
  Future<void> actualizarConfiguracion(
    ConfiguracionSistema configuracion,
    String usuarioId,
  ) async {
    try {
      final data = configuracion.toFirestore();
      data['fechaActualizacion'] = FieldValue.serverTimestamp();
      data['modificadoPor'] = usuarioId;

      await _firestore
          .collection(_coleccion)
          .doc(_documentoConfig)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      print('Error al actualizar configuración: $e');
      rethrow;
    }
  }

  /// Actualizar solo los módulos visibles
  Future<void> actualizarModulos(
    ModulosVisibles modulos,
    String usuarioId,
  ) async {
    try {
      await _firestore
          .collection(_coleccion)
          .doc(_documentoConfig)
          .update({
        'modulos': modulos.toMap(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'modificadoPor': usuarioId,
      });
    } catch (e) {
      print('Error al actualizar módulos: $e');
      rethrow;
    }
  }

  /// Actualizar solo las características
  Future<void> actualizarCaracteristicas(
    CaracteristicasHabilitadas caracteristicas,
    String usuarioId,
  ) async {
    try {
      await _firestore
          .collection(_coleccion)
          .doc(_documentoConfig)
          .update({
        'caracteristicas': caracteristicas.toMap(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'modificadoPor': usuarioId,
      });
    } catch (e) {
      print('Error al actualizar características: $e');
      rethrow;
    }
  }

  /// Actualizar solo las secciones de inicio
  Future<void> actualizarSeccionesInicio(
    SeccionesInicio secciones,
    String usuarioId,
  ) async {
    try {
      await _firestore
          .collection(_coleccion)
          .doc(_documentoConfig)
          .update({
        'seccionesInicio': secciones.toMap(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'modificadoPor': usuarioId,
      });
    } catch (e) {
      print('Error al actualizar secciones de inicio: $e');
      rethrow;
    }
  }

  /// Actualizar solo la configuración de productos
  Future<void> actualizarConfiguracionProductos(
    ConfiguracionProductos productos,
    String usuarioId,
  ) async {
    try {
      await _firestore
          .collection(_coleccion)
          .doc(_documentoConfig)
          .update({
        'productos': productos.toMap(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'modificadoPor': usuarioId,
      });
    } catch (e) {
      print('Error al actualizar configuración de productos: $e');
      rethrow;
    }
  }

  /// Actualizar solo la configuración de pedidos
  Future<void> actualizarConfiguracionPedidos(
    ConfiguracionPedidos pedidos,
    String usuarioId,
  ) async {
    try {
      await _firestore
          .collection(_coleccion)
          .doc(_documentoConfig)
          .update({
        'pedidos': pedidos.toMap(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'modificadoPor': usuarioId,
      });
    } catch (e) {
      print('Error al actualizar configuración de pedidos: $e');
      rethrow;
    }
  }

  /// Toggle rápido de un módulo específico
  Future<void> toggleModulo(
    String nombreModulo,
    bool estado,
    String usuarioId,
  ) async {
    try {
      await _firestore
          .collection(_coleccion)
          .doc(_documentoConfig)
          .update({
        'modulos.$nombreModulo': estado,
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'modificadoPor': usuarioId,
      });
    } catch (e) {
      print('Error al cambiar estado del módulo $nombreModulo: $e');
      rethrow;
    }
  }

  /// Toggle rápido de una característica específica
  Future<void> toggleCaracteristica(
    String nombreCaracteristica,
    bool estado,
    String usuarioId,
  ) async {
    try {
      await _firestore
          .collection(_coleccion)
          .doc(_documentoConfig)
          .update({
        'caracteristicas.$nombreCaracteristica': estado,
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'modificadoPor': usuarioId,
      });
    } catch (e) {
      print('Error al cambiar estado de la característica $nombreCaracteristica: $e');
      rethrow;
    }
  }

  /// Toggle rápido de una sección de inicio
  Future<void> toggleSeccionInicio(
    String nombreSeccion,
    bool estado,
    String usuarioId,
  ) async {
    try {
      await _firestore
          .collection(_coleccion)
          .doc(_documentoConfig)
          .update({
        'seccionesInicio.$nombreSeccion': estado,
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'modificadoPor': usuarioId,
      });
    } catch (e) {
      print('Error al cambiar estado de la sección $nombreSeccion: $e');
      rethrow;
    }
  }

  /// Crear configuración por defecto
  Future<void> crearConfiguracionPorDefecto() async {
    try {
      final configuracion = ConfiguracionSistema(
        id: _documentoConfig,
        modulos: ModulosVisibles(),
        caracteristicas: CaracteristicasHabilitadas(),
        seccionesInicio: SeccionesInicio(),
        productos: ConfiguracionProductos(),
        pedidos: ConfiguracionPedidos(),
        fechaActualizacion: DateTime.now(),
        modificadoPor: 'sistema',
      );

      await _firestore
          .collection(_coleccion)
          .doc(_documentoConfig)
          .set(configuracion.toFirestore());
    } catch (e) {
      print('Error al crear configuración por defecto: $e');
      rethrow;
    }
  }

  /// Verificar si existe la configuración
  Future<bool> existeConfiguracion() async {
    try {
      final doc = await _firestore
          .collection(_coleccion)
          .doc(_documentoConfig)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error al verificar existencia de configuración: $e');
      return false;
    }
  }

  /// Restaurar configuración a valores por defecto
  Future<void> restaurarPorDefecto(String usuarioId) async {
    try {
      final configuracion = ConfiguracionSistema(
        id: _documentoConfig,
        modulos: ModulosVisibles(),
        caracteristicas: CaracteristicasHabilitadas(),
        seccionesInicio: SeccionesInicio(),
        productos: ConfiguracionProductos(),
        pedidos: ConfiguracionPedidos(),
        fechaActualizacion: DateTime.now(),
        modificadoPor: usuarioId,
      );

      await _firestore
          .collection(_coleccion)
          .doc(_documentoConfig)
          .set(configuracion.toFirestore());
    } catch (e) {
      print('Error al restaurar configuración por defecto: $e');
      rethrow;
    }
  }
}
