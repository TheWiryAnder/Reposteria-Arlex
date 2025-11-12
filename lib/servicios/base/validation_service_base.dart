import '../../configuracion/app_config.dart';

abstract class ValidationServiceBase {
  // Validaciones de texto
  static ValidationResult validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.error('$fieldName es requerido');
    }
    return ValidationResult.success();
  }

  static ValidationResult validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.error('El email es requerido');
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return ValidationResult.error('Ingresa un email válido');
    }

    return ValidationResult.success();
  }

  static ValidationResult validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationResult.error('La contraseña es requerida');
    }

    if (value.length < AppConfig.minPasswordLength) {
      return ValidationResult.error(
        'La contraseña debe tener al menos ${AppConfig.minPasswordLength} caracteres',
      );
    }

    if (value.length > AppConfig.maxPasswordLength) {
      return ValidationResult.error(
        'La contraseña no puede tener más de ${AppConfig.maxPasswordLength} caracteres',
      );
    }

    // Verificar que tenga al menos una letra y un número
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return ValidationResult.error(
        'La contraseña debe contener al menos una letra',
      );
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return ValidationResult.error(
        'La contraseña debe contener al menos un número',
      );
    }

    return ValidationResult.success();
  }

  static ValidationResult validateConfirmPassword(
    String? password,
    String? confirmPassword,
  ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return ValidationResult.error('Confirma tu contraseña');
    }

    if (password != confirmPassword) {
      return ValidationResult.error('Las contraseñas no coinciden');
    }

    return ValidationResult.success();
  }

  static ValidationResult validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.error('El teléfono es requerido');
    }

    // Remover espacios, guiones y paréntesis
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Verificar que solo contenga números y el símbolo +
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(cleanPhone)) {
      return ValidationResult.error('Ingresa un número de teléfono válido');
    }

    return ValidationResult.success();
  }

  // Validaciones numéricas
  static ValidationResult validateNumber(
    String? value, {
    double? min,
    double? max,
    bool allowNegative = true,
    bool allowDecimals = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.error('Este campo es requerido');
    }

    final number = double.tryParse(value.trim());
    if (number == null) {
      return ValidationResult.error('Ingresa un número válido');
    }

    if (!allowNegative && number < 0) {
      return ValidationResult.error('El número no puede ser negativo');
    }

    if (!allowDecimals && number != number.toInt()) {
      return ValidationResult.error('El número debe ser entero');
    }

    if (min != null && number < min) {
      return ValidationResult.error('El valor debe ser mayor o igual a $min');
    }

    if (max != null && number > max) {
      return ValidationResult.error('El valor debe ser menor o igual a $max');
    }

    return ValidationResult.success();
  }

  static ValidationResult validateInteger(
    String? value, {
    int? min,
    int? max,
    bool allowNegative = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.error('Este campo es requerido');
    }

    final number = int.tryParse(value.trim());
    if (number == null) {
      return ValidationResult.error('Ingresa un número entero válido');
    }

    if (!allowNegative && number < 0) {
      return ValidationResult.error('El número no puede ser negativo');
    }

    if (min != null && number < min) {
      return ValidationResult.error('El valor debe ser mayor o igual a $min');
    }

    if (max != null && number > max) {
      return ValidationResult.error('El valor debe ser menor o igual a $max');
    }

    return ValidationResult.success();
  }

  // Validaciones de precio
  static ValidationResult validatePrice(String? value) {
    final numberResult = validateNumber(
      value,
      min: AppConfig.minProductPrice,
      max: AppConfig.maxProductPrice,
      allowNegative: false,
    );

    if (!numberResult.isValid) {
      return numberResult;
    }

    return ValidationResult.success();
  }

  // Validaciones de texto con longitud
  static ValidationResult validateTextLength(
    String? value,
    String fieldName, {
    int? minLength,
    int? maxLength,
    bool required = true,
  }) {
    if (required) {
      final requiredResult = validateRequired(value, fieldName);
      if (!requiredResult.isValid) {
        return requiredResult;
      }
    }

    if (value != null) {
      if (minLength != null && value.length < minLength) {
        return ValidationResult.error(
          '$fieldName debe tener al menos $minLength caracteres',
        );
      }

      if (maxLength != null && value.length > maxLength) {
        return ValidationResult.error(
          '$fieldName no puede tener más de $maxLength caracteres',
        );
      }
    }

    return ValidationResult.success();
  }

  // Validaciones específicas del negocio
  static ValidationResult validateProductName(String? value) {
    return validateTextLength(
      value,
      'El nombre del producto',
      minLength: AppConfig.minProductNameLength,
      maxLength: AppConfig.maxProductNameLength,
    );
  }

  static ValidationResult validateProductDescription(String? value) {
    return validateTextLength(
      value,
      'La descripción',
      maxLength: AppConfig.maxProductDescriptionLength,
      required: false,
    );
  }

  static ValidationResult validateUsername(String? value) {
    return validateTextLength(
      value,
      'El nombre de usuario',
      minLength: AppConfig.minUsernameLength,
      maxLength: AppConfig.maxUsernameLength,
    );
  }

  // Validaciones de fecha
  static ValidationResult validateDate(
    DateTime? value, {
    bool required = true,
  }) {
    if (required && value == null) {
      return ValidationResult.error('La fecha es requerida');
    }

    return ValidationResult.success();
  }

  static ValidationResult validateFutureDate(
    DateTime? value, {
    bool required = true,
  }) {
    final dateResult = validateDate(value, required: required);
    if (!dateResult.isValid) {
      return dateResult;
    }

    if (value != null && value.isBefore(DateTime.now())) {
      return ValidationResult.error('La fecha debe ser futura');
    }

    return ValidationResult.success();
  }

  static ValidationResult validateDeliveryDate(DateTime? value) {
    final futureResult = validateFutureDate(value);
    if (!futureResult.isValid) {
      return futureResult;
    }

    if (value != null) {
      final daysDifference = value.difference(DateTime.now()).inDays;
      if (daysDifference < 1) {
        return ValidationResult.error(
          'La fecha de entrega debe ser al menos mañana',
        );
      }
    }

    return ValidationResult.success();
  }

  // Validaciones de archivos
  static ValidationResult validateImageFile(
    String? filePath,
    int? fileSizeBytes,
  ) {
    if (filePath == null || filePath.isEmpty) {
      return ValidationResult.error('Selecciona una imagen');
    }

    // Verificar extensión
    final extension = filePath.split('.').last.toLowerCase();
    if (!AppConfig.allowedImageFormats.contains(extension)) {
      return ValidationResult.error(
        'Formato no válido. Usa: ${AppConfig.allowedImageFormats.join(', ')}',
      );
    }

    // Verificar tamaño
    if (fileSizeBytes != null) {
      final maxSizeBytes = AppConfig.maxImageSizeMB * 1024 * 1024;
      if (fileSizeBytes > maxSizeBytes) {
        return ValidationResult.error(
          'La imagen no puede ser mayor a ${AppConfig.maxImageSizeMB}MB',
        );
      }
    }

    return ValidationResult.success();
  }

  // Validaciones compuestas
  static ValidationResult validateMultiple(List<ValidationResult> validations) {
    for (final validation in validations) {
      if (!validation.isValid) {
        return validation;
      }
    }
    return ValidationResult.success();
  }

  // Validaciones de URLs
  static ValidationResult validateUrl(String? value, {bool required = true}) {
    if (!required && (value == null || value.trim().isEmpty)) {
      return ValidationResult.success();
    }

    if (value == null || value.trim().isEmpty) {
      return ValidationResult.error('La URL es requerida');
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value.trim())) {
      return ValidationResult.error('Ingresa una URL válida');
    }

    return ValidationResult.success();
  }

  // Validaciones específicas para pedidos
  static ValidationResult validateOrderAmount(double? amount) {
    if (amount == null || amount <= 0) {
      return ValidationResult.error('El monto del pedido debe ser mayor a 0');
    }

    if (amount < AppConfig.minOrderAmount) {
      return ValidationResult.error(
        'El monto mínimo del pedido es S/. ${AppConfig.minOrderAmount.toStringAsFixed(0)}',
      );
    }

    if (amount > AppConfig.maxOrderAmount) {
      return ValidationResult.error(
        'El monto máximo del pedido es S/. ${AppConfig.maxOrderAmount.toStringAsFixed(0)}',
      );
    }

    return ValidationResult.success();
  }

  // Utilidades
  static String normalizeText(String text) {
    return text.trim().toLowerCase();
  }

  static String sanitizeText(String text) {
    // Remover caracteres especiales peligrosos
    return text
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('\\', '')
        .trim();
  }
}

// Clase para el resultado de validaciones
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult._({required this.isValid, this.errorMessage});

  factory ValidationResult.success() {
    return ValidationResult._(isValid: true);
  }

  factory ValidationResult.error(String message) {
    return ValidationResult._(isValid: false, errorMessage: message);
  }
}

// Clase para validaciones en lote
class FormValidator {
  final Map<String, String> _errors = {};

  void addValidation(String field, ValidationResult result) {
    if (!result.isValid && result.errorMessage != null) {
      _errors[field] = result.errorMessage!;
    }
  }

  bool get isValid => _errors.isEmpty;
  Map<String, String> get errors => Map.unmodifiable(_errors);

  String? getError(String field) => _errors[field];

  void clear() => _errors.clear();

  void removeError(String field) => _errors.remove(field);
}

// Mixin para validaciones en tiempo real
mixin RealTimeValidationMixin {
  final Map<String, ValidationResult> _validationResults = {};

  void setValidationResult(String field, ValidationResult result) {
    _validationResults[field] = result;
  }

  ValidationResult? getValidationResult(String field) {
    return _validationResults[field];
  }

  bool isFieldValid(String field) {
    final result = _validationResults[field];
    return result?.isValid ?? true;
  }

  String? getFieldError(String field) {
    final result = _validationResults[field];
    return result?.isValid == false ? result?.errorMessage : null;
  }

  bool get isFormValid {
    return _validationResults.values.every((result) => result.isValid);
  }

  void clearValidations() {
    _validationResults.clear();
  }
}
