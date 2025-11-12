import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generar reporte en el formato especificado
  Future<Map<String, dynamic>?> generarReporte({
    required String formato, // 'excel', 'csv', 'pdf'
    required String dateFilter,
    required String categoryFilter,
    required String usuarioId,
    required String usuarioNombre,
  }) async {
    try {
      Uint8List? bytes;
      String extension;

      switch (formato.toLowerCase()) {
        case 'excel':
          bytes = await _generarExcel(dateFilter, categoryFilter);
          extension = 'xlsx';
          break;
        case 'csv':
          bytes = await _generarCSV(dateFilter, categoryFilter);
          extension = 'csv';
          break;
        case 'pdf':
          bytes = await _generarPDF(dateFilter, categoryFilter);
          extension = 'pdf';
          break;
        default:
          return null;
      }

      if (bytes == null) return null;

      // Generar nombre de archivo
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final nombreArchivo = 'Reporte_Estadisticas_$timestamp.$extension';

      // Guardar registro en Firestore (sin URL de Storage para hacerlo más rápido)
      await _guardarRegistroEnFirestore(
        nombreArchivo: nombreArchivo,
        tipo: formato,
        tamanoBytes: bytes.length,
        usuarioId: usuarioId,
        usuarioNombre: usuarioNombre,
        filtroFecha: dateFilter,
        filtroCategoria: categoryFilter,
        downloadUrl: '', // Sin URL por ahora para hacerlo más rápido
      );

      return {
        'bytes': bytes,
        'nombreArchivo': nombreArchivo,
      };
    } catch (e) {
      debugPrint('Error al generar reporte: $e');
      return null;
    }
  }

  /// Guardar registro en Firestore
  Future<DocumentReference> _guardarRegistroEnFirestore({
    required String nombreArchivo,
    required String tipo,
    required int tamanoBytes,
    required String usuarioId,
    required String usuarioNombre,
    required String filtroFecha,
    required String filtroCategoria,
    required String downloadUrl,
  }) async {
    return await _firestore.collection('reportes').add({
      'nombreArchivo': nombreArchivo,
      'tipo': tipo,
      'tamañoBytes': tamanoBytes,
      'fechaGeneracion': FieldValue.serverTimestamp(),
      'usuarioId': usuarioId,
      'usuarioNombre': usuarioNombre,
      'filtroFecha': filtroFecha,
      'filtroCategoria': filtroCategoria,
      'downloadUrl': downloadUrl,
    });
  }

  /// Generar reporte Excel
  Future<Uint8List?> _generarExcel(String dateFilter, String categoryFilter) async {
    try {
      // Hacer TODAS las consultas en paralelo para optimizar
      final resultados = await Future.wait([
        _obtenerPedidosFiltrados(dateFilter, categoryFilter),
        _firestore.collection('productos').get(),
        _firestore.collection('categorias').get(),
        _firestore.collection('promociones').get(),
        _firestore.collection('pedidos').orderBy('fechaPedido', descending: true).limit(100).get(),
      ]);

      final pedidosFiltrados = resultados[0] as List<QueryDocumentSnapshot>;
      final productosSnapshot = resultados[1] as QuerySnapshot;
      final categoriasSnapshot = resultados[2] as QuerySnapshot;
      final promocionesSnapshot = resultados[3] as QuerySnapshot;
      final pedidosSnapshot = resultados[4] as QuerySnapshot;

      final excel = Excel.createExcel();
      excel.delete('Sheet1');

      // Crear hojas con datos pre-cargados
      _crearHojaEstadisticasExcelOptimizado(excel, dateFilter, categoryFilter, pedidosFiltrados);
      _crearHojaProductosExcelOptimizado(excel, productosSnapshot);
      _crearHojaCategoriasExcelOptimizado(excel, categoriasSnapshot);
      _crearHojaPromocionesExcelOptimizado(excel, promocionesSnapshot);
      _crearHojaPedidosExcelOptimizado(excel, pedidosSnapshot);

      final bytes = excel.encode();
      return bytes != null ? Uint8List.fromList(bytes) : null;
    } catch (e) {
      debugPrint('Error al generar Excel: $e');
      return null;
    }
  }

  /// Generar reporte CSV (optimizado)
  Future<Uint8List?> _generarCSV(String dateFilter, String categoryFilter) async {
    try {
      // Hacer todas las consultas en paralelo
      final resultados = await Future.wait([
        _obtenerPedidosFiltrados(dateFilter, categoryFilter),
        _firestore.collection('productos').get(),
      ]);

      final pedidos = resultados[0] as List<QueryDocumentSnapshot>;
      final productosSnapshot = resultados[1] as QuerySnapshot;

      final rows = <List<dynamic>>[];

      // Encabezado
      rows.add(['REPORTE DE ESTADÍSTICAS Y VENTAS']);
      rows.add([]);
      rows.add(['Filtro de Fecha', _getNombreFiltro(dateFilter)]);
      rows.add(['Categoría', categoryFilter == 'all' ? 'Todas' : categoryFilter]);
      rows.add(['Fecha de Generación', DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())]);
      rows.add([]);

      // Ventas Diarias
      rows.add(['VENTAS DIARIAS (TOTAL)']);
      rows.add(['Fecha', 'Total (S/.)']);
      final ventasDiarias = _calcularVentasDiarias(pedidos);
      for (var entry in ventasDiarias.entries) {
        rows.add([entry.key, entry.value]);
      }
      rows.add([]);

      // Ventas por Método de Pago
      rows.add(['VENTAS POR MÉTODO DE PAGO']);
      rows.add(['Método de Pago', 'Total (S/.)']);
      final ventasMetodoPago = _calcularVentasPorMetodoPago(pedidos);
      for (var entry in ventasMetodoPago.entries) {
        rows.add([entry.key, entry.value]);
      }
      rows.add([]);

      // Top 5 Productos
      rows.add(['TOP 5 PRODUCTOS MÁS VENDIDOS']);
      rows.add(['Producto', 'Cantidad Vendida']);
      final topProductos = _calcularTop5Productos(pedidos);
      for (var entry in topProductos.entries) {
        rows.add([entry.key, entry.value]);
      }
      rows.add([]);
      rows.add([]);

      // Productos
      rows.add(['GESTIÓN DE PRODUCTOS']);
      rows.add(['Nombre', 'Categoría', 'Precio (S/.)', 'Stock', 'Descripción']);
      for (var doc in productosSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        rows.add([
          data['nombre'] ?? '',
          data['categoria'] ?? '',
          data['precio'] ?? 0,
          data['stock'] ?? 0,
          data['descripcion'] ?? '',
        ]);
      }

      // Convertir a CSV
      final csv = const ListToCsvConverter().convert(rows);
      return Uint8List.fromList(csv.codeUnits);
    } catch (e) {
      debugPrint('Error al generar CSV: $e');
      return null;
    }
  }

  /// Generar reporte PDF
  Future<Uint8List?> _generarPDF(String dateFilter, String categoryFilter) async {
    try {
      final pdf = pw.Document();

      // Obtener datos
      final pedidos = await _obtenerPedidosFiltrados(dateFilter, categoryFilter);
      final ventasDiarias = _calcularVentasDiarias(pedidos);
      final ventasMetodoPago = _calcularVentasPorMetodoPago(pedidos);
      final topProductos = _calcularTop5Productos(pedidos);

      // Página 1: Estadísticas
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'REPORTE DE ESTADÍSTICAS Y VENTAS',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Filtro de Fecha: ${_getNombreFiltro(dateFilter)}'),
              pw.Text('Categoría: ${categoryFilter == "all" ? "Todas" : categoryFilter}'),
              pw.Text('Fecha de Generación: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
              pw.SizedBox(height: 30),

              // Ventas Diarias
              pw.Text(
                'VENTAS DIARIAS (TOTAL)',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Fecha', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Total (S/.)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...ventasDiarias.entries.map((entry) => pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(entry.key)),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(entry.value.toStringAsFixed(2))),
                        ],
                      )),
                ],
              ),
              pw.SizedBox(height: 20),

              // Ventas por Método de Pago
              pw.Text(
                'VENTAS POR MÉTODO DE PAGO',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Método de Pago', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Total (S/.)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...ventasMetodoPago.entries.map((entry) => pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(entry.key)),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(entry.value.toStringAsFixed(2))),
                        ],
                      )),
                ],
              ),
            ],
          ),
        ),
      );

      // Página 2: Top Productos
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'TOP 5 PRODUCTOS MÁS VENDIDOS',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Producto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Cantidad Vendida', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...topProductos.entries.map((entry) => pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(entry.key)),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(entry.value.toString())),
                        ],
                      )),
                ],
              ),
            ],
          ),
        ),
      );

      return await pdf.save();
    } catch (e) {
      debugPrint('Error al generar PDF: $e');
      return null;
    }
  }

  // Métodos auxiliares para Excel (optimizados)
  void _crearHojaEstadisticasExcelOptimizado(
    Excel excel,
    String dateFilter,
    String categoryFilter,
    List<QueryDocumentSnapshot> pedidos,
  ) {
    final sheet = excel['Estadísticas y Gráficos'];
    int row = 0;

    // Título
    sheet.cell(CellIndex.indexByString('A${row + 1}')).value = TextCellValue('REPORTE DE ESTADÍSTICAS Y VENTAS');
    row += 2;

    // Filtros
    sheet.cell(CellIndex.indexByString('A${row + 1}')).value = TextCellValue('Filtro de Fecha: ${_getNombreFiltro(dateFilter)}');
    row++;
    sheet.cell(CellIndex.indexByString('A${row + 1}')).value = TextCellValue('Categoría: ${categoryFilter == "all" ? "Todas" : categoryFilter}');
    row++;
    sheet.cell(CellIndex.indexByString('A${row + 1}')).value = TextCellValue('Fecha de Generación: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');
    row += 2;

    // Calcular todos los datos
    final ventasDiarias = _calcularVentasDiarias(pedidos);
    final ventasMetodoPago = _calcularVentasPorMetodoPago(pedidos);
    final topProductos = _calcularTop5Productos(pedidos);

    // Sección 1: Ventas Diarias (Total)
    sheet.cell(CellIndex.indexByString('A${row + 1}')).value = TextCellValue('VENTAS DIARIAS (TOTAL)');
    row += 2;

    sheet.cell(CellIndex.indexByString('A${row + 1}')).value = TextCellValue('Fecha');
    sheet.cell(CellIndex.indexByString('B${row + 1}')).value = TextCellValue('Total (S/.)');
    row++;

    for (var entry in ventasDiarias.entries) {
      sheet.cell(CellIndex.indexByString('A${row + 1}')).value = TextCellValue(entry.key);
      sheet.cell(CellIndex.indexByString('B${row + 1}')).value = DoubleCellValue(entry.value);
      row++;
    }
    row += 2;

    // Sección 2: Ventas por Método de Pago
    sheet.cell(CellIndex.indexByString('A${row + 1}')).value = TextCellValue('VENTAS POR MÉTODO DE PAGO');
    row += 2;

    sheet.cell(CellIndex.indexByString('A${row + 1}')).value = TextCellValue('Método de Pago');
    sheet.cell(CellIndex.indexByString('B${row + 1}')).value = TextCellValue('Total (S/.)');
    row++;

    for (var entry in ventasMetodoPago.entries) {
      sheet.cell(CellIndex.indexByString('A${row + 1}')).value = TextCellValue(entry.key);
      sheet.cell(CellIndex.indexByString('B${row + 1}')).value = DoubleCellValue(entry.value);
      row++;
    }
    row += 2;

    // Sección 3: Top 5 Productos Más Vendidos
    sheet.cell(CellIndex.indexByString('A${row + 1}')).value = TextCellValue('TOP 5 PRODUCTOS MÁS VENDIDOS');
    row += 2;

    sheet.cell(CellIndex.indexByString('A${row + 1}')).value = TextCellValue('Producto');
    sheet.cell(CellIndex.indexByString('B${row + 1}')).value = TextCellValue('Cantidad Vendida');
    row++;

    for (var entry in topProductos.entries) {
      sheet.cell(CellIndex.indexByString('A${row + 1}')).value = TextCellValue(entry.key);
      sheet.cell(CellIndex.indexByString('B${row + 1}')).value = IntCellValue(entry.value);
      row++;
    }
  }

  void _crearHojaProductosExcelOptimizado(Excel excel, QuerySnapshot productos) {
    final sheet = excel['Productos'];
    int row = 0;

    sheet.cell(CellIndex.indexByString('A${row + 1}')).value = TextCellValue('Nombre');
    sheet.cell(CellIndex.indexByString('B${row + 1}')).value = TextCellValue('Categoría');
    sheet.cell(CellIndex.indexByString('C${row + 1}')).value = TextCellValue('Precio (S/.)');
    sheet.cell(CellIndex.indexByString('D${row + 1}')).value = TextCellValue('Stock');
    row++;

    for (var doc in productos.docs) {
      final data = doc.data() as Map<String, dynamic>;
      sheet.cell(CellIndex.indexByString('A${row + 1}')).value = TextCellValue(data['nombre'] ?? '');
      sheet.cell(CellIndex.indexByString('B${row + 1}')).value = TextCellValue(data['categoria'] ?? '');
      sheet.cell(CellIndex.indexByString('C${row + 1}')).value = DoubleCellValue((data['precio'] ?? 0).toDouble());
      sheet.cell(CellIndex.indexByString('D${row + 1}')).value = IntCellValue(data['stock'] ?? 0);
      row++;
    }
  }

  void _crearHojaCategoriasExcelOptimizado(Excel excel, QuerySnapshot categorias) {
    final sheet = excel['Categorías'];
    int row = 0;

    sheet.cell(CellIndex.indexByString('A${row + 1}')).value = TextCellValue('Nombre');
    sheet.cell(CellIndex.indexByString('B${row + 1}')).value = TextCellValue('Descripción');
    row++;

    for (var doc in categorias.docs) {
      final data = doc.data() as Map<String, dynamic>;
      sheet.cell(CellIndex.indexByString('A${row + 1}')).value = TextCellValue(data['nombre'] ?? '');
      sheet.cell(CellIndex.indexByString('B${row + 1}')).value = TextCellValue(data['descripcion'] ?? '');
      row++;
    }
  }

  void _crearHojaPromocionesExcelOptimizado(Excel excel, QuerySnapshot promociones) {
    final sheet = excel['Promociones'];
    int row = 0;

    sheet.cell(CellIndex.indexByString('A${row + 1}')).value = TextCellValue('Título');
    sheet.cell(CellIndex.indexByString('B${row + 1}')).value = TextCellValue('Descuento (%)');
    sheet.cell(CellIndex.indexByString('C${row + 1}')).value = TextCellValue('Fecha Inicio');
    sheet.cell(CellIndex.indexByString('D${row + 1}')).value = TextCellValue('Fecha Fin');
    row++;

    for (var doc in promociones.docs) {
      final data = doc.data() as Map<String, dynamic>;
      sheet.cell(CellIndex.indexByString('A${row + 1}')).value = TextCellValue(data['titulo'] ?? '');
      sheet.cell(CellIndex.indexByString('B${row + 1}')).value = DoubleCellValue((data['descuento'] ?? 0).toDouble());

      if (data['fechaInicio'] != null) {
        final fecha = (data['fechaInicio'] as Timestamp).toDate();
        sheet.cell(CellIndex.indexByString('C${row + 1}')).value = TextCellValue(DateFormat('dd/MM/yyyy').format(fecha));
      }

      if (data['fechaFin'] != null) {
        final fecha = (data['fechaFin'] as Timestamp).toDate();
        sheet.cell(CellIndex.indexByString('D${row + 1}')).value = TextCellValue(DateFormat('dd/MM/yyyy').format(fecha));
      }

      row++;
    }
  }

  void _crearHojaPedidosExcelOptimizado(Excel excel, QuerySnapshot pedidos) {
    final sheet = excel['Pedidos'];
    int row = 0;

    sheet.cell(CellIndex.indexByString('A${row + 1}')).value = TextCellValue('N° Pedido');
    sheet.cell(CellIndex.indexByString('B${row + 1}')).value = TextCellValue('Cliente');
    sheet.cell(CellIndex.indexByString('C${row + 1}')).value = TextCellValue('Estado');
    sheet.cell(CellIndex.indexByString('D${row + 1}')).value = TextCellValue('Total (S/.)');
    sheet.cell(CellIndex.indexByString('E${row + 1}')).value = TextCellValue('Fecha');
    row++;

    for (var doc in pedidos.docs) {
      final data = doc.data() as Map<String, dynamic>;
      sheet.cell(CellIndex.indexByString('A${row + 1}')).value = TextCellValue(data['numeroPedido']?.toString() ?? doc.id);
      sheet.cell(CellIndex.indexByString('B${row + 1}')).value = TextCellValue(data['clienteNombre'] ?? '');
      sheet.cell(CellIndex.indexByString('C${row + 1}')).value = TextCellValue(data['estado'] ?? '');
      sheet.cell(CellIndex.indexByString('D${row + 1}')).value = DoubleCellValue((data['total'] ?? 0).toDouble());

      if (data['fechaPedido'] != null) {
        final fecha = (data['fechaPedido'] as Timestamp).toDate();
        sheet.cell(CellIndex.indexByString('E${row + 1}')).value = TextCellValue(DateFormat('dd/MM/yyyy HH:mm').format(fecha));
      }

      row++;
    }
  }

  // Métodos auxiliares compartidos
  String _getNombreFiltro(String filter) {
    switch (filter) {
      case '30_days':
        return 'Últimos 30 días';
      case 'this_month':
        return 'Este mes';
      case 'this_year':
        return 'Este año';
      default:
        return 'Todos';
    }
  }

  Future<List<QueryDocumentSnapshot>> _obtenerPedidosFiltrados(
    String dateFilter,
    String categoryFilter,
  ) async {
    Query query = _firestore.collection('pedidos');

    final now = DateTime.now();
    DateTime? startDate;

    switch (dateFilter) {
      case '30_days':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 'this_month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'this_year':
        startDate = DateTime(now.year, 1, 1);
        break;
    }

    if (startDate != null) {
      query = query.where('fechaPedido', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    final snapshot = await query.get();
    return snapshot.docs;
  }

  Map<String, double> _calcularVentasDiarias(List<QueryDocumentSnapshot> pedidos) {
    final Map<String, double> dailySales = {};

    for (var pedido in pedidos) {
      final data = pedido.data() as Map<String, dynamic>;
      final fechaPedido = data['fechaPedido'] as Timestamp?;
      if (fechaPedido == null) continue;

      final fecha = fechaPedido.toDate();
      final fechaFormateada = DateFormat('dd/MM/yyyy').format(fecha);
      final total = (data['total'] ?? 0).toDouble();

      dailySales[fechaFormateada] = (dailySales[fechaFormateada] ?? 0) + total;
    }

    final sortedEntries = dailySales.entries.toList()
      ..sort((a, b) {
        final dateA = DateFormat('dd/MM/yyyy').parse(a.key);
        final dateB = DateFormat('dd/MM/yyyy').parse(b.key);
        return dateA.compareTo(dateB);
      });

    return Map.fromEntries(sortedEntries);
  }

  Map<String, double> _calcularVentasPorMetodoPago(List<QueryDocumentSnapshot> pedidos) {
    final Map<String, double> paymentSales = {};

    for (var pedido in pedidos) {
      final data = pedido.data() as Map<String, dynamic>;
      final metodoPago = data['metodoPago'] ?? 'Sin especificar';
      final total = (data['total'] ?? 0).toDouble();

      paymentSales[metodoPago] = (paymentSales[metodoPago] ?? 0) + total;
    }

    return paymentSales;
  }

  Map<String, int> _calcularTop5Productos(List<QueryDocumentSnapshot> pedidos) {
    final Map<String, int> productCount = {};

    for (var pedido in pedidos) {
      final data = pedido.data() as Map<String, dynamic>;
      final productos = data['productos'] as List<dynamic>?;

      if (productos != null) {
        for (var producto in productos) {
          final nombre = producto['productoNombre'] ?? 'Sin nombre';
          final cantidad = (producto['cantidad'] ?? 0) as int;
          productCount[nombre] = (productCount[nombre] ?? 0) + cantidad;
        }
      }
    }

    final sortedEntries = productCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sortedEntries.take(5);
    return Map.fromEntries(top5);
  }

  void debugPrint(String message) {
    print(message);
  }
}
