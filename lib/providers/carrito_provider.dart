import 'package:flutter/material.dart';
import '../modelos/carrito_modelo.dart';
import '../modelos/producto_modelo.dart';

class CarritoProvider extends ChangeNotifier {
  static CarritoProvider? _instance;
  static CarritoProvider get instance => _instance ??= CarritoProvider._();

  CarritoProvider._();

  CarritoModelo _carrito = CarritoModelo(
    items: [],
    fechaCreacion: DateTime.now(),
    fechaActualizacion: DateTime.now(),
  );

  CarritoModelo get carrito => _carrito;
  List<ItemCarrito> get items => _carrito.items;
  double get total => _carrito.total;
  int get cantidadTotal => _carrito.cantidadTotal;
  bool get estaVacio => _carrito.estaVacio;

  // Agregar producto al carrito
  void agregarProducto(
    ProductoModelo producto, {
    int cantidad = 1,
    String? notas,
    double? precioConDescuento,
    double? porcentajeDescuento,
  }) {
    // Verificar si el producto ya existe en el carrito (con el mismo precio/descuento)
    final index = _carrito.items.indexWhere((item) =>
      item.producto.id == producto.id &&
      item.precioConDescuento == precioConDescuento
    );

    if (index != -1) {
      // Si ya existe con el mismo descuento, aumentar la cantidad
      _carrito.items[index].cantidad += cantidad;
    } else {
      // Si no existe o tiene diferente descuento, agregarlo como nuevo item
      _carrito.items.add(ItemCarrito(
        producto: producto,
        cantidad: cantidad,
        notasEspeciales: notas,
        precioConDescuento: precioConDescuento,
        porcentajeDescuento: porcentajeDescuento,
      ));
    }

    _actualizarCarrito();
  }

  // Eliminar producto del carrito
  void eliminarProducto(String productoId) {
    _carrito.items.removeWhere((item) => item.producto.id == productoId);
    _actualizarCarrito();
  }

  // Actualizar cantidad de un producto
  void actualizarCantidad(String productoId, int nuevaCantidad) {
    if (nuevaCantidad <= 0) {
      eliminarProducto(productoId);
      return;
    }

    final index = _carrito.items.indexWhere((item) => item.producto.id == productoId);
    if (index != -1) {
      _carrito.items[index].cantidad = nuevaCantidad;
      _actualizarCarrito();
    }
  }

  // Incrementar cantidad
  void incrementarCantidad(String productoId) {
    final index = _carrito.items.indexWhere((item) => item.producto.id == productoId);
    if (index != -1) {
      _carrito.items[index].cantidad++;
      _actualizarCarrito();
    }
  }

  // Decrementar cantidad
  void decrementarCantidad(String productoId) {
    final index = _carrito.items.indexWhere((item) => item.producto.id == productoId);
    if (index != -1) {
      if (_carrito.items[index].cantidad > 1) {
        _carrito.items[index].cantidad--;
        _actualizarCarrito();
      } else {
        eliminarProducto(productoId);
      }
    }
  }

  // Actualizar notas especiales de un producto
  void actualizarNotas(String productoId, String? notas) {
    final index = _carrito.items.indexWhere((item) => item.producto.id == productoId);
    if (index != -1) {
      _carrito.items[index].notasEspeciales = notas;
      _actualizarCarrito();
    }
  }

  // Limpiar carrito
  void limpiarCarrito() {
    _carrito = CarritoModelo(
      items: [],
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
    notifyListeners();
  }

  // Verificar si un producto está en el carrito
  bool tieneProducto(String productoId) {
    return _carrito.items.any((item) => item.producto.id == productoId);
  }

  // Obtener cantidad de un producto en el carrito
  int getCantidadProducto(String productoId) {
    final index = _carrito.items.indexWhere((item) => item.producto.id == productoId);
    return index != -1 ? _carrito.items[index].cantidad : 0;
  }

  // Método privado para actualizar el carrito
  void _actualizarCarrito() {
    _carrito = _carrito.copyWith(
      fechaActualizacion: DateTime.now(),
    );
    notifyListeners();
  }

  // Guardar carrito (para futuro con Firebase)
  Future<void> guardarCarrito(String usuarioId) async {
    // TODO: Implementar guardado en Firebase
    _carrito = _carrito.copyWith(usuarioId: usuarioId);
    notifyListeners();
  }

  // Cargar carrito (para futuro con Firebase)
  Future<void> cargarCarrito(String usuarioId) async {
    // TODO: Implementar carga desde Firebase
  }
}
