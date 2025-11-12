import 'producto_modelo.dart';

class ItemCarrito {
  final ProductoModelo producto;
  int cantidad;
  String? notasEspeciales;
  final double? precioConDescuento; // Precio con descuento aplicado (si viene de promoción)
  final double? porcentajeDescuento; // Porcentaje de descuento (si aplica)

  ItemCarrito({
    required this.producto,
    this.cantidad = 1,
    this.notasEspeciales,
    this.precioConDescuento,
    this.porcentajeDescuento,
  });

  // Precio unitario a usar (con descuento si aplica, o precio normal)
  double get precioUnitario => precioConDescuento ?? producto.precio;

  // Subtotal calculado con el precio correcto
  double get subtotal => precioUnitario * cantidad;

  // Indica si este item tiene descuento
  bool get tieneDescuento => precioConDescuento != null && porcentajeDescuento != null;

  factory ItemCarrito.fromJson(Map<String, dynamic> json) {
    return ItemCarrito(
      producto: ProductoModelo.fromJson(json['producto'] as Map<String, dynamic>),
      cantidad: json['cantidad'] as int,
      notasEspeciales: json['notasEspeciales'] as String?,
      precioConDescuento: json['precioConDescuento'] as double?,
      porcentajeDescuento: json['porcentajeDescuento'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'producto': producto.toJson(),
      'cantidad': cantidad,
      'notasEspeciales': notasEspeciales,
      'precioConDescuento': precioConDescuento,
      'porcentajeDescuento': porcentajeDescuento,
    };
  }

  ItemCarrito copyWith({
    ProductoModelo? producto,
    int? cantidad,
    String? notasEspeciales,
    double? precioConDescuento,
    double? porcentajeDescuento,
  }) {
    return ItemCarrito(
      producto: producto ?? this.producto,
      cantidad: cantidad ?? this.cantidad,
      notasEspeciales: notasEspeciales ?? this.notasEspeciales,
      precioConDescuento: precioConDescuento ?? this.precioConDescuento,
      porcentajeDescuento: porcentajeDescuento ?? this.porcentajeDescuento,
    );
  }
}

class CarritoModelo {
  final String? id;
  final String? usuarioId;
  final List<ItemCarrito> items;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  CarritoModelo({
    this.id,
    this.usuarioId,
    required this.items,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  })  : fechaCreacion = fechaCreacion ?? DateTime.now(),
        fechaActualizacion = fechaActualizacion ?? DateTime.now();

  double get total {
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  int get cantidadTotal {
    return items.fold(0, (sum, item) => sum + item.cantidad);
  }

  bool get estaVacio => items.isEmpty;

  factory CarritoModelo.fromJson(Map<String, dynamic> json) {
    return CarritoModelo(
      id: json['id'] as String?,
      usuarioId: json['usuarioId'] as String?,
      items: (json['items'] as List<dynamic>)
          .map((item) => ItemCarrito.fromJson(item as Map<String, dynamic>))
          .toList(),
      fechaCreacion: DateTime.parse(json['fechaCreacion'] as String),
      fechaActualizacion: DateTime.parse(json['fechaActualizacion'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'items': items.map((item) => item.toJson()).toList(),
      'fechaCreacion': fechaCreacion?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'fechaActualizacion': fechaActualizacion?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  CarritoModelo copyWith({
    String? id,
    String? usuarioId,
    List<ItemCarrito>? items,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return CarritoModelo(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      items: items ?? this.items,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}
