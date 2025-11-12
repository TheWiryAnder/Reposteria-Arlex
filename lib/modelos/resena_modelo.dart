import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para las reseñas/comentarios de los clientes
class ResenaModelo {
  final String id;
  final String usuarioId;
  final String usuarioNombre;
  final String comentario;
  final int valoracion; // 1 a 5 estrellas
  final DateTime fecha;
  final String? productoId; // ID del producto reseñado
  final String? productoNombre; // Nombre del producto
  final String? productoImagen; // URL de la imagen del producto

  ResenaModelo({
    required this.id,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.comentario,
    required this.valoracion,
    required this.fecha,
    this.productoId,
    this.productoNombre,
    this.productoImagen,
  });

  /// Crear desde un Map de Firebase
  factory ResenaModelo.fromMap(Map<String, dynamic> map, String id) {
    return ResenaModelo(
      id: id,
      usuarioId: map['usuarioId'] ?? '',
      usuarioNombre: map['usuarioNombre'] ?? 'Usuario',
      comentario: map['comentario'] ?? '',
      valoracion: (map['valoracion'] ?? 5) as int,
      fecha: (map['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      productoId: map['productoId'] as String?,
      productoNombre: map['productoNombre'] as String?,
      productoImagen: map['productoImagen'] as String?,
    );
  }

  /// Convertir a Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'usuarioId': usuarioId,
      'usuarioNombre': usuarioNombre,
      'comentario': comentario,
      'valoracion': valoracion,
      'fecha': Timestamp.fromDate(fecha),
      'productoId': productoId,
      'productoNombre': productoNombre,
      'productoImagen': productoImagen,
    };
  }

  /// Crear copia con cambios
  ResenaModelo copyWith({
    String? id,
    String? usuarioId,
    String? usuarioNombre,
    String? comentario,
    int? valoracion,
    DateTime? fecha,
    String? productoId,
    String? productoNombre,
    String? productoImagen,
  }) {
    return ResenaModelo(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      usuarioNombre: usuarioNombre ?? this.usuarioNombre,
      comentario: comentario ?? this.comentario,
      valoracion: valoracion ?? this.valoracion,
      fecha: fecha ?? this.fecha,
      productoId: productoId ?? this.productoId,
      productoNombre: productoNombre ?? this.productoNombre,
      productoImagen: productoImagen ?? this.productoImagen,
    );
  }

  @override
  String toString() {
    return 'ResenaModelo(id: $id, usuarioNombre: $usuarioNombre, valoracion: $valoracion, fecha: $fecha)';
  }
}
