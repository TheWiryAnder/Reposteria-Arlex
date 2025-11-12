import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/producto_modelo.dart';
import '../modelos/carrito_modelo.dart';
import 'firebase_firestore_service.dart';

/// Servicio del carrito sincronizado con Firebase
class CarritoFirebaseService {
  static final CarritoFirebaseService _instance =
      CarritoFirebaseService._internal();
  factory CarritoFirebaseService() => _instance;
  CarritoFirebaseService._internal();

  final FirebaseFirestoreService _firestore = FirebaseFirestoreService();
  static const String _coleccion = 'carritos';

  // ============================================================================
  // OPERACIONES DEL CARRITO
  // ============================================================================

  /// Obtener carrito del usuario
  Future<CarritoModelo?> obtenerCarrito(String usuarioId) async {
    try {
      final datos = await _firestore.leer(
        coleccion: _coleccion,
        documentId: usuarioId,
      );

      if (datos == null) {
        // Crear carrito vacío si no existe
        await _crearCarritoVacio(usuarioId);
        return CarritoModelo(
          usuarioId: usuarioId,
          items: [],
        );
      }

      return _parsearCarrito(datos);
    } catch (e) {
      return null;
    }
  }

  /// Crear carrito vacío
  Future<void> _crearCarritoVacio(String usuarioId) async {
    final ahora = DateTime.now();
    final expiracion = ahora.add(const Duration(days: 7));

    await _firestore.crear(
      coleccion: _coleccion,
      documentId: usuarioId,
      datos: {
        'usuarioId': usuarioId,
        'items': [],
        'total': 0.0,
        'cantidadTotal': 0,
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'fechaExpiracion': Timestamp.fromDate(expiracion),
      },
    );
  }

  /// Agregar producto al carrito
  Future<Map<String, dynamic>> agregarProducto({
    required String usuarioId,
    required ProductoModelo producto,
    int cantidad = 1,
    String? notasEspeciales,
  }) async {
    try {
      // Obtener carrito actual
      final carritoActual = await obtenerCarrito(usuarioId);

      if (carritoActual == null) {
        return {
          'success': false,
          'message': 'Error al obtener el carrito',
        };
      }

      // Verificar si el producto ya existe
      final items = List<ItemCarrito>.from(carritoActual.items);
      final indiceExistente = items.indexWhere(
        (item) => item.producto.id == producto.id,
      );

      if (indiceExistente != -1) {
        // Incrementar cantidad si ya existe
        items[indiceExistente].cantidad += cantidad;
      } else {
        // Agregar nuevo item
        items.add(ItemCarrito(
          producto: producto,
          cantidad: cantidad,
          notasEspeciales: notasEspeciales,
        ));
      }

      // Guardar en Firebase
      await _guardarCarrito(usuarioId, items);

      return {
        'success': true,
        'message': '${producto.nombre} agregado al carrito',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al agregar producto: $e',
      };
    }
  }

  /// Actualizar cantidad de un producto
  Future<Map<String, dynamic>> actualizarCantidad({
    required String usuarioId,
    required String productoId,
    required int nuevaCantidad,
  }) async {
    try {
      if (nuevaCantidad <= 0) {
        return await eliminarProducto(
          usuarioId: usuarioId,
          productoId: productoId,
        );
      }

      final carritoActual = await obtenerCarrito(usuarioId);

      if (carritoActual == null) {
        return {
          'success': false,
          'message': 'Carrito no encontrado',
        };
      }

      final items = List<ItemCarrito>.from(carritoActual.items);
      final indice = items.indexWhere(
        (item) => item.producto.id == productoId,
      );

      if (indice == -1) {
        return {
          'success': false,
          'message': 'Producto no encontrado en el carrito',
        };
      }

      items[indice].cantidad = nuevaCantidad;

      await _guardarCarrito(usuarioId, items);

      return {
        'success': true,
        'message': 'Cantidad actualizada',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al actualizar cantidad: $e',
      };
    }
  }

  /// Eliminar producto del carrito
  Future<Map<String, dynamic>> eliminarProducto({
    required String usuarioId,
    required String productoId,
  }) async {
    try {
      final carritoActual = await obtenerCarrito(usuarioId);

      if (carritoActual == null) {
        return {
          'success': false,
          'message': 'Carrito no encontrado',
        };
      }

      final items = carritoActual.items
          .where((item) => item.producto.id != productoId)
          .toList();

      await _guardarCarrito(usuarioId, items);

      return {
        'success': true,
        'message': 'Producto eliminado del carrito',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al eliminar producto: $e',
      };
    }
  }

  /// Limpiar carrito
  Future<Map<String, dynamic>> limpiarCarrito(String usuarioId) async {
    try {
      await _guardarCarrito(usuarioId, []);

      return {
        'success': true,
        'message': 'Carrito vaciado',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al limpiar carrito: $e',
      };
    }
  }

  /// Guardar carrito en Firebase
  Future<void> _guardarCarrito(
    String usuarioId,
    List<ItemCarrito> items,
  ) async {
    // Convertir items a formato Firebase
    final itemsData = items.map((item) {
      return {
        'productoId': item.producto.id,
        'productoNombre': item.producto.nombre,
        'productoPrecio': item.producto.precio,
        'productoImagen': item.producto.imagenUrl ?? '',
        'cantidad': item.cantidad,
        'notasEspeciales': item.notasEspeciales ?? '',
      };
    }).toList();

    // Calcular totales
    final total = items.fold<double>(
      0.0,
      (sum, item) => sum + item.subtotal,
    );

    final cantidadTotal = items.fold<int>(
      0,
      (sum, item) => sum + item.cantidad,
    );

    final ahora = DateTime.now();
    final expiracion = ahora.add(const Duration(days: 7));

    await _firestore.actualizar(
      coleccion: _coleccion,
      documentId: usuarioId,
      datos: {
        'items': itemsData,
        'total': total,
        'cantidadTotal': cantidadTotal,
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'fechaExpiracion': Timestamp.fromDate(expiracion),
      },
    );
  }

  // ============================================================================
  // STREAMS EN TIEMPO REAL
  // ============================================================================

  /// Stream del carrito del usuario
  Stream<CarritoModelo?> streamCarrito(String usuarioId) {
    return _firestore
        .streamDocumento(
      coleccion: _coleccion,
      documentId: usuarioId,
    )
        .map((datos) {
      if (datos == null) {
        return CarritoModelo(usuarioId: usuarioId, items: []);
      }
      return _parsearCarrito(datos);
    });
  }

  // ============================================================================
  // UTILIDADES
  // ============================================================================

  /// Parsear datos de Firebase a CarritoModelo
  CarritoModelo _parsearCarrito(Map<String, dynamic> datos) {
    final itemsData = datos['items'] as List? ?? [];

    final items = itemsData.map((itemData) {
      final producto = ProductoModelo(
        id: itemData['productoId'] ?? '',
        nombre: itemData['productoNombre'] ?? '',
        descripcion: '',
        precio: (itemData['productoPrecio'] ?? 0).toDouble(),
        categoria: '',
        imagenUrl: itemData['productoImagen'],
        disponible: true,
        stock: 999,
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
      );

      return ItemCarrito(
        producto: producto,
        cantidad: itemData['cantidad'] ?? 1,
        notasEspeciales: itemData['notasEspeciales'],
      );
    }).toList();

    return CarritoModelo(
      id: datos['usuarioId'],
      usuarioId: datos['usuarioId'],
      items: items,
    );
  }

  /// Verificar si hay items en el carrito
  Future<bool> tieneItems(String usuarioId) async {
    final carrito = await obtenerCarrito(usuarioId);
    return carrito != null && carrito.items.isNotEmpty;
  }

  /// Obtener cantidad total de items
  Future<int> obtenerCantidadTotal(String usuarioId) async {
    final carrito = await obtenerCarrito(usuarioId);
    return carrito?.cantidadTotal ?? 0;
  }

  /// Obtener total del carrito
  Future<double> obtenerTotal(String usuarioId) async {
    final carrito = await obtenerCarrito(usuarioId);
    return carrito?.total ?? 0.0;
  }

  /// Sincronizar carrito local con Firebase
  Future<void> sincronizarCarrito({
    required String usuarioId,
    required List<ItemCarrito> itemsLocales,
  }) async {
    await _guardarCarrito(usuarioId, itemsLocales);
  }
}
