import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio para gestionar la cola de pedidos y transiciones automáticas de estado
class ColaPedidosService {
  static final ColaPedidosService _instance = ColaPedidosService._internal();
  factory ColaPedidosService() => _instance;
  ColaPedidosService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _coleccion = 'pedidos';

  // Mapa para trackear timers activos por pedido
  final Map<String, Timer> _timersActivos = {};

  /// Calcular tiempo de preparación según cantidad de productos
  /// PARA PRUEBAS: Usando minutos en lugar de horas
  /// - 1-4 productos: 2 minutos (simulando 1 hora)
  /// - 5-8 productos: 5 minutos (simulando 4 horas)
  /// - 9+ productos: 10 minutos (simulando 8 horas)
  ///
  /// PRODUCCIÓN: Cambiar a Duration(hours: X)
  Duration calcularTiempoPreparacion(int cantidadProductos) {
    if (cantidadProductos <= 4) {
      return const Duration(minutes: 2); // Cambiar a hours: 1 en producción
    } else if (cantidadProductos <= 8) {
      return const Duration(minutes: 5); // Cambiar a hours: 4 en producción
    } else {
      return const Duration(minutes: 10); // Cambiar a hours: 8 en producción
    }
  }

  /// Obtener cantidad total de productos en un pedido
  int _obtenerCantidadTotal(List<dynamic> items) {
    int total = 0;
    for (var item in items) {
      total += (item['cantidad'] as int? ?? 0);
    }
    return total;
  }

  /// Procesar nuevo pedido y agregarlo a la cola
  Future<void> procesarNuevoPedido(String pedidoId) async {
    try {
      // Obtener el pedido
      final pedidoDoc = await _firestore.collection(_coleccion).doc(pedidoId).get();
      if (!pedidoDoc.exists) return;

      final pedidoData = pedidoDoc.data()!;
      final items = pedidoData['items'] as List<dynamic>? ?? [];
      final cantidadTotal = _obtenerCantidadTotal(items);

      // Calcular tiempo de preparación
      final tiempoPreparacion = calcularTiempoPreparacion(cantidadTotal);
      final tiempoEstimado = DateTime.now().add(tiempoPreparacion);

      // Verificar si hay pedidos en proceso
      final pedidosEnProceso = await _firestore
          .collection(_coleccion)
          .where('estado', isEqualTo: 'en_proceso')
          .get();

      String nuevoEstado;
      if (pedidosEnProceso.docs.isEmpty) {
        // No hay pedidos en proceso, este pedido pasa directo a proceso
        nuevoEstado = 'en_proceso';

        // Programar transición automática a 'listo'
        _programarTransicion(
          pedidoId: pedidoId,
          duracion: tiempoPreparacion,
          estadoDestino: 'listo',
        );
      } else {
        // Hay pedidos en proceso, este queda pendiente
        nuevoEstado = 'pendiente';
      }

      // Actualizar el pedido con el estado y tiempo estimado
      await _firestore.collection(_coleccion).doc(pedidoId).update({
        'estado': nuevoEstado,
        'tiempoEstimadoCompletado': Timestamp.fromDate(tiempoEstimado),
        'tiempoPreparacionMinutos': tiempoPreparacion.inMinutes,
      });

      // Si está pendiente, suscribirse a cambios para detectar cuando puede pasar a proceso
      if (nuevoEstado == 'pendiente') {
        _monitorearCola();
      }
    } catch (e) {
      print('Error al procesar nuevo pedido: $e');
    }
  }

  /// Programar transición automática de estado después de un tiempo
  void _programarTransicion({
    required String pedidoId,
    required Duration duracion,
    required String estadoDestino,
  }) {
    // Cancelar timer existente si lo hay
    _timersActivos[pedidoId]?.cancel();

    // Crear nuevo timer
    _timersActivos[pedidoId] = Timer(duracion, () async {
      try {
        await _firestore.collection(_coleccion).doc(pedidoId).update({
          'estado': estadoDestino,
          'fechaActualizacion': FieldValue.serverTimestamp(),
        });

        // Registrar en historial
        await _firestore
            .collection(_coleccion)
            .doc(pedidoId)
            .collection('historial')
            .add({
          'estado': estadoDestino,
          'comentario': 'Transición automática a $estadoDestino',
          'fecha': FieldValue.serverTimestamp(),
          'automatico': true,
        });

        // Si el pedido pasó a 'listo' o 'completado', procesar siguiente en cola
        if (estadoDestino == 'listo' || estadoDestino == 'completado') {
          await _procesarSiguienteEnCola();
        }

        // Limpiar timer
        _timersActivos.remove(pedidoId);
      } catch (e) {
        print('Error en transición automática: $e');
      }
    });
  }

  /// Monitorear la cola y procesar pedidos pendientes
  void _monitorearCola() {
    _firestore
        .collection(_coleccion)
        .where('estado', whereIn: ['en_proceso', 'listo', 'completado'])
        .snapshots()
        .listen((snapshot) {
      // Cuando cambia algún pedido en proceso, verificar si hay pendientes
      _procesarSiguienteEnCola();
    }, onError: (error) {
      // Silenciar errores de permisos cuando el usuario cierra sesión
      if (!error.toString().contains('permission-denied')) {
        print('Error monitoreando cola: $error');
      }
    });
  }

  /// Procesar el siguiente pedido en la cola (pendiente -> en_proceso)
  Future<void> _procesarSiguienteEnCola() async {
    try {
      // Verificar si hay algún pedido en proceso
      final enProceso = await _firestore
          .collection(_coleccion)
          .where('estado', isEqualTo: 'en_proceso')
          .limit(1)
          .get();

      // Si hay un pedido en proceso, no hacer nada
      if (enProceso.docs.isNotEmpty) return;

      // Obtener el pedido pendiente más antiguo
      final pendientes = await _firestore
          .collection(_coleccion)
          .where('estado', isEqualTo: 'pendiente')
          .orderBy('fechaPedido', descending: false)
          .limit(1)
          .get();

      if (pendientes.docs.isEmpty) return;

      final pedidoPendiente = pendientes.docs.first;
      final pedidoId = pedidoPendiente.id;
      final pedidoData = pedidoPendiente.data();

      // Obtener tiempo de preparación guardado
      final tiempoPreparacionMin = pedidoData['tiempoPreparacionMinutos'] as int? ?? 60;
      final tiempoPreparacion = Duration(minutes: tiempoPreparacionMin);

      // Actualizar a 'en_proceso'
      await _firestore.collection(_coleccion).doc(pedidoId).update({
        'estado': 'en_proceso',
        'fechaInicioProceso': FieldValue.serverTimestamp(),
      });

      // Programar transición a 'listo'
      _programarTransicion(
        pedidoId: pedidoId,
        duracion: tiempoPreparacion,
        estadoDestino: 'listo',
      );

      // Registrar en historial
      await _firestore
          .collection(_coleccion)
          .doc(pedidoId)
          .collection('historial')
          .add({
        'estado': 'en_proceso',
        'comentario': 'Pedido pasó de pendiente a en proceso automáticamente',
        'fecha': FieldValue.serverTimestamp(),
        'automatico': true,
      });
    } catch (e) {
      // Silenciar errores de permisos cuando el usuario cierra sesión
      if (!e.toString().contains('permission-denied')) {
        print('Error al procesar siguiente en cola: $e');
      }
    }
  }

  /// Marcar pedido como completado manualmente
  Future<void> marcarComoCompletado(String pedidoId) async {
    try {
      // Cancelar timer si existe
      _timersActivos[pedidoId]?.cancel();
      _timersActivos.remove(pedidoId);

      // Actualizar estado
      await _firestore.collection(_coleccion).doc(pedidoId).update({
        'estado': 'completado',
        'fechaCompletado': FieldValue.serverTimestamp(),
      });

      // Procesar siguiente en cola
      await _procesarSiguienteEnCola();
    } catch (e) {
      print('Error al marcar como completado: $e');
    }
  }

  /// Cancelar pedido
  Future<void> cancelarPedido(String pedidoId, String motivo) async {
    try {
      // Cancelar timer si existe
      _timersActivos[pedidoId]?.cancel();
      _timersActivos.remove(pedidoId);

      // Actualizar estado
      await _firestore.collection(_coleccion).doc(pedidoId).update({
        'estado': 'cancelado',
        'fechaCancelacion': FieldValue.serverTimestamp(),
        'motivoCancelacion': motivo,
      });

      // Procesar siguiente en cola
      await _procesarSiguienteEnCola();
    } catch (e) {
      print('Error al cancelar pedido: $e');
    }
  }

  /// Inicializar cola procesando todos los pedidos existentes
  /// Esto se debe llamar al iniciar la aplicación
  Future<void> inicializarCola() async {
    try {
      print('🔄 Inicializando cola de pedidos...');

      // Obtener todos los pedidos pendientes ordenados por fecha
      final pedidosPendientes = await _firestore
          .collection(_coleccion)
          .where('estado', isEqualTo: 'pendiente')
          .orderBy('fechaPedido', descending: false) // Los más antiguos primero
          .get();

      // Verificar si hay algún pedido en proceso
      final pedidosEnProceso = await _firestore
          .collection(_coleccion)
          .where('estado', isEqualTo: 'en_proceso')
          .get();

      if (pedidosEnProceso.docs.isEmpty && pedidosPendientes.docs.isNotEmpty) {
        // No hay pedidos en proceso, procesar el primero pendiente
        final primerPedido = pedidosPendientes.docs.first;
        print('✅ Procesando primer pedido pendiente: ${primerPedido.id}');
        await procesarNuevoPedido(primerPedido.id);
      } else if (pedidosEnProceso.docs.isNotEmpty) {
        // Hay pedidos en proceso, restaurar sus timers
        for (var doc in pedidosEnProceso.docs) {
          final data = doc.data();
          final tiempoEstimado = data['tiempoEstimadoCompletado'] as Timestamp?;

          if (tiempoEstimado != null) {
            final ahora = DateTime.now();
            final completado = tiempoEstimado.toDate();
            final duracionRestante = completado.difference(ahora);

            if (duracionRestante.isNegative) {
              // Ya debería estar listo
              print('⏰ Pedido ${doc.id} ya debería estar listo, marcando...');
              await _firestore.collection(_coleccion).doc(doc.id).update({
                'estado': 'listo',
              });
              await _procesarSiguienteEnCola();
            } else {
              // Restaurar timer
              print('⏱️ Restaurando timer para pedido ${doc.id}: ${duracionRestante.inMinutes} min restantes');
              _programarTransicion(
                pedidoId: doc.id,
                duracion: duracionRestante,
                estadoDestino: 'listo',
              );
            }
          }
        }
      }

      print('✅ Cola de pedidos inicializada exitosamente');
    } catch (e) {
      print('❌ Error al inicializar cola: $e');
    }
  }

  /// Limpiar todos los timers
  void dispose() {
    for (var timer in _timersActivos.values) {
      timer.cancel();
    }
    _timersActivos.clear();
  }
}
