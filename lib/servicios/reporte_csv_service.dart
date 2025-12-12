import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;

/// Servicio para generar reportes en formato CSV con alias legibles
class ReporteCsvService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Genera un reporte completo en CSV con datos de todas las colecciones
  Future<void> generarReporteCompleto() async {
    try {
      debugPrint('🔄 Iniciando generación de reporte CSV...');

      // Obtener datos de Firebase
      debugPrint('📊 Obteniendo datos desde Firebase...');

      final productos = await _obtenerProductos();
      debugPrint('✅ Productos obtenidos: ${productos.length}');

      final promociones = await _obtenerPromociones();
      debugPrint('✅ Promociones obtenidas: ${promociones.length}');

      final pedidos = await _obtenerPedidos();
      debugPrint('✅ Pedidos obtenidos: ${pedidos.length}');

      final usuarios = await _obtenerUsuarios();
      debugPrint('✅ Usuarios obtenidos: ${usuarios.length}');

      // Generar contenido CSV
      debugPrint('📝 Generando contenido CSV...');
      final csvContent = StringBuffer();

      // Sección de Productos
      csvContent.writeln('===== PRODUCTOS =====');
      csvContent.writeln(_generarCsvProductos(productos));
      csvContent.writeln('');

      // Sección de Promociones
      csvContent.writeln('===== PROMOCIONES =====');
      csvContent.writeln(_generarCsvPromociones(promociones));
      csvContent.writeln('');

      // Sección de Pedidos
      csvContent.writeln('===== PEDIDOS =====');
      csvContent.writeln(_generarCsvPedidos(pedidos));
      csvContent.writeln('');

      // Sección de Usuarios
      csvContent.writeln('===== USUARIOS =====');
      csvContent.writeln(_generarCsvUsuarios(usuarios));

      // Descargar el archivo CSV
      debugPrint('💾 Descargando archivo CSV...');
      await _descargarCsv(csvContent.toString());
      debugPrint('✅ Reporte CSV generado exitosamente');
    } catch (e, stackTrace) {
      debugPrint('❌ Error al generar reporte CSV: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Obtener productos desde Firebase
  Future<List<Map<String, dynamic>>> _obtenerProductos() async {
    try {
      final completer = Completer<List<Map<String, dynamic>>>();

      final subscription = _firestore
          .collection('productos')
          .snapshots()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: (sink) {
              sink.addError(TimeoutException('Timeout al obtener productos'));
            },
          )
          .listen(
            (snapshot) {
              if (!completer.isCompleted) {
                final productos = snapshot.docs.map((doc) {
                  final data = doc.data();
                  return {
                    'id': doc.id,
                    'nombre': data['nombre'] ?? '',
                    'categoria': data['categoria'] ?? '',
                    'precio': (data['precio'] ?? 0).toDouble(),
                    'stock': data['stock'] ?? 0,
                    'estado': data['estado'] ?? 'activo',
                    'descripcion': data['descripcion'] ?? '',
                  };
                }).toList();
                completer.complete(productos);
              }
            },
            onError: (error) {
              if (!completer.isCompleted) {
                completer.complete([]);
              }
            },
          );

      final result = await completer.future;
      await subscription.cancel();
      return result;
    } catch (e) {
      debugPrint('❌ Error al obtener productos: $e');
      return [];
    }
  }

  /// Obtener promociones desde Firebase
  Future<List<Map<String, dynamic>>> _obtenerPromociones() async {
    try {
      final completer = Completer<List<Map<String, dynamic>>>();

      final subscription = _firestore
          .collection('promociones')
          .snapshots()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: (sink) {
              sink.addError(TimeoutException('Timeout al obtener promociones'));
            },
          )
          .listen(
            (snapshot) {
              if (!completer.isCompleted) {
                final promociones = snapshot.docs.map((doc) {
                  final data = doc.data();
                  return {
                    'id': doc.id,
                    'titulo': data['titulo'] ?? '',
                    'descripcion': data['descripcion'] ?? '',
                    'descuento': (data['descuento'] ?? 0).toDouble(),
                    'productosAplicables': (data['productosAplicables'] as List<dynamic>?)?.length ?? 0,
                    'activa': data['activa'] ?? false,
                    'fechaInicio': _formatearFecha(data['fechaInicio']),
                    'fechaFin': _formatearFecha(data['fechaFin']),
                  };
                }).toList();
                completer.complete(promociones);
              }
            },
            onError: (error) {
              if (!completer.isCompleted) {
                completer.complete([]);
              }
            },
          );

      final result = await completer.future;
      await subscription.cancel();
      return result;
    } catch (e) {
      debugPrint('❌ Error al obtener promociones: $e');
      return [];
    }
  }

  /// Obtener pedidos desde Firebase
  Future<List<Map<String, dynamic>>> _obtenerPedidos() async {
    try {
      final completer = Completer<List<Map<String, dynamic>>>();

      final subscription = _firestore
          .collection('pedidos')
          .snapshots()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: (sink) {
              sink.addError(TimeoutException('Timeout al obtener pedidos'));
            },
          )
          .listen(
            (snapshot) {
              if (!completer.isCompleted) {
                final pedidos = snapshot.docs.map((doc) {
                  final data = doc.data();
                  final productos = (data['productos'] as List<dynamic>?) ??
                                   (data['items'] as List<dynamic>?) ?? [];

                  return {
                    'id': doc.id,
                    'numero': data['numero'] ?? doc.id.substring(0, 8),
                    'clienteId': data['clienteId'] ?? '',
                    'clienteNombre': data['clienteNombre'] ?? '',
                    'total': (data['total'] ?? 0).toDouble(),
                    'estado': data['estado'] ?? 'pendiente',
                    'metodoPago': data['metodoPago'] ?? '',
                    'fecha': _formatearFecha(data['fecha']),
                    'cantidadProductos': productos.length,
                  };
                }).toList();
                completer.complete(pedidos);
              }
            },
            onError: (error) {
              if (!completer.isCompleted) {
                completer.complete([]);
              }
            },
          );

      final result = await completer.future;
      await subscription.cancel();
      return result;
    } catch (e) {
      debugPrint('❌ Error al obtener pedidos: $e');
      return [];
    }
  }

  /// Obtener usuarios desde Firebase
  Future<List<Map<String, dynamic>>> _obtenerUsuarios() async {
    try {
      final completer = Completer<List<Map<String, dynamic>>>();

      final subscription = _firestore
          .collection('usuarios')
          .snapshots()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: (sink) {
              sink.addError(TimeoutException('Timeout al obtener usuarios'));
            },
          )
          .listen(
            (snapshot) {
              if (!completer.isCompleted) {
                final usuarios = snapshot.docs.map((doc) {
                  final data = doc.data();
                  return {
                    'id': doc.id,
                    'nombre': data['nombre'] ?? '',
                    'email': data['email'] ?? '',
                    'rol': data['rol'] ?? 'cliente',
                    'estado': data['estado'] ?? 'activo',
                    'telefono': data['telefono'] ?? '',
                    'fechaCreacion': _formatearFecha(data['fechaCreacion']),
                  };
                }).toList();
                completer.complete(usuarios);
              }
            },
            onError: (error) {
              if (!completer.isCompleted) {
                completer.complete([]);
              }
            },
          );

      final result = await completer.future;
      await subscription.cancel();
      return result;
    } catch (e) {
      debugPrint('❌ Error al obtener usuarios: $e');
      return [];
    }
  }

  /// Generar CSV de productos con ALIAS
  String _generarCsvProductos(List<Map<String, dynamic>> productos) {
    final buffer = StringBuffer();

    // Encabezados con ALIAS legibles
    buffer.writeln('ID,Nombre del Producto,Categoría,Precio (S/.),Stock Disponible,Estado,Descripción');

    // Datos
    for (var producto in productos) {
      buffer.writeln(_formatearFilaCsv([
        producto['id'].toString().substring(0, 8),
        producto['nombre'],
        producto['categoria'],
        producto['precio'].toStringAsFixed(2),
        producto['stock'].toString(),
        producto['estado'],
        producto['descripcion'],
      ]));
    }

    return buffer.toString();
  }

  /// Generar CSV de promociones con ALIAS
  String _generarCsvPromociones(List<Map<String, dynamic>> promociones) {
    final buffer = StringBuffer();

    // Encabezados con ALIAS legibles
    buffer.writeln('ID,Título de Promoción,Descripción,Descuento (%),Productos Aplicables,Estado,Fecha Inicio,Fecha Fin');

    // Datos
    for (var promo in promociones) {
      buffer.writeln(_formatearFilaCsv([
        promo['id'].toString().substring(0, 8),
        promo['titulo'],
        promo['descripcion'],
        promo['descuento'].toStringAsFixed(1),
        promo['productosAplicables'].toString(),
        promo['activa'] ? 'Activa' : 'Inactiva',
        promo['fechaInicio'],
        promo['fechaFin'],
      ]));
    }

    return buffer.toString();
  }

  /// Generar CSV de pedidos con ALIAS
  String _generarCsvPedidos(List<Map<String, dynamic>> pedidos) {
    final buffer = StringBuffer();

    // Encabezados con ALIAS legibles
    buffer.writeln('Número de Pedido,Cliente,Total (S/.),Estado del Pedido,Método de Pago,Fecha del Pedido,Cantidad de Productos');

    // Datos
    for (var pedido in pedidos) {
      buffer.writeln(_formatearFilaCsv([
        pedido['numero'],
        pedido['clienteNombre'],
        pedido['total'].toStringAsFixed(2),
        pedido['estado'],
        pedido['metodoPago'],
        pedido['fecha'],
        pedido['cantidadProductos'].toString(),
      ]));
    }

    return buffer.toString();
  }

  /// Generar CSV de usuarios con ALIAS
  String _generarCsvUsuarios(List<Map<String, dynamic>> usuarios) {
    final buffer = StringBuffer();

    // Encabezados con ALIAS legibles
    buffer.writeln('ID,Nombre Completo,Correo Electrónico,Rol,Estado,Teléfono,Fecha de Registro');

    // Datos
    for (var usuario in usuarios) {
      buffer.writeln(_formatearFilaCsv([
        usuario['id'].toString().substring(0, 8),
        usuario['nombre'],
        usuario['email'],
        usuario['rol'],
        usuario['estado'],
        usuario['telefono'],
        usuario['fechaCreacion'],
      ]));
    }

    return buffer.toString();
  }

  /// Formatear una fila CSV escapando comillas y comas
  String _formatearFilaCsv(List<String> campos) {
    return campos.map((campo) {
      // Escapar comillas dobles duplicándolas
      final escapado = campo.replaceAll('"', '""');
      // Envolver en comillas si contiene comas, saltos de línea o comillas
      if (escapado.contains(',') || escapado.contains('\n') || escapado.contains('"')) {
        return '"$escapado"';
      }
      return escapado;
    }).join(',');
  }

  /// Formatear fecha desde Timestamp o String
  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return 'N/A';

    try {
      if (fecha is Timestamp) {
        return DateFormat('dd/MM/yyyy').format(fecha.toDate());
      } else if (fecha is DateTime) {
        return DateFormat('dd/MM/yyyy').format(fecha);
      } else if (fecha is String) {
        final parsedDate = DateTime.tryParse(fecha);
        if (parsedDate != null) {
          return DateFormat('dd/MM/yyyy').format(parsedDate);
        }
        return fecha;
      }
      return fecha.toString();
    } catch (e) {
      return 'N/A';
    }
  }

  /// Descargar el archivo CSV en el navegador
  Future<void> _descargarCsv(String contenido) async {
    try {
      // Convertir a bytes UTF-8 con BOM para que Excel lo abra correctamente
      final contenidoConBom = '\uFEFF$contenido';
      final bytes = utf8.encode(contenidoConBom);

      final fechaActual = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final nombreArchivo = 'Reporte_Reposteria_Arlex_$fechaActual.csv';

      // Crear blob y descargar (para Flutter Web)
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', nombreArchivo)
        ..click();

      html.Url.revokeObjectUrl(url);

      debugPrint('✅ Reporte CSV generado exitosamente: $nombreArchivo');
    } catch (e) {
      debugPrint('❌ Error al descargar CSV: $e');
      rethrow;
    }
  }

  /// Genera un reporte CSV de pedidos para un usuario específico
  Future<void> generarReporteUsuario(String nombreCliente, List<DocumentSnapshot> pedidos) async {
    try {
      debugPrint('🔄 Generando reporte CSV para: $nombreCliente');

      final csvContent = StringBuffer();

      // Título
      csvContent.writeln('REPORTE DE PEDIDOS - $nombreCliente');
      csvContent.writeln('Fecha de generación: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');
      csvContent.writeln('');

      // Resumen
      double totalGastado = 0;
      int totalProductos = 0;
      for (var pedido in pedidos) {
        final data = pedido.data() as Map<String, dynamic>;
        totalGastado += (data['total'] ?? 0).toDouble();
        final items = data['items'] as List<dynamic>? ?? [];
        totalProductos += items.length;
      }

      csvContent.writeln('===== RESUMEN =====');
      csvContent.writeln('Total de Pedidos,${pedidos.length}');
      csvContent.writeln('Total Gastado,S/. ${totalGastado.toStringAsFixed(2)}');
      csvContent.writeln('Total de Productos,${totalProductos}');
      csvContent.writeln('');

      // Detalle de pedidos
      csvContent.writeln('===== DETALLE DE PEDIDOS =====');
      csvContent.writeln('Número de Pedido,Fecha,Estado,Método de Pago,Método de Entrega,Productos,Total (S/.)');

      for (var pedido in pedidos) {
        final data = pedido.data() as Map<String, dynamic>;
        final numeroPedido = data['numeroPedido'] ?? pedido.id;
        final fechaPedido = (data['fechaPedido'] as Timestamp?)?.toDate();
        final estado = data['estado'] ?? 'pendiente';
        final metodoPago = data['metodoPago'] ?? 'N/A';
        final metodoEntrega = data['metodoEntrega'] ?? 'N/A';
        final items = data['items'] as List<dynamic>? ?? [];
        final total = (data['total'] ?? 0).toDouble();

        final productosStr = items.map((item) {
          final nombre = item['productoNombre'] ?? 'Producto';
          final cantidad = item['cantidad'] ?? 1;
          return '$nombre (x$cantidad)';
        }).join('; ');

        csvContent.writeln(_formatearFilaCsv([
          numeroPedido.toString(),
          fechaPedido != null ? DateFormat('dd/MM/yyyy HH:mm').format(fechaPedido) : 'N/A',
          estado.toUpperCase(),
          metodoPago,
          metodoEntrega,
          productosStr,
          total.toStringAsFixed(2),
        ]));
      }

      // Descargar
      final fechaActual = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final nombreArchivo = 'Pedidos_${nombreCliente.replaceAll(' ', '_')}_$fechaActual.csv';

      final contenidoConBom = '\uFEFF${csvContent.toString()}';
      final bytes = utf8.encode(contenidoConBom);
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', nombreArchivo)
        ..click();
      html.Url.revokeObjectUrl(url);

      debugPrint('✅ Reporte CSV de usuario generado exitosamente');
    } catch (e, stackTrace) {
      debugPrint('❌ Error al generar reporte CSV de usuario: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
