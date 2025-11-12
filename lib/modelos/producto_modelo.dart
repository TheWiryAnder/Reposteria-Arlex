class ProductoModelo {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final double? precioOriginal;  // Precio antes del descuento
  final double? precioDescuento; // Precio con descuento aplicado
  final double? porcentajeDescuento; // Porcentaje de descuento calculado
  final String categoria;
  final String? imagenUrl;
  final bool disponible;
  final int stock;
  final int totalVendidos; // Total de unidades vendidas
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  ProductoModelo({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    this.precioOriginal,
    this.precioDescuento,
    this.porcentajeDescuento,
    required this.categoria,
    this.imagenUrl,
    this.disponible = true,
    this.stock = 0,
    this.totalVendidos = 0,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  // Factory constructor para crear desde JSON/Firebase
  factory ProductoModelo.fromJson(Map<String, dynamic> json) {
    // Manejar categoria: puede venir como 'categoria' o 'categoriaNombre'
    String categoria = json['categoria'] as String? ??
                       json['categoriaNombre'] as String? ??
                       'Sin categoría';

    // Manejar fechas: pueden ser Timestamps de Firebase o Strings ISO
    DateTime fechaCreacion;
    DateTime fechaActualizacion;

    try {
      if (json['fechaCreacion'] is String) {
        fechaCreacion = DateTime.parse(json['fechaCreacion'] as String);
      } else if (json['fechaCreacion'] != null) {
        // Es un Timestamp de Firebase
        fechaCreacion = (json['fechaCreacion'] as dynamic).toDate();
      } else {
        fechaCreacion = DateTime.now();
      }
    } catch (e) {
      fechaCreacion = DateTime.now();
    }

    try {
      if (json['fechaActualizacion'] is String) {
        fechaActualizacion = DateTime.parse(json['fechaActualizacion'] as String);
      } else if (json['fechaActualizacion'] != null) {
        // Es un Timestamp de Firebase
        fechaActualizacion = (json['fechaActualizacion'] as dynamic).toDate();
      } else {
        fechaActualizacion = DateTime.now();
      }
    } catch (e) {
      fechaActualizacion = DateTime.now();
    }

    return ProductoModelo(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String? ?? '',
      precio: (json['precio'] as num?)?.toDouble() ?? 0.0,
      precioOriginal: (json['precioOriginal'] as num?)?.toDouble(),
      precioDescuento: (json['precioDescuento'] as num?)?.toDouble(),
      porcentajeDescuento: (json['porcentajeDescuento'] as num?)?.toDouble(),
      categoria: categoria,
      imagenUrl: json['imagenUrl'] as String?,
      disponible: json['disponible'] as bool? ?? true,
      stock: json['stock'] as int? ?? 0,
      totalVendidos: json['totalVendidos'] as int? ?? 0,
      fechaCreacion: fechaCreacion,
      fechaActualizacion: fechaActualizacion,
    );
  }

  // Convertir a JSON/Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'precioOriginal': precioOriginal,
      'precioDescuento': precioDescuento,
      'porcentajeDescuento': porcentajeDescuento,
      'categoria': categoria,
      'imagenUrl': imagenUrl,
      'disponible': disponible,
      'stock': stock,
      'totalVendidos': totalVendidos,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaActualizacion': fechaActualizacion.toIso8601String(),
    };
  }

  // Copiar con modificaciones
  ProductoModelo copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    double? precio,
    double? precioOriginal,
    double? precioDescuento,
    double? porcentajeDescuento,
    String? categoria,
    String? imagenUrl,
    bool? disponible,
    int? stock,
    int? totalVendidos,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return ProductoModelo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      precioOriginal: precioOriginal ?? this.precioOriginal,
      precioDescuento: precioDescuento ?? this.precioDescuento,
      porcentajeDescuento: porcentajeDescuento ?? this.porcentajeDescuento,
      categoria: categoria ?? this.categoria,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      disponible: disponible ?? this.disponible,
      stock: stock ?? this.stock,
      totalVendidos: totalVendidos ?? this.totalVendidos,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}
