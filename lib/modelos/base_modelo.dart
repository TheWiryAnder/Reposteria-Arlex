// TODO: Uncomment when cloud_firestore package is added to pubspec.yaml
// import 'package:cloud_firestore/cloud_firestore.dart';

// Placeholder types until Firebase is properly configured
abstract class DocumentSnapshot<T> {
  String get id;
  T? data();
  bool get exists;
}

abstract class Timestamp {
  DateTime toDate();
}

class FieldValue {
  static dynamic serverTimestamp() => DateTime.now();
}

class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint(this.latitude, this.longitude);
}

abstract class BaseModelo {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  BaseModelo({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore();

  // Método estático que debe ser implementado por cada modelo
  // static T fromFirestore(DocumentSnapshot doc);

  // Método para crear una copia con valores actualizados
  BaseModelo copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
  });

  // Método para obtener solo los campos que han cambiado
  Map<String, dynamic> getChangedFields(BaseModelo oldModel) {
    final newMap = toFirestore();
    final oldMap = oldModel.toFirestore();
    final changes = <String, dynamic>{};

    for (final key in newMap.keys) {
      if (newMap[key] != oldMap[key]) {
        changes[key] = newMap[key];
      }
    }

    return changes;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BaseModelo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return '$runtimeType(id: $id, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

// Mixin para modelos que tienen timestamps automáticos
mixin TimestampMixin {
  static Map<String, dynamic> addTimestamps(Map<String, dynamic> data, {bool isUpdate = false}) {
    final now = FieldValue.serverTimestamp();

    if (!isUpdate) {
      data['createdAt'] = now;
    }
    data['updatedAt'] = now;

    return data;
  }

  static DateTime parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    if (timestamp is DateTime) {
      return timestamp;
    }
    return DateTime.now();
  }
}

// Mixin para modelos que tienen campos de auditoría
mixin AuditMixin {
  String? get createdBy;
  String? get updatedBy;

  static Map<String, dynamic> addAuditFields(
    Map<String, dynamic> data,
    String userId, {
    bool isUpdate = false,
  }) {
    if (!isUpdate) {
      data['createdBy'] = userId;
    }
    data['updatedBy'] = userId;

    return data;
  }
}

// Mixin para modelos que pueden ser activados/desactivados
mixin ActivableMixin {
  bool get activo;

  static Map<String, dynamic> addActivableFields(Map<String, dynamic> data, bool activo) {
    data['activo'] = activo;
    return data;
  }
}

// Mixin para modelos que tienen metadatos adicionales
mixin MetadataMixin {
  Map<String, dynamic>? get metadata;

  static Map<String, dynamic> addMetadata(
    Map<String, dynamic> data,
    Map<String, dynamic>? metadata,
  ) {
    if (metadata != null && metadata.isNotEmpty) {
      data['metadata'] = metadata;
    }
    return data;
  }
}

// Mixin para modelos que tienen tags o etiquetas
mixin TaggableMixin {
  List<String> get tags;

  static Map<String, dynamic> addTags(Map<String, dynamic> data, List<String> tags) {
    data['tags'] = tags;
    return data;
  }

  List<String> get normalizedTags => tags.map((tag) => tag.toLowerCase().trim()).toList();
}

// Mixin para modelos que tienen búsqueda por texto
mixin SearchableMixin {
  List<String> get searchTerms;

  static Map<String, dynamic> addSearchTerms(
    Map<String, dynamic> data,
    List<String> searchTerms,
  ) {
    data['searchTerms'] = searchTerms.map((term) => term.toLowerCase()).toList();
    return data;
  }

  static List<String> generateSearchTerms(List<String> fields) {
    final terms = <String>[];

    for (final field in fields) {
      if (field.isNotEmpty) {
        final words = field.toLowerCase().split(' ');
        terms.addAll(words);

        // Agregar prefijos para búsqueda parcial
        for (final word in words) {
          for (int i = 1; i <= word.length; i++) {
            terms.add(word.substring(0, i));
          }
        }
      }
    }

    return terms.toSet().toList(); // Remover duplicados
  }
}

// Mixin para modelos que tienen ubicación geográfica
mixin GeolocatedMixin {
  GeoPoint? get ubicacion;
  String? get direccion;

  static Map<String, dynamic> addLocationFields(
    Map<String, dynamic> data, {
    GeoPoint? ubicacion,
    String? direccion,
  }) {
    if (ubicacion != null) {
      data['ubicacion'] = ubicacion;
    }
    if (direccion != null) {
      data['direccion'] = direccion;
    }
    return data;
  }
}

// Clase para validaciones de modelos
abstract class ModelValidator<T extends BaseModelo> {
  List<ValidationError> validate(T model);

  bool isValid(T model) {
    return validate(model).isEmpty;
  }

  List<ValidationError> validateRequired(Map<String, dynamic> data, List<String> requiredFields) {
    final errors = <ValidationError>[];

    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null) {
        errors.add(ValidationError(field, 'Campo requerido'));
      } else if (data[field] is String && (data[field] as String).trim().isEmpty) {
        errors.add(ValidationError(field, 'Campo no puede estar vacío'));
      }
    }

    return errors;
  }

  List<ValidationError> validateTypes(Map<String, dynamic> data, Map<String, Type> typeMap) {
    final errors = <ValidationError>[];

    for (final entry in typeMap.entries) {
      final field = entry.key;
      final expectedType = entry.value;

      if (data.containsKey(field) && data[field] != null) {
        if (!_isOfType(data[field], expectedType)) {
          errors.add(ValidationError(field, 'Tipo inválido, se esperaba $expectedType'));
        }
      }
    }

    return errors;
  }

  bool _isOfType(dynamic value, Type expectedType) {
    if (expectedType == String) {
      return value is String;
    } else if (expectedType == int) {
      return value is int;
    } else if (expectedType == double) {
      return value is double || value is int;
    } else if (expectedType == bool) {
      return value is bool;
    } else if (expectedType == List) {
      return value is List;
    } else if (expectedType == Map) {
      return value is Map;
    } else {
      return value.runtimeType == expectedType;
    }
  }
}

// Clase para errores de validación
class ValidationError {
  final String field;
  final String message;

  ValidationError(this.field, this.message);

  @override
  String toString() => '$field: $message';
}

// Enum para estados comunes
enum EstadoGeneral {
  activo,
  inactivo,
  pendiente,
  aprobado,
  rechazado,
  suspendido,
}

// Extensiones útiles para trabajar con modelos
extension BaseModeloExtensions on BaseModelo {
  bool get isNew => id.isEmpty;

  Duration get age => DateTime.now().difference(createdAt);

  Duration get timeSinceUpdate => DateTime.now().difference(updatedAt);

  bool get isRecent => age.inHours < 24;

  bool get isOld => age.inDays > 30;
}

// Clase para configuración de modelos
class ModelConfig {
  final Map<String, dynamic> defaultValues;
  final List<String> requiredFields;
  final Map<String, Type> fieldTypes;
  final Map<String, dynamic> constraints;

  ModelConfig({
    this.defaultValues = const {},
    this.requiredFields = const [],
    this.fieldTypes = const {},
    this.constraints = const {},
  });

  Map<String, dynamic> applyDefaults(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);

    for (final entry in defaultValues.entries) {
      if (!result.containsKey(entry.key) || result[entry.key] == null) {
        result[entry.key] = entry.value;
      }
    }

    return result;
  }
}

// Factory para crear modelos de forma consistente
abstract class ModelFactory<T extends BaseModelo> {
  T create(Map<String, dynamic> data);
  T fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc);

  ModelConfig get config;

  T createWithDefaults(Map<String, dynamic> data) {
    final dataWithDefaults = config.applyDefaults(data);
    return create(dataWithDefaults);
  }

  Map<String, dynamic> prepareForFirestore(Map<String, dynamic> data, {String? userId}) {
    var result = Map<String, dynamic>.from(data);

    // Aplicar timestamps
    result = TimestampMixin.addTimestamps(result);

    // Aplicar auditoría si se proporciona userId
    if (userId != null) {
      result = AuditMixin.addAuditFields(result, userId);
    }

    return result;
  }
}