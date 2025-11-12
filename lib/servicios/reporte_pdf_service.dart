import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;

/// Servicio para generar reportes en formato PDF con gráficos embebidos
class ReportePdfService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Genera el reporte completo en PDF con gráficos
  Future<void> generarReporteCompleto() async {
    // Obtener datos de Firebase
    final productos = await _obtenerProductos();
    final promociones = await _obtenerPromociones();
    final pedidos = await _obtenerPedidos();
    final usuarios = await _obtenerUsuarios();

    // Calcular estadísticas
    final estadisticas = _calcularEstadisticas(pedidos, productos);

    // Crear el documento PDF
    final pdf = pw.Document();

    // Agregar páginas
    _agregarPortada(pdf);
    _agregarResumenEjecutivo(pdf, estadisticas);
    await _agregarGraficos(pdf, pedidos, productos, estadisticas);
    _agregarTablaDatos(pdf, productos, promociones, pedidos, usuarios);

    // Descargar el PDF
    await _descargarPdf(pdf);
  }

  // ========== OBTENCIÓN DE DATOS ==========

  Future<List<Map<String, dynamic>>> _obtenerProductos() async {
    final snapshot = await _firestore.collection('productos').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'nombre': data['nombre'] ?? '',
        'categoria': data['categoria'] ?? '',
        'precio': (data['precio'] ?? 0).toDouble(),
        'stock': data['stock'] ?? 0,
        'estado': data['estado'] ?? 'activo',
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _obtenerPromociones() async {
    final snapshot = await _firestore.collection('promociones').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'titulo': data['titulo'] ?? '',
        'descuento': (data['descuento'] ?? 0).toDouble(),
        'activa': data['activa'] ?? false,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _obtenerPedidos() async {
    final snapshot = await _firestore.collection('pedidos').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'numero': data['numero'] ?? '',
        'total': (data['total'] ?? 0).toDouble(),
        'estado': data['estado'] ?? '',
        'metodoPago': data['metodoPago'] ?? '',
        'fecha': (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
        'productos': (data['productos'] as List?) ?? [],
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _obtenerUsuarios() async {
    final snapshot = await _firestore.collection('usuarios').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'nombre': data['nombre'] ?? '',
        'email': data['email'] ?? '',
        'rol': data['rol'] ?? 'cliente',
      };
    }).toList();
  }

  // ========== CÁLCULO DE ESTADÍSTICAS ==========

  Map<String, dynamic> _calcularEstadisticas(
    List<Map<String, dynamic>> pedidos,
    List<Map<String, dynamic>> productos,
  ) {
    final totalPedidos = pedidos.length;
    final totalVentas = pedidos.fold<double>(
      0.0,
      (sum, pedido) => sum + (pedido['total'] as double),
    );
    final promedioVenta = totalPedidos > 0 ? totalVentas / totalPedidos : 0.0;

    // Ventas por día (últimos 7 días)
    final hoy = DateTime.now();
    final ventasPorDia = <DateTime, double>{};
    for (var i = 6; i >= 0; i--) {
      final fecha = DateTime(hoy.year, hoy.month, hoy.day - i);
      ventasPorDia[fecha] = 0.0;
    }

    for (var pedido in pedidos) {
      final fecha = pedido['fecha'] as DateTime;
      final fechaSolo = DateTime(fecha.year, fecha.month, fecha.day);
      if (ventasPorDia.containsKey(fechaSolo)) {
        ventasPorDia[fechaSolo] =
            (ventasPorDia[fechaSolo] ?? 0) + (pedido['total'] as double);
      }
    }

    // Pedidos por estado
    final pedidosPorEstado = <String, int>{};
    for (var pedido in pedidos) {
      final estado = pedido['estado'] as String;
      pedidosPorEstado[estado] = (pedidosPorEstado[estado] ?? 0) + 1;
    }

    // Ventas por método de pago
    final ventasPorMetodo = <String, double>{};
    for (var pedido in pedidos) {
      final metodo = pedido['metodoPago'] as String;
      ventasPorMetodo[metodo] =
          (ventasPorMetodo[metodo] ?? 0) + (pedido['total'] as double);
    }

    // Productos con bajo stock
    final productosStockBajo = productos
        .where((p) => (p['stock'] as int) <= 10)
        .toList()
      ..sort((a, b) => (a['stock'] as int).compareTo(b['stock'] as int));

    // Calcular productos más vendidos (por cantidad en pedidos)
    final ventasPorProducto = <String, Map<String, dynamic>>{};
    for (var pedido in pedidos) {
      final productosPedido = pedido['productos'] as List<dynamic>? ?? [];
      for (var item in productosPedido) {
        if (item is Map) {
          final productoId = item['productoId'] ?? item['id'] ?? '';
          final cantidad = (item['cantidad'] ?? 1) as int;
          final nombre = item['nombre'] ?? 'Desconocido';

          if (ventasPorProducto.containsKey(productoId)) {
            ventasPorProducto[productoId]!['cantidad'] =
                (ventasPorProducto[productoId]!['cantidad'] as int) + cantidad;
          } else {
            ventasPorProducto[productoId] = {
              'id': productoId,
              'nombre': nombre,
              'cantidad': cantidad,
            };
          }
        }
      }
    }

    final top5Productos = ventasPorProducto.values.toList()
      ..sort((a, b) => (b['cantidad'] as int).compareTo(a['cantidad'] as int));

    // Productos por categoría
    final productosPorCategoria = <String, int>{};
    for (var producto in productos) {
      final categoria = producto['categoria'] as String;
      productosPorCategoria[categoria] = (productosPorCategoria[categoria] ?? 0) + 1;
    }

    return {
      'totalPedidos': totalPedidos,
      'totalVentas': totalVentas,
      'promedioVenta': promedioVenta,
      'ventasPorDia': ventasPorDia,
      'pedidosPorEstado': pedidosPorEstado,
      'ventasPorMetodo': ventasPorMetodo,
      'productosStockBajo': productosStockBajo.take(10).toList(),
      'top5Productos': top5Productos.take(5).toList(),
      'productosPorCategoria': productosPorCategoria,
    };
  }

  // ========== CREACIÓN DE PÁGINAS DEL PDF ==========

  void _agregarPortada(pw.Document pdf) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [
                  PdfColor.fromHex('#ef4444'),
                  PdfColor.fromHex('#dc2626'),
                ],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
            ),
            child: pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Repostería Arlex',
                    style: pw.TextStyle(
                      fontSize: 48,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Reporte de Gestión',
                    style: pw.TextStyle(
                      fontSize: 32,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'Fecha de generación:',
                          style: pw.TextStyle(
                            fontSize: 16,
                            color: PdfColor.fromHex('#dc2626'),
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _agregarResumenEjecutivo(
    pw.Document pdf,
    Map<String, dynamic> estadisticas,
  ) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Resumen Ejecutivo',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#dc2626'),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#fee2e2'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildMetricRow(
                      'Total de Pedidos',
                      '${estadisticas['totalPedidos']}',
                    ),
                    pw.SizedBox(height: 10),
                    _buildMetricRow(
                      'Total de Ventas',
                      'S/. ${(estadisticas['totalVentas'] as double).toStringAsFixed(2)}',
                    ),
                    pw.SizedBox(height: 10),
                    _buildMetricRow(
                      'Ticket Promedio',
                      'S/. ${(estadisticas['promedioVenta'] as double).toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Distribución de Pedidos por Estado',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              ...((estadisticas['pedidosPorEstado'] as Map<String, int>)
                  .entries
                  .map((entry) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Row(
                    children: [
                      pw.Text('• ${entry.key}: '),
                      pw.Text(
                        '${entry.value} pedidos',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                );
              })),
              pw.SizedBox(height: 20),
              pw.Text(
                'Ventas por Método de Pago',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              ...((estadisticas['ventasPorMetodo'] as Map<String, double>)
                  .entries
                  .map((entry) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Row(
                    children: [
                      pw.Text('• ${entry.key}: '),
                      pw.Text(
                        'S/. ${entry.value.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                );
              })),
            ],
          );
        },
      ),
    );
  }

  pw.Widget _buildMetricRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 16),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#dc2626'),
          ),
        ),
      ],
    );
  }

  Future<void> _agregarGraficos(
    pw.Document pdf,
    List<Map<String, dynamic>> pedidos,
    List<Map<String, dynamic>> productos,
    Map<String, dynamic> estadisticas,
  ) async {
    // Página de gráficos
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Text(
              'Análisis Visual',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#dc2626'),
              ),
            ),
            pw.SizedBox(height: 20),

            // Gráfico 1: Ventas por Día (representación en tabla)
            pw.Text(
              '1. Evolución de Ventas Diarias (Últimos 7 días)',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            _buildVentasDiariaChart(estadisticas['ventasPorDia'] as Map<DateTime, double>),
            pw.SizedBox(height: 30),

            // Gráfico 2: Pedidos por Estado (representación en barras ASCII)
            pw.Text(
              '2. Distribución de Pedidos por Estado',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            _buildPedidosPorEstadoChart(estadisticas['pedidosPorEstado'] as Map<String, int>),
            pw.SizedBox(height: 30),

            // Gráfico 3: Ventas por Método de Pago
            pw.Text(
              '3. Ventas por Método de Pago',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            _buildVentasPorMetodoChart(estadisticas['ventasPorMetodo'] as Map<String, double>),
            pw.SizedBox(height: 30),

            // Gráfico 4: Productos con Bajo Stock
            pw.Text(
              '4. Alerta: Productos con Stock Bajo (≤ 10 unidades)',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            _buildProductosStockBajoChart(estadisticas['productosStockBajo'] as List<Map<String, dynamic>>),
            pw.SizedBox(height: 30),

            // Gráfico 5: Top 5 Productos Más Vendidos
            pw.Text(
              '5. Top 5 Productos Más Vendidos',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            _buildTop5ProductosChart(estadisticas['top5Productos'] as List<Map<String, dynamic>>),
            pw.SizedBox(height: 30),

            // Gráfico 6: Productos por Categoría
            pw.Text(
              '6. Distribución de Productos por Categoría',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            _buildProductosPorCategoriaChart(estadisticas['productosPorCategoria'] as Map<String, int>),
          ];
        },
      ),
    );
  }

  pw.Widget _buildVentasDiariaChart(Map<DateTime, double> ventasPorDia) {
    final maxVenta = ventasPorDia.values.isEmpty ? 0.0 : ventasPorDia.values.reduce((a, b) => a > b ? a : b);

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#e5e7eb')),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: ventasPorDia.entries.map((entry) {
          final porcentaje = maxVenta > 0 ? (entry.value / maxVenta) : 0.0;
          final barWidth = porcentaje * 400;

          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 80,
                  child: pw.Text(
                    DateFormat('dd/MM').format(entry.key),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.Container(
                  width: barWidth,
                  height: 20,
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#3b82f6'),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                ),
                pw.SizedBox(width: 5),
                pw.Text(
                  'S/. ${entry.value.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  pw.Widget _buildPedidosPorEstadoChart(Map<String, int> pedidosPorEstado) {
    final total = pedidosPorEstado.values.fold(0, (sum, count) => sum + count);

    final colores = {
      'pendiente': '#f59e0b',
      'en_proceso': '#3b82f6',
      'completado': '#10b981',
      'cancelado': '#ef4444',
    };

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#e5e7eb')),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: pedidosPorEstado.entries.map((entry) {
          final porcentaje = total > 0 ? (entry.value / total * 100) : 0.0;
          final barWidth = (entry.value / total) * 400;
          final color = colores[entry.key] ?? '#6b7280';

          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 100,
                  child: pw.Text(
                    entry.key,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.Container(
                  width: barWidth,
                  height: 20,
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex(color),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                ),
                pw.SizedBox(width: 5),
                pw.Text(
                  '${entry.value} (${porcentaje.toStringAsFixed(1)}%)',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  pw.Widget _buildVentasPorMetodoChart(Map<String, double> ventasPorMetodo) {
    final maxVenta = ventasPorMetodo.values.isEmpty ? 0.0 : ventasPorMetodo.values.reduce((a, b) => a > b ? a : b);

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#e5e7eb')),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: ventasPorMetodo.entries.map((entry) {
          final porcentaje = maxVenta > 0 ? (entry.value / maxVenta) : 0.0;
          final barWidth = porcentaje * 350;

          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 100,
                  child: pw.Text(
                    entry.key,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.Container(
                  width: barWidth,
                  height: 20,
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#10b981'),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                ),
                pw.SizedBox(width: 5),
                pw.Text(
                  'S/. ${entry.value.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  pw.Widget _buildProductosStockBajoChart(List<Map<String, dynamic>> productos) {
    if (productos.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(15),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#d1fae5'),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(
          '✓ No hay productos con stock bajo',
          style: pw.TextStyle(
            fontSize: 14,
            color: PdfColor.fromHex('#059669'),
          ),
        ),
      );
    }

    final maxStock = productos.fold<int>(0, (max, p) => (p['stock'] as int) > max ? p['stock'] as int : max);

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#fee2e2')),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColor.fromHex('#fef2f2'),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: productos.map((producto) {
          final stock = producto['stock'] as int;
          final barWidth = maxStock > 0 ? (stock / maxStock) * 300 : 0.0;

          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 150,
                  child: pw.Text(
                    producto['nombre'] as String,
                    style: const pw.TextStyle(fontSize: 9),
                    maxLines: 1,
                    overflow: pw.TextOverflow.clip,
                  ),
                ),
                pw.Container(
                  width: barWidth,
                  height: 18,
                  decoration: pw.BoxDecoration(
                    color: stock <= 5 ? PdfColor.fromHex('#dc2626') : PdfColor.fromHex('#f59e0b'),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                ),
                pw.SizedBox(width: 5),
                pw.Text(
                  '$stock unidades',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: stock <= 5 ? PdfColor.fromHex('#dc2626') : PdfColor.fromHex('#f59e0b'),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  pw.Widget _buildTop5ProductosChart(List<Map<String, dynamic>> productos) {
    if (productos.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(15),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#fef3c7'),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(
          'No hay datos de ventas de productos',
          style: pw.TextStyle(
            fontSize: 14,
            color: PdfColor.fromHex('#92400e'),
          ),
        ),
      );
    }

    final maxCantidad = productos.fold<int>(0, (max, p) => (p['cantidad'] as int) > max ? p['cantidad'] as int : max);

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#e5e7eb')),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColor.fromHex('#fef3c7'),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: productos.map((producto) {
          final cantidad = producto['cantidad'] as int;
          final barWidth = maxCantidad > 0 ? (cantidad / maxCantidad) * 300 : 0.0;

          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 150,
                  child: pw.Text(
                    producto['nombre'] as String,
                    style: const pw.TextStyle(fontSize: 9),
                    maxLines: 1,
                    overflow: pw.TextOverflow.clip,
                  ),
                ),
                pw.Container(
                  width: barWidth,
                  height: 18,
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#f59e0b'),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                ),
                pw.SizedBox(width: 5),
                pw.Text(
                  '$cantidad vendidos',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#92400e'),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  pw.Widget _buildProductosPorCategoriaChart(Map<String, int> productosPorCategoria) {
    if (productosPorCategoria.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(15),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#e0e7ff'),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(
          'No hay categorías registradas',
          style: pw.TextStyle(
            fontSize: 14,
            color: PdfColor.fromHex('#3730a3'),
          ),
        ),
      );
    }

    final maxCantidad = productosPorCategoria.values.fold(0, (max, count) => count > max ? count : max);

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#e5e7eb')),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColor.fromHex('#ede9fe'),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: productosPorCategoria.entries.map((entry) {
          final barWidth = maxCantidad > 0 ? (entry.value / maxCantidad) * 350 : 0.0;

          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 120,
                  child: pw.Text(
                    entry.key,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.Container(
                  width: barWidth,
                  height: 20,
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#7c3aed'),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                ),
                pw.SizedBox(width: 5),
                pw.Text(
                  '${entry.value} productos',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#5b21b6'),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _agregarTablaDatos(
    pw.Document pdf,
    List<Map<String, dynamic>> productos,
    List<Map<String, dynamic>> promociones,
    List<Map<String, dynamic>> pedidos,
    List<Map<String, dynamic>> usuarios,
  ) {
    // Página de resumen de datos
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Resumen de Datos',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#dc2626'),
                ),
              ),
              pw.SizedBox(height: 20),
              _buildDataSummaryBox('Productos Totales', '${productos.length}'),
              pw.SizedBox(height: 10),
              _buildDataSummaryBox('Promociones Activas', '${promociones.where((p) => p['activa'] == true).length}'),
              pw.SizedBox(height: 10),
              _buildDataSummaryBox('Pedidos Totales', '${pedidos.length}'),
              pw.SizedBox(height: 10),
              _buildDataSummaryBox('Usuarios Registrados', '${usuarios.length}'),
              pw.SizedBox(height: 30),
              pw.Text(
                'Top 10 Productos por Precio',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildTopProductosTable(productos),
            ],
          );
        },
      ),
    );
  }

  pw.Widget _buildDataSummaryBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#f3f4f6'),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColor.fromHex('#e5e7eb')),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#dc2626'),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTopProductosTable(List<Map<String, dynamic>> productos) {
    final topProductos = productos.toList()
      ..sort((a, b) => (b['precio'] as double).compareTo(a['precio'] as double));
    final top10 = topProductos.take(10).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColor.fromHex('#e5e7eb')),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#fee2e2'),
          ),
          children: [
            _buildTableCell('Producto', isHeader: true),
            _buildTableCell('Categoría', isHeader: true),
            _buildTableCell('Precio', isHeader: true),
            _buildTableCell('Stock', isHeader: true),
          ],
        ),
        ...top10.map((producto) {
          return pw.TableRow(
            children: [
              _buildTableCell(producto['nombre'] as String),
              _buildTableCell(producto['categoria'] as String),
              _buildTableCell('S/. ${(producto['precio'] as double).toStringAsFixed(2)}'),
              _buildTableCell('${producto['stock']}'),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        maxLines: 2,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  // ========== DESCARGA DEL PDF ==========

  /// Genera un nombre único para el archivo PDF con timestamp y contador
  /// para evitar sobrescribir archivos descargados el mismo día
  String _generarNombreArchivo() {
    final ahora = DateTime.now();
    final fechaActual = DateFormat('yyyyMMdd').format(ahora);
    final timestamp = DateFormat('HHmmss').format(ahora);

    // Genera nombres únicos basados en milisegundos para evitar colisiones
    // Formato: Reporte_Visual_Reposteria_Arlex_YYYYMMDD_HHMMSS_#.pdf
    final contador = ahora.millisecondsSinceEpoch % 1000;
    return 'Reporte_Visual_Reposteria_Arlex_${fechaActual}_${timestamp}_$contador.pdf';
  }

  Future<void> _descargarPdf(pw.Document pdf) async {
    final bytes = await pdf.save();
    final nombreArchivo = _generarNombreArchivo();

    // Crear blob y descargar en el navegador
    final blob = html.Blob([Uint8List.fromList(bytes)], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute('download', nombreArchivo)
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  /// Método público para generar y devolver el PDF como bytes con nombre de archivo
  Future<Map<String, dynamic>> generarReportePdf() async {
    try {
      // Obtener datos de Firebase
      final productos = await _obtenerProductos();
      final promociones = await _obtenerPromociones();
      final pedidos = await _obtenerPedidos();
      final usuarios = await _obtenerUsuarios();

      // Calcular estadísticas
      final estadisticas = _calcularEstadisticas(pedidos, productos);

      // Crear el documento PDF
      final pdf = pw.Document();

      // Agregar páginas
      _agregarPortada(pdf);
      _agregarResumenEjecutivo(pdf, estadisticas);
      await _agregarGraficos(pdf, pedidos, productos, estadisticas);
      _agregarTablaDatos(pdf, productos, promociones, pedidos, usuarios);

      // Generar bytes
      final bytes = await pdf.save();
      final nombreArchivo = _generarNombreArchivo();

      return {
        'bytes': Uint8List.fromList(bytes),
        'nombreArchivo': nombreArchivo,
      };
    } catch (e, stackTrace) {
      // Log del error para debugging
      debugPrint('Error al generar reporte PDF: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
