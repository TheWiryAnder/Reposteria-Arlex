import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/producto_modelo.dart';
import 'firebase_firestore_service.dart';

/// Servicio específico para gestión de productos
class ProductosService {
  static final ProductosService _instance = ProductosService._internal();
  factory ProductosService() => _instance;
  ProductosService._internal();

  final FirebaseFirestoreService _firestore = FirebaseFirestoreService();
  static const String _coleccion = 'productos';

  // ============================================================================
  // CRUD DE PRODUCTOS
  // ============================================================================

  /// Crear nuevo producto
  Future<Map<String, dynamic>> crearProducto(ProductoModelo producto) async {
    try {
      final datos = producto.toJson();
      datos['fechaCreacion'] = FieldValue.serverTimestamp();
      datos['fechaActualizacion'] = FieldValue.serverTimestamp();

      return await _firestore.crear(
        coleccion: _coleccion,
        documentId: producto.id,
        datos: datos,
      );
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al crear producto: $e',
      };
    }
  }

  /// Obtener producto por ID
  Future<ProductoModelo?> obtenerProducto(String productoId) async {
    try {
      final datos = await _firestore.leer(
        coleccion: _coleccion,
        documentId: productoId,
      );

      if (datos != null) {
        return ProductoModelo.fromJson(datos);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Actualizar producto
  Future<Map<String, dynamic>> actualizarProducto({
    required String productoId,
    required Map<String, dynamic> cambios,
  }) async {
    try {
      cambios['fechaActualizacion'] = FieldValue.serverTimestamp();

      return await _firestore.actualizar(
        coleccion: _coleccion,
        documentId: productoId,
        datos: cambios,
      );
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al actualizar producto: $e',
      };
    }
  }

  /// Eliminar producto
  Future<Map<String, dynamic>> eliminarProducto(String productoId) async {
    return await _firestore.eliminar(
      coleccion: _coleccion,
      documentId: productoId,
    );
  }

  /// Obtener todos los productos
  Future<List<ProductoModelo>> obtenerTodosLosProductos({
    bool soloDisponibles = false,
  }) async {
    try {
      List<Map<String, dynamic>> datos;

      if (soloDisponibles) {
        datos = await _firestore.consultarDonde(
          coleccion: _coleccion,
          campo: 'disponible',
          valor: true,
          orderBy: 'nombre',
        );
      } else {
        datos = await _firestore.obtenerTodos(
          coleccion: _coleccion,
          orderBy: 'nombre',
        );
      }

      return datos.map((d) => ProductoModelo.fromJson(d)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtener productos por categoría
  Future<List<ProductoModelo>> obtenerProductosPorCategoria({
    required String categoria,
    bool soloDisponibles = true,
  }) async {
    try {
      // Convertir el nombre de categoría a ID (ej: "Tortas" -> "cat_tortas")
      String categoriaId = _convertirNombreAId(categoria);

      // Intentar buscar por 'categoriaNombre' primero (estructura Firebase actual)
      var datos = await _firestore.consultarDonde(
        coleccion: _coleccion,
        campo: 'categoriaNombre',
        valor: categoria,
        orderBy: 'nombre',
      );

      // Si no encontró resultados con 'categoriaNombre', intentar con 'categoria' usando el ID
      if (datos.isEmpty) {
        datos = await _firestore.consultarDonde(
          coleccion: _coleccion,
          campo: 'categoria',
          valor: categoriaId,  // Usar el ID convertido
          orderBy: 'nombre',
        );
      }

      // Si tampoco encontró con el ID, intentar con el nombre directo
      if (datos.isEmpty) {
        datos = await _firestore.consultarDonde(
          coleccion: _coleccion,
          campo: 'categoria',
          valor: categoria,
          orderBy: 'nombre',
        );
      }

      List<ProductoModelo> productos =
          datos.map((d) => ProductoModelo.fromJson(d)).toList();

      if (soloDisponibles) {
        productos = productos.where((p) => p.disponible).toList();
      }

      return productos;
    } catch (e) {
      return [];
    }
  }

  /// Convertir nombre de categoría a ID (ej: "Tortas" -> "cat_tortas")
  String _convertirNombreAId(String nombreCategoria) {
    // Convertir a minúsculas y reemplazar espacios por guiones bajos
    final nombreLower = nombreCategoria.toLowerCase().replaceAll(' ', '_');
    return 'cat_$nombreLower';
  }

  /// Convertir ID de categoría a nombre (ej: "cat_tortas" -> "Tortas")
  static String convertirIdANombre(String categoriaId) {
    // Mapa de conversión de IDs a nombres
    const mapaCategoria = {
      'cat_tortas': 'Tortas',
      'cat_galletas': 'Galletas',
      'cat_postres': 'Postres',
      'cat_pasteles': 'Pasteles',
      'cat_bocaditos': 'Bocaditos',
      'cat_gaseosas': 'Gaseosas',
    };

    // Retornar el nombre si existe en el mapa, de lo contrario capitalizar el ID
    if (mapaCategoria.containsKey(categoriaId)) {
      return mapaCategoria[categoriaId]!;
    }

    // Si no está en el mapa, intentar convertir el ID a un nombre legible
    if (categoriaId.startsWith('cat_')) {
      final nombre = categoriaId.substring(4); // Quitar 'cat_'
      return nombre[0].toUpperCase() + nombre.substring(1).replaceAll('_', ' ');
    }

    return categoriaId; // Retornar el ID original si no se puede convertir
  }

  /// Obtener todas las categorías únicas disponibles desde la colección 'categorias'
  Future<List<String>> obtenerCategorias() async {
    try {
      // Primero intentar obtener categorías desde la colección 'categorias'
      final categoriasData = await _firestore.obtenerTodos(
        coleccion: 'categorias',
        orderBy: 'orden',
      );

      if (categoriasData.isNotEmpty) {
        // Filtrar solo categorías activas y extraer los nombres
        return categoriasData
            .where((cat) => cat['activa'] == true)
            .map((cat) => cat['nombre'] as String)
            .toList();
      }

      // Si no hay categorías en la colección, obtenerlas de los productos
      final productos = await obtenerTodosLosProductos(soloDisponibles: true);
      final categorias = productos.map((p) => p.categoria).toSet().toList();
      categorias.sort();
      return categorias;
    } catch (e) {
      return [];
    }
  }

  /// Obtener productos destacados
  Future<List<ProductoModelo>> obtenerProductosDestacados({
    int limite = 10,
  }) async {
    try {
      final datos = await _firestore.consultarDonde(
        coleccion: _coleccion,
        campo: 'destacado',
        valor: true,
        orderBy: 'totalVendidos',
        descending: true,
        limit: limite,
      );

      return datos
          .map((d) => ProductoModelo.fromJson(d))
          .where((p) => p.disponible)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Buscar productos por nombre
  Future<List<ProductoModelo>> buscarProductos(String termino) async {
    try {
      final todos = await obtenerTodosLosProductos(soloDisponibles: true);

      final terminoLower = termino.toLowerCase();

      return todos
          .where((p) =>
              p.nombre.toLowerCase().contains(terminoLower) ||
              p.descripcion.toLowerCase().contains(terminoLower))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ============================================================================
  // GESTIÓN DE STOCK
  // ============================================================================

  /// Actualizar stock del producto
  Future<Map<String, dynamic>> actualizarStock({
    required String productoId,
    required int nuevoStock,
  }) async {
    return await actualizarProducto(
      productoId: productoId,
      cambios: {'stock': nuevoStock},
    );
  }

  /// Incrementar stock
  Future<Map<String, dynamic>> incrementarStock({
    required String productoId,
    required int cantidad,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection(_coleccion)
          .doc(productoId)
          .update({
        'stock': FieldValue.increment(cantidad),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Stock incrementado',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al incrementar stock: $e',
      };
    }
  }

  /// Decrementar stock
  Future<Map<String, dynamic>> decrementarStock({
    required String productoId,
    required int cantidad,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection(_coleccion)
          .doc(productoId)
          .update({
        'stock': FieldValue.increment(-cantidad),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Stock decrementado',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al decrementar stock: $e',
      };
    }
  }

  /// Obtener productos con stock bajo
  Future<List<ProductoModelo>> obtenerProductosStockBajo() async {
    try {
      final todos = await obtenerTodosLosProductos();

      return todos.where((p) => p.stock < 5 && p.disponible).toList();
    } catch (e) {
      return [];
    }
  }

  // ============================================================================
  // STREAMS EN TIEMPO REAL
  // ============================================================================

  /// Stream de todos los productos
  Stream<List<ProductoModelo>> streamProductos({
    bool soloDisponibles = false,
  }) {
    if (soloDisponibles) {
      return _firestore
          .streamDonde(
        coleccion: _coleccion,
        campo: 'disponible',
        valor: true,
        // Removido orderBy para evitar requerir índice compuesto
      )
          .map((lista) {
        // Ordenar localmente después de obtener los datos
        final productos = lista.map((d) => ProductoModelo.fromJson(d)).toList();
        productos.sort((a, b) => a.nombre.compareTo(b.nombre));
        return productos;
      });
    }

    return _firestore
        .streamColeccion(
      coleccion: _coleccion,
      // Removido orderBy para evitar conflictos
    )
        .map((lista) {
      // Ordenar localmente después de obtener los datos
      final productos = lista.map((d) => ProductoModelo.fromJson(d)).toList();
      productos.sort((a, b) => a.nombre.compareTo(b.nombre));
      return productos;
    });
  }

  /// Stream de productos por categoría
  Stream<List<ProductoModelo>> streamProductosPorCategoria(
      String categoria) {
    // Usar 'categoriaNombre' para la estructura actual de Firebase
    return _firestore
        .streamDonde(
      coleccion: _coleccion,
      campo: 'categoriaNombre',
      valor: categoria,
      orderBy: 'nombre',
    )
        .map((lista) {
      return lista
          .map((d) => ProductoModelo.fromJson(d))
          .where((p) => p.disponible)
          .toList();
    });
  }

  /// Stream de un producto específico
  Stream<ProductoModelo?> streamProducto(String productoId) {
    return _firestore
        .streamDocumento(
      coleccion: _coleccion,
      documentId: productoId,
    )
        .map((datos) {
      if (datos != null) {
        return ProductoModelo.fromJson(datos);
      }
      return null;
    });
  }

  // ============================================================================
  // ESTADÍSTICAS Y UTILIDADES
  // ============================================================================

  /// Actualizar estadísticas de venta
  Future<void> actualizarEstadisticasVenta({
    required String productoId,
    required int cantidadVendida,
  }) async {
    await FirebaseFirestore.instance
        .collection(_coleccion)
        .doc(productoId)
        .update({
      'totalVendidos': FieldValue.increment(cantidadVendida),
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });
  }

  /// Actualizar calificación
  Future<void> actualizarCalificacion({
    required String productoId,
    required double promedioCalificacion,
    required int numeroCalificaciones,
  }) async {
    await actualizarProducto(
      productoId: productoId,
      cambios: {
        'calificacionPromedio': promedioCalificacion,
        'numeroCalificaciones': numeroCalificaciones,
      },
    );
  }

  /// Marcar producto como destacado
  Future<Map<String, dynamic>> marcarDestacado({
    required String productoId,
    required bool destacado,
  }) async {
    return await actualizarProducto(
      productoId: productoId,
      cambios: {'destacado': destacado},
    );
  }

  /// Cambiar disponibilidad
  Future<Map<String, dynamic>> cambiarDisponibilidad({
    required String productoId,
    required bool disponible,
  }) async {
    return await actualizarProducto(
      productoId: productoId,
      cambios: {'disponible': disponible},
    );
  }

  /// Contar productos total
  Future<int> contarProductos({bool soloDisponibles = false}) async {
    if (soloDisponibles) {
      return await _firestore.contarDocumentos(
        coleccion: _coleccion,
        campo: 'disponible',
        valor: true,
      );
    }
    return await _firestore.contarDocumentos(coleccion: _coleccion);
  }

  /// Diagnóstico: Obtener información detallada de productos y categorías
  Future<Map<String, dynamic>> diagnosticarProductos() async {
    try {
      // 1. Contar productos totales
      final totalProductos = await contarProductos();

      // 2. Obtener todos los productos
      final productos = await obtenerTodosLosProductos();

      // 3. Obtener categorías únicas de productos
      final categoriasDeProductos = productos.map((p) => p.categoria).toSet().toList();
      categoriasDeProductos.sort();

      // 4. Obtener categorías desde la colección 'categorias'
      final categoriasData = await _firestore.obtenerTodos(
        coleccion: 'categorias',
        orderBy: 'orden',
      );

      // 5. Contar productos por categoría
      Map<String, int> productosPorCategoria = {};
      for (var categoria in categoriasDeProductos) {
        final count = productos.where((p) => p.categoria == categoria).length;
        productosPorCategoria[categoria] = count;
      }

      // 6. Obtener muestra de productos (primeros 3)
      final muestraProductos = productos.take(3).map((p) => {
        'id': p.id,
        'nombre': p.nombre,
        'categoria': p.categoria,
        'disponible': p.disponible,
        'stock': p.stock,
        'precio': p.precio,
      }).toList();

      return {
        'success': true,
        'totalProductos': totalProductos,
        'productosObtenidos': productos.length,
        'categoriasEnProductos': categoriasDeProductos,
        'categoriasEnColeccion': categoriasData.length,
        'categoriasActivas': categoriasData.where((c) => c['activa'] == true).length,
        'productosPorCategoria': productosPorCategoria,
        'muestraProductos': muestraProductos,
        'categoriasData': categoriasData.map((c) => {
          'nombre': c['nombre'],
          'activa': c['activa'],
          'orden': c['orden'],
        }).toList(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ============================================================================
  // SCRIPT DE INICIALIZACIÓN
  // ============================================================================

  /// Inicializar campo totalVendidos en todos los productos
  /// Este método debe ejecutarse UNA VEZ para migrar productos existentes
  Future<Map<String, dynamic>> inicializarTotalVendidos() async {
    try {
      // 1. Obtener todos los productos
      final snapshot = await FirebaseFirestore.instance
          .collection(_coleccion)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'success': true,
          'message': 'No se encontraron productos en la base de datos.',
          'totalProductos': 0,
          'productosActualizados': 0,
          'productosYaExistian': 0,
        };
      }

      // 2. Actualizar cada producto que no tenga totalVendidos
      int actualizados = 0;
      int yaExistian = 0;
      final List<String> errores = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();

          // Solo actualizar si no existe el campo o es null
          if (!data.containsKey('totalVendidos') || data['totalVendidos'] == null) {
            await FirebaseFirestore.instance
                .collection(_coleccion)
                .doc(doc.id)
                .update({
              'totalVendidos': 0,
              'fechaActualizacion': FieldValue.serverTimestamp(),
            });
            actualizados++;
          } else {
            yaExistian++;
          }
        } catch (e) {
          errores.add('Error en producto ${doc.id}: $e');
        }
      }

      return {
        'success': true,
        'message': 'Script ejecutado exitosamente',
        'totalProductos': snapshot.docs.length,
        'productosActualizados': actualizados,
        'productosYaExistian': yaExistian,
        'errores': errores,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al ejecutar el script: $e',
      };
    }
  }
}
