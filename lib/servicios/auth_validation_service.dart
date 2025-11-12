import '../servicios/base/validation_service_base.dart';
import '../configuracion/app_config.dart';

class AuthValidationService extends ValidationServiceBase {
  // Validaciones específicas de login
  static ValidationResult validateLoginEmail(String? value) {
    // Primero validación básica de email
    final emailResult = ValidationServiceBase.validateEmail(value);
    if (!emailResult.isValid) {
      return emailResult;
    }

    // Validaciones adicionales específicas de login
    final email = value!.trim().toLowerCase();

    // Verificar dominios bloqueados
    if (_isDomainBlocked(email)) {
      return ValidationResult.error('Este dominio de email no está permitido');
    }

    return ValidationResult.success();
  }

  static ValidationResult validateLoginPassword(String? value) {
    // Para login, solo verificamos que no esté vacío
    if (value == null || value.isEmpty) {
      return ValidationResult.error('La contraseña es requerida');
    }

    // Mínimo de caracteres más permisivo para login
    if (value.length < 4) {
      return ValidationResult.error('La contraseña debe tener al menos 4 caracteres');
    }

    return ValidationResult.success();
  }

  // Validaciones específicas de registro
  static ValidationResult validateRegisterEmail(String? value) {
    // Validación básica de email
    final emailResult = ValidationServiceBase.validateEmail(value);
    if (!emailResult.isValid) {
      return emailResult;
    }

    final email = value!.trim().toLowerCase();

    // Verificar dominios bloqueados
    if (_isDomainBlocked(email)) {
      return ValidationResult.error('Este dominio de email no está permitido');
    }

    // Verificar longitud máxima
    if (email.length > AppConfig.maxEmailLength) {
      return ValidationResult.error('El email es demasiado largo');
    }

    // Verificar que no sea un email temporal
    if (_isTemporaryEmail(email)) {
      return ValidationResult.error('No se permiten emails temporales');
    }

    return ValidationResult.success();
  }

  static ValidationResult validateRegisterPassword(String? value) {
    // Usar validación estricta para registro
    final passwordResult = ValidationServiceBase.validatePassword(value);
    if (!passwordResult.isValid) {
      return passwordResult;
    }

    // Validaciones adicionales para registro
    final password = value!;

    // Verificar que no contenga espacios
    if (password.contains(' ')) {
      return ValidationResult.error('La contraseña no puede contener espacios');
    }

    // Verificar que no sea una contraseña común
    if (_isCommonPassword(password)) {
      return ValidationResult.error('Esta contraseña es muy común, elige una más segura');
    }

    // Verificar patrones secuenciales
    if (_hasSequentialPattern(password)) {
      return ValidationResult.error('La contraseña no puede tener patrones secuenciales');
    }

    return ValidationResult.success();
  }

  static ValidationResult validateNombre(String? value) {
    return ValidationServiceBase.validateTextLength(
      value,
      'El nombre',
      minLength: AppConfig.minUsernameLength,
      maxLength: AppConfig.maxUsernameLength,
    );
  }

  static ValidationResult validateNombreCompleto(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.error('El nombre es requerido');
    }

    final nombre = value.trim();

    // Verificar longitud mínima y máxima
    if (nombre.length < 2) {
      return ValidationResult.error('El nombre debe tener al menos 2 caracteres');
    }

    if (nombre.length > 50) {
      return ValidationResult.error('El nombre no puede tener más de 50 caracteres');
    }

    // Verificar que solo contenga letras, espacios y algunos caracteres especiales
    if (!RegExp(r"^[a-zA-ZñÑáéíóúÁÉÍÓÚüÜ\s\-'\.]+$").hasMatch(nombre)) {
      return ValidationResult.error('El nombre solo puede contener letras, espacios, guiones y apostrofes');
    }

    // Verificar que tenga al menos una letra
    if (!RegExp(r'[a-zA-ZñÑáéíóúÁÉÍÓÚüÜ]').hasMatch(nombre)) {
      return ValidationResult.error('El nombre debe contener al menos una letra');
    }

    // Verificar que no tenga múltiples espacios consecutivos
    if (RegExp(r'\s{2,}').hasMatch(nombre)) {
      return ValidationResult.error('El nombre no puede tener espacios múltiples consecutivos');
    }

    return ValidationResult.success();
  }

  static ValidationResult validateTelefonoOpcional(String? value) {
    // Si está vacío, es válido (opcional)
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.success();
    }

    // Si no está vacío, aplicar validación completa
    return ValidationServiceBase.validatePhone(value);
  }

  static ValidationResult validateAceptacionTerminos(bool? value) {
    if (value == null || !value) {
      return ValidationResult.error('Debes aceptar los términos y condiciones');
    }
    return ValidationResult.success();
  }

  // Validación de formulario de login completo
  static Map<String, ValidationResult> validateLoginForm({
    required String? email,
    required String? password,
  }) {
    return {
      'email': validateLoginEmail(email),
      'password': validateLoginPassword(password),
    };
  }

  // Validación de formulario de registro completo
  static Map<String, ValidationResult> validateRegisterForm({
    required String? email,
    required String? password,
    required String? confirmPassword,
    required String? nombre,
    String? telefono,
    required bool? aceptaTerminos,
  }) {
    return {
      'email': validateRegisterEmail(email),
      'password': validateRegisterPassword(password),
      'confirmPassword': ValidationServiceBase.validateConfirmPassword(password, confirmPassword),
      'nombre': validateNombreCompleto(nombre),
      'telefono': validateTelefonoOpcional(telefono),
      'aceptaTerminos': validateAceptacionTerminos(aceptaTerminos),
    };
  }

  // Métodos auxiliares privados
  static bool _isDomainBlocked(String email) {
    final domain = email.split('@').last.toLowerCase();
    const blockedDomains = [
      'example.com',
      'test.com',
      'fake.com',
      // Agregar más dominios bloqueados según necesidades
    ];
    return blockedDomains.contains(domain);
  }

  static bool _isTemporaryEmail(String email) {
    final domain = email.split('@').last.toLowerCase();
    const temporaryDomains = [
      '10minutemail.com',
      'tempmail.org',
      'guerrillamail.com',
      'mailinator.com',
      'yopmail.com',
      // Agregar más dominios temporales según necesidades
    ];
    return temporaryDomains.contains(domain);
  }

  static bool _isCommonPassword(String password) {
    final lowerPassword = password.toLowerCase();
    const commonPasswords = [
      'password',
      'password123',
      '123456',
      '123456789',
      'qwerty',
      'abc123',
      'password1',
      'admin',
      'user',
      'guest',
      '000000',
      '111111',
      'welcome',
      'login',
      // Agregar más contraseñas comunes
    ];
    return commonPasswords.contains(lowerPassword);
  }

  static bool _hasSequentialPattern(String password) {
    final lower = password.toLowerCase();

    // Verificar secuencias numéricas
    for (int i = 0; i <= lower.length - 3; i++) {
      final sequence = lower.substring(i, i + 3);
      if (RegExp(r'^(012|123|234|345|456|567|678|789|890|987|876|765|654|543|432|321|210)').hasMatch(sequence)) {
        return true;
      }
    }

    // Verificar secuencias de teclado
    const keyboardPatterns = ['qwe', 'asd', 'zxc', 'qaz', 'wsx'];
    for (final pattern in keyboardPatterns) {
      if (lower.contains(pattern)) {
        return true;
      }
    }

    // Verificar repeticiones
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) {
      return true;
    }

    return false;
  }

  // Utilidades adicionales para validación en tiempo real
  static String? getPasswordStrengthMessage(String? password) {
    if (password == null || password.isEmpty) {
      return null;
    }

    if (password.length < AppConfig.minPasswordLength) {
      return 'Muy débil - Mínimo ${AppConfig.minPasswordLength} caracteres';
    }

    int strength = 0;

    // Verificar longitud
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;

    // Verificar tipos de caracteres
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    switch (strength) {
      case 0:
      case 1:
      case 2:
        return 'Débil';
      case 3:
      case 4:
        return 'Moderada';
      case 5:
      case 6:
        return 'Fuerte';
      default:
        return 'Muy fuerte';
    }
  }

  static double getPasswordStrengthValue(String? password) {
    if (password == null || password.isEmpty) {
      return 0.0;
    }

    if (password.length < AppConfig.minPasswordLength) {
      return 0.2;
    }

    int strength = 0;

    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    return (strength / 6).clamp(0.0, 1.0);
  }

  // Validación de email en tiempo real
  static String? getEmailValidationMessage(String? email) {
    if (email == null || email.isEmpty) {
      return null;
    }

    final result = validateRegisterEmail(email);
    return result.isValid ? null : result.errorMessage;
  }

  // Limpiar y normalizar datos de entrada
  static String normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  static String normalizeNombre(String nombre) {
    return nombre.trim()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  static String? normalizeTelefono(String? telefono) {
    if (telefono == null || telefono.isEmpty) {
      return null;
    }

    // Remover espacios, guiones y paréntesis
    String cleaned = telefono.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Si no empieza con +, agregar código de país por defecto (+57 para Colombia)
    if (!cleaned.startsWith('+')) {
      if (cleaned.startsWith('57')) {
        cleaned = '+$cleaned';
      } else if (cleaned.length == 10) {
        cleaned = '+57$cleaned';
      }
    }

    return cleaned;
  }
}