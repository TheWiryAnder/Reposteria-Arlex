import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../modelos/carrito_modelo.dart';
import 'firebase_firestore_service.dart';
import 'productos_service.dart';

/// Servicio específico para gestión de pedidos
class PedidosService {
  static final PedidosService _instance = PedidosService._internal();
  factory PedidosService() => _instance;
  PedidosService._internal();

  final FirebaseFirestoreService _firestore = FirebaseFirestoreService();
  final ProductosService _productosService = ProductosService();
  static const String _coleccion = 'pedidos';

  // ============================================================================
  // CREAR PEDIDO
  // ============================================================================

  /// Crear nuevo pedido desde el carrito
  Future<Map<String, dynamic>> crearPedido({
    required String clienteId,
    required String clienteNombre,
    required String clienteEmail,
    required String clienteTelefono,
    required CarritoModelo carrito,
    required String metodoEntrega, // "domicilio" | "tienda"
    required String metodoPago, // "efectivo" | "transferencia" | "tarjeta"
    String? direccionEntrega,
    String? notasCliente,
    String? comprobanteUrl, // URL del comprobante de pago
    double costoEnvio = 0,
    double descuento = 0,
    double iva = 0,
  }) async {
    try {
      // 0. Verificar que el usuario esté autenticado en Firebase Auth
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        return {
          'success': false,
          'message': 'No hay usuario autenticado en Firebase Auth. Por favor inicia sesión nuevamente.',
        };
      }

      // Verificar que el clienteId coincida con el UID de Firebase Auth
      if (clienteId != firebaseUser.uid) {
        print('ERROR - clienteId ($clienteId) no coincide con Firebase Auth UID (${firebaseUser.uid})');
        return {
          'success': false,
          'message': 'Error de autenticación. El ID del usuario no coincide. Por favor inicia sesión nuevamente.',
        };
      }

      print('DEBUG - Usuario autenticado en Firebase Auth: ${firebaseUser.uid}');
      print('DEBUG - Email: ${firebaseUser.email}');

      // 1. Generar número de pedido único
      print('DEBUG - Generando número de pedido...');
      final numeroPedido = await _generarNumeroPedido();
      print('DEBUG - Número de pedido generado: $numeroPedido');

      // 2. Preparar items del pedido
      final items = carrito.items.map((item) {
        return {
          'productoId': item.producto.id,
          'productoNombre': item.producto.nombre,
          'productoImagen': item.producto.imagenUrl ?? '',
          'cantidad': item.cantidad,
          'precioUnitario': item.producto.precio,
          'subtotal': item.subtotal,
          'notasEspeciales': item.notasEspeciales ?? '',
        };
      }).toList();

      // 3. Calcular totales
      final subtotal = carrito.total;
      final total = subtotal + iva + costoEnvio - descuento;

      // 4. Crear el pedido
      final pedidoId = 'ped_${DateTime.now().millisecondsSinceEpoch}';

      final datosPedido = {
        'id': pedidoId,
        'numeroPedido': numeroPedido,
        'clienteId': clienteId,
        'clienteNombre': clienteNombre,
        'clienteEmail': clienteEmail,
        'clienteTelefono': clienteTelefono,
        'items': items,
        'subtotal': subtotal,
        'iva': iva,
        'costoEnvio': costoEnvio,
        'descuento': descuento,
        'total': total,
        'metodoEntrega': metodoEntrega,
        'direccionEntrega': direccionEntrega ?? '',
        'metodoPago': metodoPago,
        'comprobanteUrl': comprobanteUrl ?? '', // URL del comprobante de pago
        'estadoPago': 'pendiente',
        'estado': 'pendiente',
        'notasCliente': notasCliente ?? '',
        'notasInternas': '',
        'fechaPedido': FieldValue.serverTimestamp(),
      };

      print('DEBUG - Intentando crear pedido en Firestore...');
      print('DEBUG - Pedido ID: $pedidoId');
      print('DEBUG - Cliente ID: $clienteId');

      final resultado = await _firestore.crear(
        coleccion: _coleccion,
        documentId: pedidoId,
        datos: datosPedido,
      );

      print('DEBUG - Resultado de crear pedido: ${resultado['success']}');
      if (resultado['message'] != null) {
        print('DEBUG - Mensaje: ${resultado['message']}');
      }

      if (resultado['success']) {
        print('DEBUG - Pedido creado exitosamente, registrando historial...');
        // 5. Registrar en historial (intentar, pero no fallar si hay error)
        try {
          await _agregarHistorial(
            pedidoId: pedidoId,
            estado: 'pendiente',
            comentario: 'Pedido creado',
            usuarioId: clienteId,
            usuarioNombre: clienteNombre,
          );
          print('DEBUG - Historial registrado exitosamente');
        } catch (e) {
          print('DEBUG - ⚠️ No se pudo registrar historial (no crítico): $e');
          // No fallar por esto, el pedido ya está creado
        }

        // 6. Actualizar stock de productos (intentar, pero no es crítico)
        print('DEBUG - Actualizando stock de productos...');
        try {
          for (var item in carrito.items) {
            print('DEBUG - Actualizando stock para: ${item.producto.nombre}');
            await _productosService.decrementarStock(
              productoId: item.producto.id,
              cantidad: item.cantidad,
            );

            await _productosService.actualizarEstadisticasVenta(
              productoId: item.producto.id,
              cantidadVendida: item.cantidad,
            );
          }
          print('DEBUG - Stock actualizado exitosamente');
        } catch (e) {
          print('DEBUG - ⚠️ No se pudo actualizar stock (no crítico): $e');
          // No fallar por esto, el pedido ya está creado
        }

        print('DEBUG - ✅ Pedido completo creado exitosamente!');
        return {
          'success': true,
          'message': 'Pedido creado exitosamente',
          'pedidoId': pedidoId,
          'numeroPedido': numeroPedido,
        };
      }

      print('DEBUG - ❌ Error al crear pedido: ${resultado['message']}');
      return resultado;
    } catch (e) {
      print('DEBUG - ❌ EXCEPCIÓN al crear pedido: $e');
      return {
        'success': false,
        'message': 'Error al crear pedido: $e',
      };
    }
  }

  /// Generar número de pedido único (formato: ORD-2025-0001)
  Future<String> _generarNumeroPedido() async {
    final ahora = DateTime.now();
    final anio = ahora.year;
    final mes = ahora.month.toString().padLeft(2, '0');

    // Contar pedidos del mes actual
    final inicio = DateTime(ahora.year, ahora.month, 1);
    final fin = DateTime(ahora.year, ahora.month + 1, 0, 23, 59, 59);

    final snapshot = await FirebaseFirestore.instance
        .collection(_coleccion)
        .where('fechaPedido', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fechaPedido', isLessThanOrEqualTo: Timestamp.fromDate(fin))
        .count()
        .get();

    final numero = (snapshot.count ?? 0) + 1;
    final numeroFormateado = numero.toString().padLeft(4, '0');

    return 'ORD-$anio$mes-$numeroFormateado';
  }

  // ============================================================================
  // ACTUALIZAR PEDIDO
  // ============================================================================

  /// Actualizar estado del pedido
  Future<Map<String, dynamic>> actualizarEstado({
    required String pedidoId,
    required String nuevoEstado,
    required String usuarioId,
    required String usuarioNombre,
    String? comentario,
  }) async {
    try {
      final Map<String, dynamic> cambios = {
        'estado': nuevoEstado,
      };

      // Agregar timestamp según el estado
      switch (nuevoEstado) {
        case 'confirmado':
          cambios['fechaConfirmacion'] = FieldValue.serverTimestamp();
          break;
        case 'preparando':
          cambios['fechaPreparacion'] = FieldValue.serverTimestamp();
          break;
        case 'entregado':
          cambios['fechaEntrega'] = FieldValue.serverTimestamp();
          break;
        case 'cancelado':
          cambios['fechaCancelacion'] = FieldValue.serverTimestamp();
          break;
      }

      // Actualizar pedido
      await FirebaseFirestore.instance
          .collection(_coleccion)
          .doc(pedidoId)
          .update(cambios);

      // Registrar en historial
      await _agregarHistorial(
        pedidoId: pedidoId,
        estado: nuevoEstado,
        comentario: comentario ?? 'Estado actualizado a $nuevoEstado',
        usuarioId: usuarioId,
        usuarioNombre: usuarioNombre,
      );

      return {
        'success': true,
        'message': 'Estado actualizado exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al actualizar estado: $e',
      };
    }
  }

  /// Actualizar estado de pago
  Future<Map<String, dynamic>> actualizarEstadoPago({
    required String pedidoId,
    required String estadoPago,
    String? referenciaPago,
  }) async {
    try {
      final Map<String, dynamic> cambios = {
        'estadoPago': estadoPago,
      };

      if (referenciaPago != null) {
        cambios['referenciaPago'] = referenciaPago;
      }

      return await _firestore.actualizar(
        coleccion: _coleccion,
        documentId: pedidoId,
        datos: cambios,
      );
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al actualizar estado de pago: $e',
      };
    }
  }

  /// Asignar empleado al pedido
  Future<Map<String, dynamic>> asignarEmpleado({
    required String pedidoId,
    required String empleadoId,
    required String tipoAsignacion, // "preparadoPor" | "entregadoPor"
  }) async {
    return await _firestore.actualizar(
      coleccion: _coleccion,
      documentId: pedidoId,
      datos: {tipoAsignacion: empleadoId},
    );
  }

  /// Agregar notas internas
  Future<Map<String, dynamic>> agregarNotasInternas({
    required String pedidoId,
    required String notas,
  }) async {
    return await _firestore.actualizar(
      coleccion: _coleccion,
      documentId: pedidoId,
      datos: {'notasInternas': notas},
    );
  }

  // ============================================================================
  // HISTORIAL DEL PEDIDO
  // ============================================================================

  /// Agregar entrada al historial del pedido
  Future<void> _agregarHistorial({
    required String pedidoId,
    required String estado,
    required String comentario,
    required String usuarioId,
    required String usuarioNombre,
  }) async {
    await _firestore.crearEnSubcoleccion(
      coleccion: _coleccion,
      documentId: pedidoId,
      subcoleccion: 'historial',
      datos: {
        'estado': estado,
        'comentario': comentario,
        'usuarioId': usuarioId,
        'usuarioNombre': usuarioNombre,
        'fecha': FieldValue.serverTimestamp(),
      },
    );
  }

  /// Obtener historial del pedido
  Future<List<Map<String, dynamic>>> obtenerHistorial(String pedidoId) async {
    return await _firestore.obtenerSubcoleccion(
      coleccion: _coleccion,
      documentId: pedidoId,
      subcoleccion: 'historial',
      orderBy: 'fecha',
      descending: true,
    );
  }

  /// Stream del historial
  Stream<List<Map<String, dynamic>>> streamHistorial(String pedidoId) {
    return _firestore.streamSubcoleccion(
      coleccion: _coleccion,
      documentId: pedidoId,
      subcoleccion: 'historial',
      orderBy: 'fecha',
      descending: true,
    );
  }

  // ============================================================================
  // CONSULTAS
  // ============================================================================

  /// Obtener pedido por ID
  Future<Map<String, dynamic>?> obtenerPedido(String pedidoId) async {
    return await _firestore.leer(
      coleccion: _coleccion,
      documentId: pedidoId,
    );
  }

  /// Obtener pedidos del cliente
  Future<List<Map<String, dynamic>>> obtenerPedidosCliente({
    required String clienteId,
    int? limite,
  }) async {
    return await _firestore.consultarDonde(
      coleccion: _coleccion,
      campo: 'clienteId',
      valor: clienteId,
      orderBy: 'fechaPedido',
      descending: true,
      limit: limite,
    );
  }

  /// Obtener pedidos por estado
  Future<List<Map<String, dynamic>>> obtenerPedidosPorEstado({
    required String estado,
    int? limite,
  }) async {
    return await _firestore.consultarDonde(
      coleccion: _coleccion,
      campo: 'estado',
      valor: estado,
      orderBy: 'fechaPedido',
      descending: true,
      limit: limite,
    );
  }

  /// Obtener todos los pedidos (con paginación)
  Future<List<Map<String, dynamic>>> obtenerTodosPedidos({
    int? limite,
  }) async {
    return await _firestore.obtenerTodos(
      coleccion: _coleccion,
      orderBy: 'fechaPedido',
      descending: true,
      limit: limite,
    );
  }

  // ============================================================================
  // STREAMS EN TIEMPO REAL
  // ============================================================================

  /// Stream de pedidos del cliente
  Stream<List<Map<String, dynamic>>> streamPedidosCliente(String clienteId) {
    return _firestore.streamDonde(
      coleccion: _coleccion,
      campo: 'clienteId',
      valor: clienteId,
      orderBy: 'fechaPedido',
      descending: true,
    );
  }

  /// Stream de pedidos por estado
  Stream<List<Map<String, dynamic>>> streamPedidosPorEstado(String estado) {
    return _firestore.streamDonde(
      coleccion: _coleccion,
      campo: 'estado',
      valor: estado,
      orderBy: 'fechaPedido',
      descending: true,
    );
  }

  /// Stream de un pedido específico
  Stream<Map<String, dynamic>?> streamPedido(String pedidoId) {
    return _firestore.streamDocumento(
      coleccion: _coleccion,
      documentId: pedidoId,
    );
  }

  /// Stream de todos los pedidos
  Stream<List<Map<String, dynamic>>> streamTodosPedidos({int? limite}) {
    return _firestore.streamColeccion(
      coleccion: _coleccion,
      orderBy: 'fechaPedido',
      descending: true,
      limit: limite,
    );
  }

  // ============================================================================
  // CALIFICACIONES
  // ============================================================================

  /// Calificar pedido
  Future<Map<String, dynamic>> calificarPedido({
    required String pedidoId,
    required int calificacion, // 1-5
    String? comentario,
  }) async {
    if (calificacion < 1 || calificacion > 5) {
      return {
        'success': false,
        'message': 'La calificación debe estar entre 1 y 5',
      };
    }

    return await _firestore.actualizar(
      coleccion: _coleccion,
      documentId: pedidoId,
      datos: {
        'calificacion': calificacion,
        'comentarioCalificacion': comentario ?? '',
        'fechaCalificacion': FieldValue.serverTimestamp(),
      },
    );
  }

  // ============================================================================
  // CANCELACIÓN
  // ============================================================================

  /// Cancelar pedido
  Future<Map<String, dynamic>> cancelarPedido({
    required String pedidoId,
    required String usuarioId,
    required String usuarioNombre,
    String? motivo,
  }) async {
    try {
      // Obtener pedido actual
      final pedido = await obtenerPedido(pedidoId);

      if (pedido == null) {
        return {
          'success': false,
          'message': 'Pedido no encontrado',
        };
      }

      // Verificar que se pueda cancelar
      final estadoActual = pedido['estado'];
      if (estadoActual == 'entregado' || estadoActual == 'cancelado') {
        return {
          'success': false,
          'message': 'No se puede cancelar un pedido $estadoActual',
        };
      }

      // Actualizar estado
      await actualizarEstado(
        pedidoId: pedidoId,
        nuevoEstado: 'cancelado',
        usuarioId: usuarioId,
        usuarioNombre: usuarioNombre,
        comentario: motivo ?? 'Pedido cancelado',
      );

      // Devolver stock (si el pedido estaba confirmado)
      if (estadoActual != 'pendiente') {
        final items = pedido['items'] as List;
        for (var item in items) {
          await _productosService.incrementarStock(
            productoId: item['productoId'],
            cantidad: item['cantidad'],
          );
        }
      }

      return {
        'success': true,
        'message': 'Pedido cancelado exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al cancelar pedido: $e',
      };
    }
  }

  // ============================================================================
  // ESTADÍSTICAS
  // ============================================================================

  /// Contar pedidos totales
  Future<int> contarPedidos({String? estado}) async {
    if (estado != null) {
      return await _firestore.contarDocumentos(
        coleccion: _coleccion,
        campo: 'estado',
        valor: estado,
      );
    }
    return await _firestore.contarDocumentos(coleccion: _coleccion);
  }

  /// Contar pedidos del cliente
  Future<int> contarPedidosCliente(String clienteId) async {
    return await _firestore.contarDocumentos(
      coleccion: _coleccion,
      campo: 'clienteId',
      valor: clienteId,
    );
  }
}
