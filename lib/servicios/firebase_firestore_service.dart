import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio genérico de Firestore para operaciones CRUD
/// Proporciona métodos reutilizables para todas las colecciones
class FirebaseFirestoreService {
  static final FirebaseFirestoreService _instance =
      FirebaseFirestoreService._internal();
  factory FirebaseFirestoreService() => _instance;
  FirebaseFirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================================
  // MÉTODOS GENÉRICOS CRUD
  // ============================================================================

  /// Crear documento con ID personalizado
  Future<Map<String, dynamic>> crear({
    required String coleccion,
    required String documentId,
    required Map<String, dynamic> datos,
  }) async {
    try {
      await _firestore.collection(coleccion).doc(documentId).set(datos);

      return {
        'success': true,
        'message': 'Documento creado exitosamente',
        'id': documentId,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al crear documento: $e',
      };
    }
  }

  /// Crear documento con ID automático
  Future<Map<String, dynamic>> crearConIdAutomatico({
    required String coleccion,
    required Map<String, dynamic> datos,
  }) async {
    try {
      final docRef = await _firestore.collection(coleccion).add(datos);

      // Actualizar el documento con su propio ID
      await docRef.update({'id': docRef.id});

      return {
        'success': true,
        'message': 'Documento creado exitosamente',
        'id': docRef.id,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al crear documento: $e',
      };
    }
  }

  /// Leer un documento específico
  Future<Map<String, dynamic>?> leer({
    required String coleccion,
    required String documentId,
  }) async {
    try {
      final doc = await _firestore.collection(coleccion).doc(documentId).get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Actualizar documento (merge)
  Future<Map<String, dynamic>> actualizar({
    required String coleccion,
    required String documentId,
    required Map<String, dynamic> datos,
  }) async {
    try {
      await _firestore.collection(coleccion).doc(documentId).update(datos);

      return {
        'success': true,
        'message': 'Documento actualizado exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al actualizar documento: $e',
      };
    }
  }

  /// Eliminar documento
  Future<Map<String, dynamic>> eliminar({
    required String coleccion,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(coleccion).doc(documentId).delete();

      return {
        'success': true,
        'message': 'Documento eliminado exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al eliminar documento: $e',
      };
    }
  }

  /// Obtener todos los documentos de una colección
  Future<List<Map<String, dynamic>>> obtenerTodos({
    required String coleccion,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(coleccion);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Consulta con condición WHERE
  Future<List<Map<String, dynamic>>> consultarDonde({
    required String coleccion,
    required String campo,
    required dynamic valor,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(coleccion).where(campo, isEqualTo: valor);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Stream de un documento
  Stream<Map<String, dynamic>?> streamDocumento({
    required String coleccion,
    required String documentId,
  }) {
    return _firestore.collection(coleccion).doc(documentId).snapshots().map(
          (doc) => doc.exists ? doc.data() : null,
        );
  }

  /// Stream de una colección
  Stream<List<Map<String, dynamic>>> streamColeccion({
    required String coleccion,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(coleccion);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList(),
        );
  }

  /// Stream con condición WHERE
  Stream<List<Map<String, dynamic>>> streamDonde({
    required String coleccion,
    required String campo,
    required dynamic valor,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(coleccion).where(campo, isEqualTo: valor);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList(),
        );
  }

  // ============================================================================
  // MÉTODOS BATCH (TRANSACCIONES EN LOTE)
  // ============================================================================

  /// Crear múltiples documentos en una transacción
  Future<Map<String, dynamic>> crearMultiples({
    required String coleccion,
    required List<Map<String, dynamic>> documentos,
  }) async {
    try {
      final batch = _firestore.batch();

      for (var doc in documentos) {
        final docRef = _firestore.collection(coleccion).doc();
        doc['id'] = docRef.id;
        batch.set(docRef, doc);
      }

      await batch.commit();

      return {
        'success': true,
        'message': '${documentos.length} documentos creados exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al crear documentos: $e',
      };
    }
  }

  /// Eliminar múltiples documentos
  Future<Map<String, dynamic>> eliminarMultiples({
    required String coleccion,
    required List<String> documentIds,
  }) async {
    try {
      final batch = _firestore.batch();

      for (var id in documentIds) {
        batch.delete(_firestore.collection(coleccion).doc(id));
      }

      await batch.commit();

      return {
        'success': true,
        'message': '${documentIds.length} documentos eliminados exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al eliminar documentos: $e',
      };
    }
  }

  // ============================================================================
  // SUBCOLLECTIONS (COLECCIONES ANIDADAS)
  // ============================================================================

  /// Crear documento en subcollection
  Future<Map<String, dynamic>> crearEnSubcoleccion({
    required String coleccion,
    required String documentId,
    required String subcoleccion,
    required Map<String, dynamic> datos,
  }) async {
    try {
      final docRef = await _firestore
          .collection(coleccion)
          .doc(documentId)
          .collection(subcoleccion)
          .add(datos);

      // Actualizar con su propio ID
      await docRef.update({'id': docRef.id});

      return {
        'success': true,
        'message': 'Documento creado en subcolección',
        'id': docRef.id,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al crear en subcolección: $e',
      };
    }
  }

  /// Obtener documentos de subcollection
  Future<List<Map<String, dynamic>>> obtenerSubcoleccion({
    required String coleccion,
    required String documentId,
    required String subcoleccion,
    String? orderBy,
    bool descending = false,
  }) async {
    try {
      Query query = _firestore
          .collection(coleccion)
          .doc(documentId)
          .collection(subcoleccion);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Stream de subcollection
  Stream<List<Map<String, dynamic>>> streamSubcoleccion({
    required String coleccion,
    required String documentId,
    required String subcoleccion,
    String? orderBy,
    bool descending = false,
  }) {
    Query query = _firestore
        .collection(coleccion)
        .doc(documentId)
        .collection(subcoleccion);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList(),
        );
  }

  // ============================================================================
  // UTILIDADES
  // ============================================================================

  /// Contar documentos en una colección
  Future<int> contarDocumentos({
    required String coleccion,
    String? campo,
    dynamic valor,
  }) async {
    try {
      Query query = _firestore.collection(coleccion);

      if (campo != null && valor != null) {
        query = query.where(campo, isEqualTo: valor);
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Verificar si un documento existe
  Future<bool> existeDocumento({
    required String coleccion,
    required String documentId,
  }) async {
    try {
      final doc = await _firestore.collection(coleccion).doc(documentId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Obtener timestamp del servidor
  FieldValue get serverTimestamp => FieldValue.serverTimestamp();

  /// Incrementar valor numérico
  FieldValue incrementar(num valor) => FieldValue.increment(valor);

  /// Decrementar valor numérico
  FieldValue decrementar(num valor) => FieldValue.increment(-valor);

  /// Array union (agregar a array sin duplicados)
  FieldValue arrayUnion(List valores) => FieldValue.arrayUnion(valores);

  /// Array remove (eliminar de array)
  FieldValue arrayRemove(List valores) => FieldValue.arrayRemove(valores);
}
