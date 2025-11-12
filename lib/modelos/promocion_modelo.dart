import 'package:cloud_firestore/cloud_firestore.dart';

class PromocionModelo {
  final String id;
  final String titulo;
  final String descripcion;
  final String? imagenUrl;
  final double descuento; // Porcentaje de descuento (0-100)
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final bool activa;
  final List<String> productosAplicables; // IDs de productos
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  PromocionModelo({
    required this.id,
    required this.titulo,
    required this.descripcion,
    this.imagenUrl,
    required this.descuento,
    required this.fechaInicio,
    required this.fechaFin,
    this.activa = true,
    this.productosAplicables = const [],
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  // Crear desde Firestore
  factory PromocionModelo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PromocionModelo(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      descripcion: data['descripcion'] ?? '',
      imagenUrl: data['imagenUrl'],
      descuento: (data['descuento'] ?? 0).toDouble(),
      fechaInicio: (data['fechaInicio'] as Timestamp).toDate(),
      fechaFin: (data['fechaFin'] as Timestamp).toDate(),
      activa: data['activa'] ?? true,
      productosAplicables: List<String>.from(data['productosAplicables'] ?? []),
      fechaCreacion: data['fechaCreacion'] != null
          ? (data['fechaCreacion'] as Timestamp).toDate()
          : null,
      fechaActualizacion: data['fechaActualizacion'] != null
          ? (data['fechaActualizacion'] as Timestamp).toDate()
          : null,
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'imagenUrl': imagenUrl,
      'descuento': descuento,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFin': Timestamp.fromDate(fechaFin),
      'activa': activa,
      'productosAplicables': productosAplicables,
      'fechaCreacion': fechaCreacion != null ? Timestamp.fromDate(fechaCreacion!) : FieldValue.serverTimestamp(),
      'fechaActualizacion': FieldValue.serverTimestamp(),
    };
  }

  // Verificar si la promoción está vigente
  bool get esVigente {
    final now = DateTime.now();
    return activa &&
           now.isAfter(fechaInicio) &&
           now.isBefore(fechaFin);
  }

  // Copiar con cambios
  PromocionModelo copyWith({
    String? id,
    String? titulo,
    String? descripcion,
    String? imagenUrl,
    double? descuento,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? activa,
    List<String>? productosAplicables,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return PromocionModelo(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      descuento: descuento ?? this.descuento,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      activa: activa ?? this.activa,
      productosAplicables: productosAplicables ?? this.productosAplicables,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}
