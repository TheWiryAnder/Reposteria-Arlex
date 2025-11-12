import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ExcelService {
  /// Generar archivo Excel con estadísticas y datos de gestión
  Future<Uint8List?> generarReporteCompleto({
    required String dateFilter,
    required String categoryFilter,
  }) async {
    try {
      final excel = Excel.createExcel();

      // Eliminar la hoja por defecto
      excel.delete('Sheet1');

      // Hoja 1: Gráficos y Estadísticas
      await _crearHojaEstadisticas(excel, dateFilter, categoryFilter);

      // Hoja 2: Gestión de Productos
      await _crearHojaProductos(excel);

      // Hoja 3: Gestión de Categorías
      await _crearHojaCategorias(excel);

      // Hoja 4: Gestión de Promociones
      await _crearHojaPromociones(excel);

      // Hoja 5: Gestión de Pedidos
      await _crearHojaPedidos(excel);

      // Convertir a bytes
      final bytes = excel.encode();
      return bytes != null ? Uint8List.fromList(bytes) : null;
    } catch (e) {
      print('Error al generar Excel: $e');
      return null;
    }
  }

  /// Crear hoja de estadísticas con gráficos
  Future<void> _crearHojaEstadisticas(
    Excel excel,
    String dateFilter,
    String categoryFilter,
  ) async {
    final sheet = excel['Estadísticas y Gráficos'];

    // Configurar anchos de columna
    sheet.setColumnWidth(0, 25);
    sheet.setColumnWidth(1, 20);
    sheet.setColumnWidth(2, 20);

    int rowIndex = 0;

    // Título
    var titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    titleCell.value = TextCellValue('REPORTE DE ESTADÍSTICAS Y VENTAS');
    titleCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 16,
      horizontalAlign: HorizontalAlign.Center,
    );
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
    );
    rowIndex += 2;

    // Información del filtro
    var filterCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    filterCell.value = TextCellValue('Filtro de Fecha: ${_getNombreFiltro(dateFilter)}');
    filterCell.cellStyle = CellStyle(bold: true);
    rowIndex++;

    var categoryCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    categoryCell.value = TextCellValue('Categoría: ${categoryFilter == "all" ? "Todas" : categoryFilter}');
    categoryCell.cellStyle = CellStyle(bold: true);
    rowIndex++;

    var dateCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    dateCell.value = TextCellValue('Fecha de Generación: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');
    rowIndex += 2;

    // Obtener datos de Firebase
    final pedidos = await _obtenerPedidosFiltrados(dateFilter, categoryFilter);

    // Sección: Ventas Diarias
    var ventasTitleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    ventasTitleCell.value = TextCellValue('VENTAS DIARIAS (TOTAL)');
    ventasTitleCell.cellStyle = CellStyle(bold: true, fontSize: 14);
    rowIndex += 2;

    // Encabezados
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue('Fecha');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue('Total (S/.)');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = CellStyle(bold: true);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).cellStyle = CellStyle(bold: true);
    rowIndex++;

    // Datos de ventas diarias
    final ventasDiarias = _calcularVentasDiarias(pedidos);
    for (var entry in ventasDiarias.entries) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(entry.key);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = DoubleCellValue(entry.value);
      rowIndex++;
    }
    rowIndex += 2;

    // Sección: Ventas por Método de Pago
    var metodoPagoTitleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    metodoPagoTitleCell.value = TextCellValue('VENTAS POR MÉTODO DE PAGO');
    metodoPagoTitleCell.cellStyle = CellStyle(bold: true, fontSize: 14);
    rowIndex += 2;

    // Encabezados
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue('Método de Pago');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue('Total (S/.)');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = CellStyle(bold: true);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).cellStyle = CellStyle(bold: true);
    rowIndex++;

    // Datos por método de pago
    final ventasMetodoPago = _calcularVentasPorMetodoPago(pedidos);
    for (var entry in ventasMetodoPago.entries) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(entry.key);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = DoubleCellValue(entry.value);
      rowIndex++;
    }
    rowIndex += 2;

    // Sección: Top 5 Productos Más Vendidos
    var topProductosTitleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    topProductosTitleCell.value = TextCellValue('TOP 5 PRODUCTOS MÁS VENDIDOS');
    topProductosTitleCell.cellStyle = CellStyle(bold: true, fontSize: 14);
    rowIndex += 2;

    // Encabezados
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue('Producto');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue('Cantidad Vendida');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = CellStyle(bold: true);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).cellStyle = CellStyle(bold: true);
    rowIndex++;

    // Datos top productos
    final topProductos = _calcularTop5Productos(pedidos);
    for (var entry in topProductos.entries) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(entry.key);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = IntCellValue(entry.value);
      rowIndex++;
    }
  }

  /// Crear hoja de productos
  Future<void> _crearHojaProductos(Excel excel) async {
    final sheet = excel['Gestión de Productos'];

    // Configurar anchos
    sheet.setColumnWidth(0, 30);
    sheet.setColumnWidth(1, 20);
    sheet.setColumnWidth(2, 15);
    sheet.setColumnWidth(3, 15);
    sheet.setColumnWidth(4, 15);

    int rowIndex = 0;

    // Título
    var titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    titleCell.value = TextCellValue('GESTIÓN DE PRODUCTOS');
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 16);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
    );
    rowIndex += 2;

    // Encabezados
    final headers = ['Nombre', 'Categoría', 'Precio (S/.)', 'Stock', 'Descripción'];
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(bold: true);
    }
    rowIndex++;

    // Obtener productos de Firebase
    final productosSnapshot = await FirebaseFirestore.instance.collection('productos').get();

    for (var doc in productosSnapshot.docs) {
      final data = doc.data();
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value =
          TextCellValue(data['nombre'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value =
          TextCellValue(data['categoria'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value =
          DoubleCellValue((data['precio'] ?? 0).toDouble());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value =
          IntCellValue(data['stock'] ?? 0);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value =
          TextCellValue(data['descripcion'] ?? '');
      rowIndex++;
    }
  }

  /// Crear hoja de categorías
  Future<void> _crearHojaCategorias(Excel excel) async {
    final sheet = excel['Gestión de Categorías'];

    sheet.setColumnWidth(0, 30);
    sheet.setColumnWidth(1, 50);

    int rowIndex = 0;

    // Título
    var titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    titleCell.value = TextCellValue('GESTIÓN DE CATEGORÍAS');
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 16);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
    );
    rowIndex += 2;

    // Encabezados
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue('Nombre');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue('Descripción');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = CellStyle(bold: true);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).cellStyle = CellStyle(bold: true);
    rowIndex++;

    // Obtener categorías
    final categoriasSnapshot = await FirebaseFirestore.instance.collection('categorias').get();

    for (var doc in categoriasSnapshot.docs) {
      final data = doc.data();
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value =
          TextCellValue(data['nombre'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value =
          TextCellValue(data['descripcion'] ?? '');
      rowIndex++;
    }
  }

  /// Crear hoja de promociones
  Future<void> _crearHojaPromociones(Excel excel) async {
    final sheet = excel['Gestión de Promociones'];

    sheet.setColumnWidth(0, 25);
    sheet.setColumnWidth(1, 40);
    sheet.setColumnWidth(2, 15);
    sheet.setColumnWidth(3, 15);
    sheet.setColumnWidth(4, 15);

    int rowIndex = 0;

    // Título
    var titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    titleCell.value = TextCellValue('GESTIÓN DE PROMOCIONES');
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 16);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
    );
    rowIndex += 2;

    // Encabezados
    final headers = ['Título', 'Descripción', 'Descuento (%)', 'Fecha Inicio', 'Fecha Fin'];
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(bold: true);
    }
    rowIndex++;

    // Obtener promociones
    final promocionesSnapshot = await FirebaseFirestore.instance.collection('promociones').get();

    for (var doc in promocionesSnapshot.docs) {
      final data = doc.data();
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value =
          TextCellValue(data['titulo'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value =
          TextCellValue(data['descripcion'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value =
          DoubleCellValue((data['descuento'] ?? 0).toDouble());

      if (data['fechaInicio'] != null) {
        final fechaInicio = (data['fechaInicio'] as Timestamp).toDate();
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value =
            TextCellValue(DateFormat('dd/MM/yyyy').format(fechaInicio));
      }

      if (data['fechaFin'] != null) {
        final fechaFin = (data['fechaFin'] as Timestamp).toDate();
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value =
            TextCellValue(DateFormat('dd/MM/yyyy').format(fechaFin));
      }

      rowIndex++;
    }
  }

  /// Crear hoja de pedidos
  Future<void> _crearHojaPedidos(Excel excel) async {
    final sheet = excel['Gestión de Pedidos'];

    sheet.setColumnWidth(0, 20);
    sheet.setColumnWidth(1, 25);
    sheet.setColumnWidth(2, 15);
    sheet.setColumnWidth(3, 15);
    sheet.setColumnWidth(4, 20);
    sheet.setColumnWidth(5, 15);

    int rowIndex = 0;

    // Título
    var titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    titleCell.value = TextCellValue('GESTIÓN DE PEDIDOS');
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 16);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
    );
    rowIndex += 2;

    // Encabezados
    final headers = ['N° Pedido', 'Cliente', 'Estado', 'Total (S/.)', 'Fecha', 'Método Pago'];
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(bold: true);
    }
    rowIndex++;

    // Obtener pedidos
    final pedidosSnapshot = await FirebaseFirestore.instance
        .collection('pedidos')
        .orderBy('fechaPedido', descending: true)
        .get();

    for (var doc in pedidosSnapshot.docs) {
      final data = doc.data();
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value =
          TextCellValue(data['numeroPedido']?.toString() ?? doc.id);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value =
          TextCellValue(data['clienteNombre'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value =
          TextCellValue(data['estado'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value =
          DoubleCellValue((data['total'] ?? 0).toDouble());

      if (data['fechaPedido'] != null) {
        final fecha = (data['fechaPedido'] as Timestamp).toDate();
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value =
            TextCellValue(DateFormat('dd/MM/yyyy HH:mm').format(fecha));
      }

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value =
          TextCellValue(data['metodoPago'] ?? '');

      rowIndex++;
    }
  }

  // Métodos auxiliares
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
    Query query = FirebaseFirestore.instance.collection('pedidos');

    // Aplicar filtro de fecha
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
      query = query.where('fechaPedido',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
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

    // Ordenar por fecha
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

    // Ordenar y tomar top 5
    final sortedEntries = productCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top5 = sortedEntries.take(5);
    return Map.fromEntries(top5);
  }
}
