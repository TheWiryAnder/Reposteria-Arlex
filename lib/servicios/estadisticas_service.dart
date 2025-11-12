import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio para obtener estadísticas del negocio
class EstadisticasService {
  static final EstadisticasService _instance = EstadisticasService._internal();
  factory EstadisticasService() => _instance;
  EstadisticasService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtener estadísticas generales
  Future<Map<String, dynamic>> obtenerEstadisticasGenerales() async {
    try {
      // Contar productos
      final productosSnapshot =
          await _firestore.collection('productos').where('disponible', isEqualTo: true).get();
      final totalProductos = productosSnapshot.docs.length;

      // Contar pedidos por estado
      final pedidosSnapshot = await _firestore.collection('pedidos').get();
      final totalPedidos = pedidosSnapshot.docs.length;

      int pedidosPendientes = 0;
      int pedidosEntregados = 0;
      double totalVentas = 0;
      double ventasHoy = 0;

      final hoy = DateTime.now();
      final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);

      for (var doc in pedidosSnapshot.docs) {
        final data = doc.data();
        final estado = data['estado'] ?? '';

        if (estado == 'pendiente' || estado == 'confirmado' || estado == 'preparando') {
          pedidosPendientes++;
        } else if (estado == 'entregado') {
          pedidosEntregados++;
        }

        final total = (data['total'] ?? 0.0).toDouble();
        totalVentas += total;

        // Verificar si es de hoy
        if (data['fechaPedido'] != null) {
          DateTime fechaPedido;
          if (data['fechaPedido'] is Timestamp) {
            fechaPedido = (data['fechaPedido'] as Timestamp).toDate();
          } else if (data['fechaPedido'] is String) {
            fechaPedido = DateTime.parse(data['fechaPedido']);
          } else {
            continue;
          }

          if (fechaPedido.isAfter(inicioHoy)) {
            ventasHoy += total;
          }
        }
      }

      // Contar usuarios
      final usuariosSnapshot = await _firestore.collection('usuarios').get();
      final totalUsuarios = usuariosSnapshot.docs.length;

      return {
        'totalProductos': totalProductos,
        'totalPedidos': totalPedidos,
        'pedidosPendientes': pedidosPendientes,
        'pedidosEntregados': pedidosEntregados,
        'totalUsuarios': totalUsuarios,
        'totalVentas': totalVentas,
        'ventasHoy': ventasHoy,
      };
    } catch (e) {
      return {
        'totalProductos': 0,
        'totalPedidos': 0,
        'pedidosPendientes': 0,
        'pedidosEntregados': 0,
        'totalUsuarios': 0,
        'totalVentas': 0.0,
        'ventasHoy': 0.0,
      };
    }
  }

  /// Obtener ventas del mes actual
  Future<double> obtenerVentasMes() async {
    try {
      final ahora = DateTime.now();
      final inicioMes = DateTime(ahora.year, ahora.month, 1);

      final snapshot = await _firestore
          .collection('pedidos')
          .where('fechaPedido', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioMes))
          .get();

      double totalVentas = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalVentas += (data['total'] ?? 0.0).toDouble();
      }

      return totalVentas;
    } catch (e) {
      return 0.0;
    }
  }

  /// Obtener productos con bajo stock
  Future<int> obtenerProductosBajoStock() async {
    try {
      final snapshot = await _firestore.collection('productos').get();

      int count = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final stock = data['stock'] ?? 0;
        final stockMinimo = data['stockMinimo'] ?? 5;

        if (stock < stockMinimo) {
          count++;
        }
      }

      return count;
    } catch (e) {
      return 0;
    }
  }

  /// Obtener pedidos del cliente
  Future<Map<String, int>> obtenerEstadisticasCliente(String clienteId) async {
    try {
      final snapshot = await _firestore
          .collection('pedidos')
          .where('clienteId', isEqualTo: clienteId)
          .get();

      int totalPedidos = 0;
      int pedidosEntregados = 0;
      int pedidosActivos = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final estado = data['estado'] ?? '';

        totalPedidos++;

        if (estado == 'entregado') {
          pedidosEntregados++;
        } else if (estado != 'cancelado') {
          pedidosActivos++;
        }
      }

      return {
        'totalPedidos': totalPedidos,
        'pedidosEntregados': pedidosEntregados,
        'pedidosActivos': pedidosActivos,
      };
    } catch (e) {
      return {
        'totalPedidos': 0,
        'pedidosEntregados': 0,
        'pedidosActivos': 0,
      };
    }
  }
}
