// TODO: Uncomment when cloud_firestore package is added to pubspec.yaml
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../configuracion/firebase_config.dart';

// Placeholder types until Firebase is properly configured
abstract class DocumentSnapshot<T> {
  String get id;
  T? data();
  bool get exists;
}

abstract class CollectionReference<T> extends Query<T> {
  Future<DocumentReference<T>> add(T data);
  DocumentReference<T> doc([String? path]);
}

abstract class DocumentReference<T> {
  String get id;
  Future<void> set(T data);
  Future<void> update(Map<String, dynamic> data);
  Future<void> delete();
  Future<DocumentSnapshot<T>> get();
  Stream<DocumentSnapshot<T>> snapshots();
}

abstract class Query<T> {
  Query<T> where(String field, {
    dynamic isEqualTo,
    dynamic isNotEqualTo,
    dynamic isGreaterThan,
    dynamic isGreaterThanOrEqualTo,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
    dynamic arrayContains,
    List<dynamic>? arrayContainsAny,
    List<dynamic>? whereIn,
    List<dynamic>? whereNotIn,
  });
  Query<T> orderBy(String field, {bool descending = false});
  Query<T> limit(int limit);
  Query<T> startAfterDocument(DocumentSnapshot document);
  Future<QuerySnapshot<T>> get();
  Stream<QuerySnapshot<T>> snapshots();
  AggregateQuery count();
}

abstract class QuerySnapshot<T> {
  List<QueryDocumentSnapshot<T>> get docs;
  bool get isEmpty;
}

abstract class QueryDocumentSnapshot<T> extends DocumentSnapshot<T> {}

abstract class AggregateQuery {
  Future<AggregateQuerySnapshot> get();
}

abstract class AggregateQuerySnapshot {
  int? get count;
}

abstract class FirebaseFirestore {
  CollectionReference<Map<String, dynamic>> collection(String path);
  Future<T> runTransaction<T>(Future<T> Function(Transaction transaction) updateFunction);
  WriteBatch batch();
}

abstract class Transaction {
  void set<T>(DocumentReference<T> documentReference, T data);
  void update(DocumentReference documentReference, Map<String, dynamic> data);
  void delete(DocumentReference documentReference);
}

abstract class WriteBatch {
  void set<T>(DocumentReference<T> documentReference, T data);
  void update(DocumentReference documentReference, Map<String, dynamic> data);
  void delete(DocumentReference documentReference);
  Future<void> commit();
}

class FieldValue {
  static dynamic serverTimestamp() => DateTime.now();
}

// Placeholder for FirebaseConfig
class FirebaseConfig {
  static FirebaseFirestore get firestore => _MockFirestore();
}

class _MockFirestore implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    throw UnimplementedError('Firebase not configured');
  }

  @override
  Future<T> runTransaction<T>(Future<T> Function(Transaction transaction) updateFunction) {
    throw UnimplementedError('Firebase not configured');
  }

  @override
  WriteBatch batch() {
    throw UnimplementedError('Firebase not configured');
  }
}

// Explícitamente definir los tipos para uso en el código
typedef FirestoreDocument = DocumentSnapshot<Map<String, dynamic>>;
typedef FirestoreQuery = Query<Map<String, dynamic>>;
typedef FirestoreCollection = CollectionReference<Map<String, dynamic>>;
typedef FirestoreBatch = WriteBatch;
typedef FirestoreTransaction = Transaction;

abstract class RepositoryBase<T> {
  final FirebaseFirestore _firestore = FirebaseConfig.firestore;

  String get collectionName;

  T fromFirestore(DocumentSnapshot doc);
  Map<String, dynamic> toFirestore(T model);

  // Referencia a la colección
  CollectionReference<Map<String, dynamic>> get collection => _firestore.collection(collectionName);

  // Crear un nuevo documento
  Future<String> create(T model) async {
    try {
      final docRef = await collection.add(toFirestore(model));
      return docRef.id;
    } catch (e) {
      throw RepositoryException('Error al crear documento: $e');
    }
  }

  // Crear con ID específico
  Future<void> createWithId(String id, T model) async {
    try {
      await collection.doc(id).set(toFirestore(model));
    } catch (e) {
      throw RepositoryException('Error al crear documento con ID: $e');
    }
  }

  // Obtener por ID
  Future<T?> getById(String id) async {
    try {
      final doc = await collection.doc(id).get();
      if (doc.exists) {
        return fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw RepositoryException('Error al obtener documento: $e');
    }
  }

  // Obtener todos los documentos
  Future<List<T>> getAll({
    int? limit,
    String? orderBy,
    bool descending = false,
  }) async {
    try {
      Query<Map<String, dynamic>> query = collection as Query<Map<String, dynamic>>;

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw RepositoryException('Error al obtener documentos: $e');
    }
  }

  // Obtener con filtros
  Future<List<T>> getWhere(
    String field,
    dynamic value, {
    int? limit,
    String? orderBy,
    bool descending = false,
  }) async {
    try {
      Query<Map<String, dynamic>> query = (collection as Query<Map<String, dynamic>>).where(field, isEqualTo: value);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw RepositoryException('Error al obtener documentos filtrados: $e');
    }
  }

  // Obtener con múltiples filtros
  Future<List<T>> getWithFilters(
    List<QueryFilter> filters, {
    int? limit,
    String? orderBy,
    bool descending = false,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = collection as Query<Map<String, dynamic>>;

      // Aplicar filtros
      for (final filter in filters) {
        query = _applyFilter(query, filter);
      }

      // Aplicar ordenamiento
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Aplicar paginación
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw RepositoryException('Error al obtener documentos con filtros: $e');
    }
  }

  // Actualizar documento
  Future<void> update(String id, Map<String, dynamic> data) async {
    try {
      await collection.doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw RepositoryException('Error al actualizar documento: $e');
    }
  }

  // Actualizar modelo completo
  Future<void> updateModel(String id, T model) async {
    try {
      final data = toFirestore(model);
      data['updatedAt'] = FieldValue.serverTimestamp();
      await collection.doc(id).update(data);
    } catch (e) {
      throw RepositoryException('Error al actualizar modelo: $e');
    }
  }

  // Eliminar documento
  Future<void> delete(String id) async {
    try {
      await collection.doc(id).delete();
    } catch (e) {
      throw RepositoryException('Error al eliminar documento: $e');
    }
  }

  // Verificar si existe
  Future<bool> exists(String id) async {
    try {
      final doc = await collection.doc(id).get();
      return doc.exists;
    } catch (e) {
      throw RepositoryException('Error al verificar existencia: $e');
    }
  }

  // Contar documentos
  Future<int> count({List<QueryFilter>? filters}) async {
    try {
      Query<Map<String, dynamic>> query = collection as Query<Map<String, dynamic>>;

      if (filters != null) {
        for (final filter in filters) {
          query = _applyFilter(query, filter);
        }
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw RepositoryException('Error al contar documentos: $e');
    }
  }

  // Stream de un documento
  Stream<T?> streamById(String id) {
    return collection.doc(id).snapshots().map((doc) {
      if (doc.exists) {
        return fromFirestore(doc);
      }
      return null;
    });
  }

  // Stream de todos los documentos
  Stream<List<T>> streamAll({
    int? limit,
    String? orderBy,
    bool descending = false,
  }) {
    Query<Map<String, dynamic>> query = collection as Query<Map<String, dynamic>>;

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    });
  }

  // Stream con filtros
  Stream<List<T>> streamWithFilters(
    List<QueryFilter> filters, {
    int? limit,
    String? orderBy,
    bool descending = false,
  }) {
    Query<Map<String, dynamic>> query = collection as Query<Map<String, dynamic>>;

    for (final filter in filters) {
      query = _applyFilter(query, filter);
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    });
  }

  // Buscar texto (requiere índices compuestos)
  Future<List<T>> search(
    String searchTerm, {
    required List<String> searchFields,
    int? limit,
    String? orderBy,
    bool descending = false,
  }) async {
    try {
      // Para búsqueda simple, usar whereArrayContains o consultas complejas
      // Nota: Firestore no soporta búsqueda de texto completa nativamente
      final results = <T>[];

      for (final field in searchFields) {
        final snapshot = await (collection as Query<Map<String, dynamic>>)
            .where(field, isGreaterThanOrEqualTo: searchTerm)
            .where(field, isLessThan: '${searchTerm}z')
            .limit(limit ?? 50)
            .get();

        results.addAll(snapshot.docs.map((doc) => fromFirestore(doc)));
      }

      // Remover duplicados basándose en el ID del documento
      final uniqueResults = <String, T>{};
      for (final item in results) {
        final id = _getDocumentId(item);
        if (id != null) {
          uniqueResults[id] = item;
        }
      }

      return uniqueResults.values.toList();
    } catch (e) {
      throw RepositoryException('Error en búsqueda: $e');
    }
  }

  // Transacciones
  Future<R> runTransaction<R>(
    Future<R> Function(Transaction transaction) transactionHandler,
  ) async {
    try {
      return await _firestore.runTransaction(transactionHandler);
    } catch (e) {
      throw RepositoryException('Error en transacción: $e');
    }
  }

  // Batch operations
  WriteBatch createBatch() {
    return _firestore.batch();
  }

  Future<void> commitBatch(WriteBatch batch) async {
    try {
      await batch.commit();
    } catch (e) {
      throw RepositoryException('Error al ejecutar batch: $e');
    }
  }

  // Métodos auxiliares
  Query<Map<String, dynamic>> _applyFilter(Query<Map<String, dynamic>> query, QueryFilter filter) {
    switch (filter.type) {
      case FilterType.equal:
        return query.where(filter.field, isEqualTo: filter.value);
      case FilterType.notEqual:
        return query.where(filter.field, isNotEqualTo: filter.value);
      case FilterType.greaterThan:
        return query.where(filter.field, isGreaterThan: filter.value);
      case FilterType.greaterThanOrEqual:
        return query.where(filter.field, isGreaterThanOrEqualTo: filter.value);
      case FilterType.lessThan:
        return query.where(filter.field, isLessThan: filter.value);
      case FilterType.lessThanOrEqual:
        return query.where(filter.field, isLessThanOrEqualTo: filter.value);
      case FilterType.arrayContains:
        return query.where(filter.field, arrayContains: filter.value);
      case FilterType.arrayContainsAny:
        return query.where(filter.field, arrayContainsAny: filter.value);
      case FilterType.whereIn:
        return query.where(filter.field, whereIn: filter.value);
      case FilterType.whereNotIn:
        return query.where(filter.field, whereNotIn: filter.value);
    }
  }

  // Método para obtener el ID del documento (debe ser implementado por las subclases)
  String? _getDocumentId(T model) {
    // Implementación por defecto - las subclases pueden sobrescribir
    try {
      return (model as dynamic).id;
    } catch (e) {
      return null;
    }
  }
}

// Clase para filtros de consulta
class QueryFilter {
  final String field;
  final dynamic value;
  final FilterType type;

  QueryFilter({
    required this.field,
    required this.value,
    required this.type,
  });

  // Factory methods para facilitar el uso
  factory QueryFilter.equal(String field, dynamic value) {
    return QueryFilter(field: field, value: value, type: FilterType.equal);
  }

  factory QueryFilter.notEqual(String field, dynamic value) {
    return QueryFilter(field: field, value: value, type: FilterType.notEqual);
  }

  factory QueryFilter.greaterThan(String field, dynamic value) {
    return QueryFilter(field: field, value: value, type: FilterType.greaterThan);
  }

  factory QueryFilter.lessThan(String field, dynamic value) {
    return QueryFilter(field: field, value: value, type: FilterType.lessThan);
  }

  factory QueryFilter.arrayContains(String field, dynamic value) {
    return QueryFilter(field: field, value: value, type: FilterType.arrayContains);
  }

  factory QueryFilter.whereIn(String field, List<dynamic> values) {
    return QueryFilter(field: field, value: values, type: FilterType.whereIn);
  }
}

// Enum para tipos de filtros
enum FilterType {
  equal,
  notEqual,
  greaterThan,
  greaterThanOrEqual,
  lessThan,
  lessThanOrEqual,
  arrayContains,
  arrayContainsAny,
  whereIn,
  whereNotIn,
}

// Excepción personalizada para repositorios
class RepositoryException implements Exception {
  final String message;

  RepositoryException(this.message);

  @override
  String toString() => 'RepositoryException: $message';
}

// Clase para resultados paginados
class PaginatedResult<T> {
  final List<T> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;
  final int totalCount;

  PaginatedResult({
    required this.items,
    this.lastDocument,
    required this.hasMore,
    required this.totalCount,
  });
}

// Mixin para operaciones de caché
mixin CacheRepositoryMixin<T> on RepositoryBase<T> {
  final Map<String, T> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  Duration get cacheDuration => const Duration(minutes: 5);

  Future<T?> getCached(String id) async {
    final cached = _cache[id];
    final timestamp = _cacheTimestamps[id];

    if (cached != null && timestamp != null) {
      if (DateTime.now().difference(timestamp) < cacheDuration) {
        return cached;
      } else {
        // Cache expirado
        _cache.remove(id);
        _cacheTimestamps.remove(id);
      }
    }

    // Obtener del repositorio y cachear
    final item = await getById(id);
    if (item != null) {
      _cache[id] = item;
      _cacheTimestamps[id] = DateTime.now();
    }

    return item;
  }

  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  void removeCached(String id) {
    _cache.remove(id);
    _cacheTimestamps.remove(id);
  }
}