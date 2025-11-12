import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;

/// Servicio para generar reportes en Excel con datos y gráficos dinámicos
class ReporteExcelService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Genera un reporte completo en Excel con múltiples hojas
  Future<void> generarReporteCompleto() async {
    try {
      debugPrint('🔄 Iniciando generación de reporte Excel...');

      // Crear el archivo Excel
      final excel = Excel.createExcel();

      // Eliminar la hoja por defecto
      excel.delete('Sheet1');

      // Pequeño delay para evitar race conditions de Firestore
      await Future.delayed(const Duration(milliseconds: 100));

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

      // Crear hojas con datos
      debugPrint('📝 Creando hojas del Excel...');
      _crearHojaInstrucciones(excel);
      debugPrint('  ✓ Hoja de Instrucciones creada');

      _crearHojaProductos(excel, productos);
      debugPrint('  ✓ Hoja de Productos creada (${productos.length} registros)');

      _crearHojaPromociones(excel, promociones);
      debugPrint('  ✓ Hoja de Promociones creada (${promociones.length} registros)');

      _crearHojaPedidos(excel, pedidos);
      debugPrint('  ✓ Hoja de Pedidos creada (${pedidos.length} registros)');

      _crearHojaUsuarios(excel, usuarios);
      debugPrint('  ✓ Hoja de Usuarios creada (${usuarios.length} registros)');

      _crearHojaEstadisticas(excel, pedidos, productos);
      debugPrint('  ✓ Hoja de Estadísticas creada');

      _crearHojaGraficos(excel, pedidos, productos);
      debugPrint('  ✓ Hoja de Gráficos creada');

      // Descargar el archivo
      debugPrint('💾 Descargando archivo Excel...');
      await _descargarExcel(excel);
      debugPrint('✅ Reporte Excel generado exitosamente');
    } catch (e, stackTrace) {
      debugPrint('❌ Error al generar reporte Excel: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Obtener productos desde Firebase
  Future<List<Map<String, dynamic>>> _obtenerProductos() async {
    try {
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
          'descripcion': data['descripcion'] ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error al obtener productos: $e');
      return [];
    }
  }

  /// Obtener promociones desde Firebase
  Future<List<Map<String, dynamic>>> _obtenerPromociones() async {
    try {
      final snapshot = await _firestore.collection('promociones').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'titulo': data['titulo'] ?? '',
          'descripcion': data['descripcion'] ?? '',
          'descuento': (data['descuento'] ?? 0).toDouble(),
          'precioOriginal': (data['precioOriginal'] ?? 0).toDouble(),
          'precioDescuento': (data['precioDescuento'] ?? 0).toDouble(),
          'activa': data['activa'] ?? false,
          'fechaInicio': _formatearFecha(data['fechaInicio']),
          'fechaFin': _formatearFecha(data['fechaFin']),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error al obtener promociones: $e');
      return [];
    }
  }

  /// Obtener pedidos desde Firebase
  Future<List<Map<String, dynamic>>> _obtenerPedidos() async {
    try {
      final snapshot = await _firestore.collection('pedidos').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Intentar obtener 'productos' o 'items' (compatibilidad con diferentes estructuras)
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
          'productos': productos,
          'cantidadProductos': productos.length,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error al obtener pedidos: $e');
      return [];
    }
  }

  /// Obtener usuarios desde Firebase
  Future<List<Map<String, dynamic>>> _obtenerUsuarios() async {
    try {
      final snapshot = await _firestore.collection('usuarios').get();
      return snapshot.docs.map((doc) {
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
    } catch (e) {
      debugPrint('Error al obtener usuarios: $e');
      return [];
    }
  }

  /// Crear hoja de instrucciones para crear gráficos
  void _crearHojaInstrucciones(Excel excel) {
    final sheet = excel['📊 INSTRUCCIONES'];

    // Estilo para el título
    final titleStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#dc2626'),
      fontColorHex: ExcelColor.white,
      bold: true,
      fontSize: 16,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // Estilo para subtítulos
    final subtitleStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#ef4444'),
      fontColorHex: ExcelColor.white,
      bold: true,
      fontSize: 12,
    );

    // Estilo para texto normal
    final normalStyle = CellStyle(
      fontSize: 11,
    );

    int row = 0;

    // Título principal
    var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('📊 CÓMO CREAR GRÁFICOS EN EXCEL');
    cell.cellStyle = titleStyle;
    row += 2;

    // Instrucción 1
    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('PASO 1: Ir a la hoja "Datos para Gráficos"');
    cell.cellStyle = subtitleStyle;
    row++;

    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('Esta hoja contiene los datos organizados en 4 secciones para crear gráficos.');
    cell.cellStyle = normalStyle;
    row += 2;

    // Instrucción 2
    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('PASO 2: Seleccionar los datos de un gráfico');
    cell.cellStyle = subtitleStyle;
    row++;

    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('Ejemplo: Para "Ventas por Día", selecciona desde la celda A2 hasta B8');
    cell.cellStyle = normalStyle;
    row++;

    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('(incluye el encabezado "Fecha" y "Ventas" más los 7 días de datos)');
    cell.cellStyle = normalStyle;
    row += 2;

    // Instrucción 3
    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('PASO 3: Insertar gráfico');
    cell.cellStyle = subtitleStyle;
    row++;

    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('1. Clic en la pestaña "Insertar" en Excel');
    cell.cellStyle = normalStyle;
    row++;

    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('2. Elegir tipo de gráfico (Línea, Columna, Circular, etc.)');
    cell.cellStyle = normalStyle;
    row++;

    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('3. El gráfico se creará automáticamente con los datos seleccionados');
    cell.cellStyle = normalStyle;
    row += 2;

    // Gráficos recomendados
    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('📈 GRÁFICOS RECOMENDADOS POR SECCIÓN');
    cell.cellStyle = subtitleStyle;
    row += 2;

    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('1. VENTAS POR DÍA → Gráfico de Líneas o Columnas');
    cell.cellStyle = normalStyle;
    row++;

    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('   Seleccionar: Columnas A y B (desde fila 2 hasta fila 8)');
    cell.cellStyle = normalStyle;
    row += 2;

    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('2. PEDIDOS POR ESTADO → Gráfico Circular (Pie)');
    cell.cellStyle = normalStyle;
    row++;

    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('   Seleccionar: Columnas D y E (todos los datos de estados)');
    cell.cellStyle = normalStyle;
    row += 2;

    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('3. VENTAS POR MÉTODO DE PAGO → Gráfico de Barras');
    cell.cellStyle = normalStyle;
    row++;

    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('   Seleccionar: Columnas G y H (todos los métodos de pago)');
    cell.cellStyle = normalStyle;
    row += 2;

    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('4. PRODUCTOS CON STOCK BAJO → Gráfico de Columnas');
    cell.cellStyle = normalStyle;
    row++;

    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('   Seleccionar: Datos de la sección "PRODUCTOS CON BAJO STOCK"');
    cell.cellStyle = normalStyle;
    row += 2;

    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('5. TOP 5 PRODUCTOS MÁS VENDIDOS → Gráfico de Barras Horizontales');
    cell.cellStyle = normalStyle;
    row++;

    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('   Seleccionar: Datos de la sección "TOP 5 PRODUCTOS MÁS VENDIDOS"');
    cell.cellStyle = normalStyle;
    row += 2;

    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('6. PRODUCTOS POR CATEGORÍA → Gráfico de Columnas o Circular');
    cell.cellStyle = normalStyle;
    row++;

    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('   Seleccionar: Datos de la sección "PRODUCTOS POR CATEGORÍA"');
    cell.cellStyle = normalStyle;
    row += 2;

    // Nota importante
    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('⚠️ NOTA IMPORTANTE');
    cell.cellStyle = subtitleStyle;
    row++;

    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('Los gráficos NO pueden ser creados automáticamente por código desde Flutter.');
    cell.cellStyle = normalStyle;
    row++;

    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('Sin embargo, los datos están perfectamente organizados para que puedas');
    cell.cellStyle = normalStyle;
    row++;

    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('crear gráficos profesionales en Excel con solo 2 clics por gráfico.');
    cell.cellStyle = normalStyle;
    row += 2;

    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('💡 TIP: Si deseas gráficos ya listos, descarga el REPORTE PDF desde el dashboard.');
    cell.cellStyle = normalStyle;
  }

  /// Crear hoja de productos
  void _crearHojaProductos(Excel excel, List<Map<String, dynamic>> productos) {
    final sheet = excel['Productos'];

    // Configurar estilos
    final headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.blue,
      fontColorHex: ExcelColor.white,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // Encabezados
    final headers = ['ID', 'Nombre', 'Categoría', 'Precio (S/.)', 'Stock', 'Estado', 'Descripción'];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Datos
    for (var i = 0; i < productos.length; i++) {
      final producto = productos[i];
      final rowIndex = i + 1;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .value = TextCellValue(producto['id'].toString().substring(0, 8));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        .value = TextCellValue(producto['nombre'].toString());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
        .value = TextCellValue(producto['categoria'].toString());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
        .value = DoubleCellValue(producto['precio']);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
        .value = IntCellValue(producto['stock']);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
        .value = TextCellValue(producto['estado'].toString());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
        .value = TextCellValue(producto['descripcion'].toString());
    }

    // Ancho de columnas configurado automáticamente por Excel
  }

  /// Crear hoja de promociones
  void _crearHojaPromociones(Excel excel, List<Map<String, dynamic>> promociones) {
    final sheet = excel['Promociones'];

    final headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.green,
      fontColorHex: ExcelColor.white,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    final headers = ['ID', 'Título', 'Descuento (%)', 'Precio Original', 'Precio Descuento', 'Activa', 'Fecha Inicio', 'Fecha Fin'];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    for (var i = 0; i < promociones.length; i++) {
      final promo = promociones[i];
      final rowIndex = i + 1;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .value = TextCellValue(promo['id'].toString().substring(0, 8));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        .value = TextCellValue(promo['titulo'].toString());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
        .value = DoubleCellValue(promo['descuento']);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
        .value = DoubleCellValue(promo['precioOriginal']);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
        .value = DoubleCellValue(promo['precioDescuento']);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
        .value = TextCellValue(promo['activa'] ? 'Sí' : 'No');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
        .value = TextCellValue(promo['fechaInicio'].toString());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
        .value = TextCellValue(promo['fechaFin'].toString());
    }
  }

  /// Crear hoja de pedidos
  void _crearHojaPedidos(Excel excel, List<Map<String, dynamic>> pedidos) {
    final sheet = excel['Pedidos'];

    final headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.orange,
      fontColorHex: ExcelColor.white,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    final headers = ['Número', 'Cliente', 'Total (S/.)', 'Estado', 'Método Pago', 'Fecha', 'Cant. Productos'];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    for (var i = 0; i < pedidos.length; i++) {
      final pedido = pedidos[i];
      final rowIndex = i + 1;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .value = TextCellValue(pedido['numero'].toString());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        .value = TextCellValue(pedido['clienteNombre'].toString());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
        .value = DoubleCellValue(pedido['total']);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
        .value = TextCellValue(pedido['estado'].toString());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
        .value = TextCellValue(pedido['metodoPago'].toString());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
        .value = TextCellValue(pedido['fecha'].toString());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
        .value = IntCellValue(pedido['cantidadProductos']);
    }
  }

  /// Crear hoja de usuarios
  void _crearHojaUsuarios(Excel excel, List<Map<String, dynamic>> usuarios) {
    final sheet = excel['Usuarios'];

    final headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.purple,
      fontColorHex: ExcelColor.white,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    final headers = ['ID', 'Nombre', 'Email', 'Rol', 'Estado', 'Teléfono', 'Fecha Registro'];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    for (var i = 0; i < usuarios.length; i++) {
      final usuario = usuarios[i];
      final rowIndex = i + 1;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .value = TextCellValue(usuario['id'].toString().substring(0, 8));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        .value = TextCellValue(usuario['nombre'].toString());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
        .value = TextCellValue(usuario['email'].toString());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
        .value = TextCellValue(usuario['rol'].toString());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
        .value = TextCellValue(usuario['estado'].toString());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
        .value = TextCellValue(usuario['telefono'].toString());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
        .value = TextCellValue(usuario['fechaCreacion'].toString());
    }
  }

  /// Crear hoja de estadísticas generales
  void _crearHojaEstadisticas(Excel excel, List<Map<String, dynamic>> pedidos, List<Map<String, dynamic>> productos) {
    final sheet = excel['Estadísticas'];

    final headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.red,
      fontColorHex: ExcelColor.white,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    // Título
    final titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue('RESUMEN ESTADÍSTICO GENERAL');
    titleCell.cellStyle = CellStyle(
      backgroundColorHex: ExcelColor.black,
      fontColorHex: ExcelColor.white,
      bold: true,
      fontSize: 14,
      horizontalAlign: HorizontalAlign.Center,
    );
    // Nota: Se omite el merge para evitar errores de rango en el paquete excel

    // Calcular estadísticas
    final totalPedidos = pedidos.length;
    final totalVentas = pedidos.fold<double>(0, (total, p) => total + (p['total'] as double));
    final promedioVenta = totalPedidos > 0 ? totalVentas / totalPedidos : 0;
    final totalProductos = productos.length;

    final pedidosPorEstado = <String, int>{};
    for (var pedido in pedidos) {
      final estado = pedido['estado'].toString();
      pedidosPorEstado[estado] = (pedidosPorEstado[estado] ?? 0) + 1;
    }

    final ventasPorMetodo = <String, double>{};
    for (var pedido in pedidos) {
      final metodo = pedido['metodoPago'].toString();
      ventasPorMetodo[metodo] = (ventasPorMetodo[metodo] ?? 0) + (pedido['total'] as double);
    }

    // Datos de estadísticas
    var rowIndex = 2;

    // Estadísticas generales
    _agregarEstadistica(sheet, rowIndex++, 'Total de Pedidos', totalPedidos.toString());
    _agregarEstadistica(sheet, rowIndex++, 'Total en Ventas', 'S/. ${totalVentas.toStringAsFixed(2)}');
    _agregarEstadistica(sheet, rowIndex++, 'Promedio por Venta', 'S/. ${promedioVenta.toStringAsFixed(2)}');
    _agregarEstadistica(sheet, rowIndex++, 'Total de Productos', totalProductos.toString());

    rowIndex++;

    // Pedidos por estado
    final estadoCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    estadoCell.value = TextCellValue('PEDIDOS POR ESTADO');
    estadoCell.cellStyle = headerStyle;
    rowIndex++;

    for (var entry in pedidosPorEstado.entries) {
      _agregarEstadistica(sheet, rowIndex++, entry.key, entry.value.toString());
    }

    rowIndex++;

    // Ventas por método de pago
    final metodoCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    metodoCell.value = TextCellValue('VENTAS POR MÉTODO DE PAGO');
    metodoCell.cellStyle = headerStyle;
    rowIndex++;

    for (var entry in ventasPorMetodo.entries) {
      _agregarEstadistica(sheet, rowIndex++, entry.key, 'S/. ${entry.value.toStringAsFixed(2)}');
    }
  }

  /// Crear hoja con datos para gráficos dinámicos
  void _crearHojaGraficos(Excel excel, List<Map<String, dynamic>> pedidos, List<Map<String, dynamic>> productos) {
    final sheet = excel['Datos para Gráficos'];

    final headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.teal,
      fontColorHex: ExcelColor.white,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    // Sección 1: Ventas por Día
    var rowIndex = 0;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
      .value = TextCellValue('VENTAS POR DÍA');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = headerStyle;
    rowIndex++;

    // Encabezados
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
      .value = TextCellValue('Fecha');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
      .value = TextCellValue('Total Ventas (S/.)');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = headerStyle;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).cellStyle = headerStyle;
    rowIndex++;

    // Calcular ventas por día
    final ventasPorDia = <String, double>{};
    for (var pedido in pedidos) {
      final fecha = pedido['fecha'].toString();
      ventasPorDia[fecha] = (ventasPorDia[fecha] ?? 0) + (pedido['total'] as double);
    }

    final fechasOrdenadas = ventasPorDia.keys.toList()..sort();
    for (var fecha in fechasOrdenadas) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .value = TextCellValue(fecha);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        .value = DoubleCellValue(ventasPorDia[fecha]!);
      rowIndex++;
    }

    rowIndex += 2;

    // Sección 2: Pedidos por Estado
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
      .value = TextCellValue('PEDIDOS POR ESTADO');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = headerStyle;
    rowIndex++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
      .value = TextCellValue('Estado');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
      .value = TextCellValue('Cantidad');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = headerStyle;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).cellStyle = headerStyle;
    rowIndex++;

    final pedidosPorEstado = <String, int>{};
    for (var pedido in pedidos) {
      final estado = pedido['estado'].toString();
      pedidosPorEstado[estado] = (pedidosPorEstado[estado] ?? 0) + 1;
    }

    for (var entry in pedidosPorEstado.entries) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .value = TextCellValue(entry.key);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        .value = IntCellValue(entry.value);
      rowIndex++;
    }

    rowIndex += 2;

    // Sección 3: Ventas por Método de Pago
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
      .value = TextCellValue('VENTAS POR MÉTODO DE PAGO');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = headerStyle;
    rowIndex++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
      .value = TextCellValue('Método de Pago');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
      .value = TextCellValue('Total (S/.)');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = headerStyle;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).cellStyle = headerStyle;
    rowIndex++;

    final ventasPorMetodo = <String, double>{};
    for (var pedido in pedidos) {
      final metodo = pedido['metodoPago'].toString();
      ventasPorMetodo[metodo] = (ventasPorMetodo[metodo] ?? 0) + (pedido['total'] as double);
    }

    for (var entry in ventasPorMetodo.entries) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .value = TextCellValue(entry.key);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        .value = DoubleCellValue(entry.value);
      rowIndex++;
    }

    rowIndex += 2;

    // Sección 4: Productos con Bajo Stock
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
      .value = TextCellValue('PRODUCTOS CON BAJO STOCK (≤ 10)');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = headerStyle;
    rowIndex++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
      .value = TextCellValue('Producto');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
      .value = TextCellValue('Stock');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = headerStyle;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).cellStyle = headerStyle;
    rowIndex++;

    final productosBajoStock = productos.where((p) => (p['stock'] as int) <= 10).toList();
    for (var producto in productosBajoStock) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .value = TextCellValue(producto['nombre'].toString());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        .value = IntCellValue(producto['stock']);
      rowIndex++;
    }

    rowIndex += 2;

    // Sección 5: Top 5 Productos Más Vendidos
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
      .value = TextCellValue('TOP 5 PRODUCTOS MÁS VENDIDOS');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = headerStyle;
    rowIndex++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
      .value = TextCellValue('Producto');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
      .value = TextCellValue('Cantidad Vendida');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = headerStyle;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).cellStyle = headerStyle;
    rowIndex++;

    // Calcular productos más vendidos
    final ventasPorProducto = <String, Map<String, dynamic>>{};
    for (var pedido in pedidos) {
      final productosPedido = pedido['productos'] as List<dynamic>? ?? [];
      for (var item in productosPedido) {
        if (item is Map) {
          final productoId = item['productoId']?.toString() ?? item['id']?.toString() ?? '';
          final cantidad = (item['cantidad'] ?? 1) as int;
          final nombre = item['nombre']?.toString() ?? 'Desconocido';

          if (ventasPorProducto.containsKey(productoId)) {
            ventasPorProducto[productoId]!['cantidad'] =
                (ventasPorProducto[productoId]!['cantidad'] as int) + cantidad;
          } else {
            ventasPorProducto[productoId] = {
              'nombre': nombre,
              'cantidad': cantidad,
            };
          }
        }
      }
    }

    final top5Productos = ventasPorProducto.values.toList()
      ..sort((a, b) => (b['cantidad'] as int).compareTo(a['cantidad'] as int));

    for (var producto in top5Productos.take(5)) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .value = TextCellValue(producto['nombre'].toString());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        .value = IntCellValue(producto['cantidad'] as int);
      rowIndex++;
    }

    rowIndex += 2;

    // Sección 6: Productos por Categoría
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
      .value = TextCellValue('PRODUCTOS POR CATEGORÍA');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = headerStyle;
    rowIndex++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
      .value = TextCellValue('Categoría');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
      .value = TextCellValue('Cantidad de Productos');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = headerStyle;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).cellStyle = headerStyle;
    rowIndex++;

    // Calcular productos por categoría
    final productosPorCategoria = <String, int>{};
    for (var producto in productos) {
      final categoria = producto['categoria']?.toString() ?? 'Sin categoría';
      productosPorCategoria[categoria] = (productosPorCategoria[categoria] ?? 0) + 1;
    }

    // Ordenar por cantidad (de mayor a menor)
    final categoriasOrdenadas = productosPorCategoria.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (var entry in categoriasOrdenadas) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .value = TextCellValue(entry.key);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        .value = IntCellValue(entry.value);
      rowIndex++;
    }
  }

  /// Agregar una fila de estadística
  void _agregarEstadistica(Sheet sheet, int rowIndex, String label, String value) {
    final labelStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Left,
    );

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
      .value = TextCellValue(label);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
      .cellStyle = labelStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
      .value = TextCellValue(value);
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

  /// Descargar el archivo Excel en el navegador
  Future<void> _descargarExcel(Excel excel) async {
    try {
      final bytes = excel.encode();
      if (bytes == null) {
        throw Exception('Error al codificar el archivo Excel');
      }

      final fechaActual = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final nombreArchivo = 'Reporte_Reposteria_Arlex_$fechaActual.xlsx';

      // Crear blob y descargar (para Flutter Web)
      final blob = html.Blob([Uint8List.fromList(bytes)]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', nombreArchivo)
        ..click();

      html.Url.revokeObjectUrl(url);

      debugPrint('✅ Reporte generado exitosamente: $nombreArchivo');
    } catch (e) {
      debugPrint('❌ Error al descargar Excel: $e');
      rethrow;
    }
  }
}
