import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_firestore_service.dart';

/// Modelo para Categoría
class CategoriaModelo {
  final String id;
  final String nombre;
  final String descripcion;
  final String icono;
  final int orden;
  final bool activa;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  CategoriaModelo({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.icono,
    required this.orden,
    required this.activa,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  factory CategoriaModelo.fromJson(Map<String, dynamic> json) {
    DateTime fechaCreacion;
    DateTime fechaActualizacion;

    try {
      if (json['fechaCreacion'] is String) {
        fechaCreacion = DateTime.parse(json['fechaCreacion'] as String);
      } else if (json['fechaCreacion'] != null) {
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
        fechaActualizacion = (json['fechaActualizacion'] as dynamic).toDate();
      } else {
        fechaActualizacion = DateTime.now();
      }
    } catch (e) {
      fechaActualizacion = DateTime.now();
    }

    return CategoriaModelo(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String? ?? '',
      icono: json['icono'] as String? ?? 'cake',
      orden: json['orden'] as int? ?? 0,
      activa: json['activa'] as bool? ?? true,
      fechaCreacion: fechaCreacion,
      fechaActualizacion: fechaActualizacion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'icono': icono,
      'orden': orden,
      'activa': activa,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaActualizacion': fechaActualizacion.toIso8601String(),
    };
  }
}

/// Servicio para gestión de categorías
class CategoriasService {
  static final CategoriasService _instance = CategoriasService._internal();
  factory CategoriasService() => _instance;
  CategoriasService._internal();

  final FirebaseFirestoreService _firestore = FirebaseFirestoreService();
  static const String _coleccion = 'categorias';

  // ============================================================================
  // CRUD DE CATEGORÍAS
  // ============================================================================

  /// Crear nueva categoría
  Future<Map<String, dynamic>> crearCategoria(CategoriaModelo categoria) async {
    try {
      final datos = categoria.toJson();
      datos['fechaCreacion'] = FieldValue.serverTimestamp();
      datos['fechaActualizacion'] = FieldValue.serverTimestamp();

      return await _firestore.crear(
        coleccion: _coleccion,
        documentId: categoria.id,
        datos: datos,
      );
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al crear categoría: $e',
      };
    }
  }

  /// Obtener categoría por ID
  Future<CategoriaModelo?> obtenerCategoria(String categoriaId) async {
    try {
      final datos = await _firestore.leer(
        coleccion: _coleccion,
        documentId: categoriaId,
      );

      if (datos != null) {
        return CategoriaModelo.fromJson(datos);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Actualizar categoría
  Future<Map<String, dynamic>> actualizarCategoria({
    required String categoriaId,
    required Map<String, dynamic> cambios,
  }) async {
    try {
      cambios['fechaActualizacion'] = FieldValue.serverTimestamp();

      return await _firestore.actualizar(
        coleccion: _coleccion,
        documentId: categoriaId,
        datos: cambios,
      );
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al actualizar categoría: $e',
      };
    }
  }

  /// Eliminar categoría
  Future<Map<String, dynamic>> eliminarCategoria(String categoriaId) async {
    try {
      // Verificar si hay productos con esta categoría
      final productos = await FirebaseFirestore.instance
          .collection('productos')
          .where('categoriaId', isEqualTo: categoriaId)
          .limit(1)
          .get();

      if (productos.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'No se puede eliminar la categoría porque tiene productos asociados',
        };
      }

      return await _firestore.eliminar(
        coleccion: _coleccion,
        documentId: categoriaId,
      );
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al eliminar categoría: $e',
      };
    }
  }

  /// Obtener todas las categorías
  Future<List<CategoriaModelo>> obtenerTodasLasCategorias({
    bool soloActivas = false,
  }) async {
    try {
      List<Map<String, dynamic>> datos;

      if (soloActivas) {
        datos = await _firestore.consultarDonde(
          coleccion: _coleccion,
          campo: 'activa',
          valor: true,
          orderBy: 'orden',
        );
      } else {
        datos = await _firestore.obtenerTodos(
          coleccion: _coleccion,
          orderBy: 'orden',
        );
      }

      return datos.map((d) => CategoriaModelo.fromJson(d)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Cambiar estado activo/inactivo
  Future<Map<String, dynamic>> cambiarEstado({
    required String categoriaId,
    required bool activa,
  }) async {
    return await actualizarCategoria(
      categoriaId: categoriaId,
      cambios: {'activa': activa},
    );
  }

  /// Stream de categorías en tiempo real
  Stream<List<CategoriaModelo>> streamCategorias({bool soloActivas = false}) {
    if (soloActivas) {
      return _firestore
          .streamDonde(
        coleccion: _coleccion,
        campo: 'activa',
        valor: true,
        orderBy: 'orden',
      )
          .map((lista) {
        return lista.map((d) => CategoriaModelo.fromJson(d)).toList();
      });
    }

    return _firestore
        .streamColeccion(
      coleccion: _coleccion,
      orderBy: 'orden',
    )
        .map((lista) {
      return lista.map((d) => CategoriaModelo.fromJson(d)).toList();
    });
  }

  /// Contar categorías
  Future<int> contarCategorias({bool soloActivas = false}) async {
    if (soloActivas) {
      return await _firestore.contarDocumentos(
        coleccion: _coleccion,
        campo: 'activa',
        valor: true,
      );
    }
    return await _firestore.contarDocumentos(coleccion: _coleccion);
  }

  /// Generar ID único para categoría
  String generarIdCategoria(String nombreCategoria) {
    final nombre = nombreCategoria
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return 'cat_$nombre';
  }
}