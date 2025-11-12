import 'package:flutter/material.dart';
import '../../../servicios/auth_service.dart';
import '../../../servicios/auth_validation_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../modelos/usuario_modelo.dart';
import '../../../servicios/base/api_service_base.dart';

class AuthControlador extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;
  final AuthProvider _authProvider;

  // Controladores de formulario
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController direccionController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Estados del formulario
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _recordarme = false;
  bool _aceptaTerminos = false;

  // Errores de validación
  String? _emailError;
  String? _passwordError;
  String? _nombreError;
  String? _telefonoError;
  String? _confirmPasswordError;

  // Mensaje de error general
  String? _errorMessage;

  AuthControlador(this._authProvider);

  // Getters
  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  bool get recordarme => _recordarme;
  bool get aceptaTerminos => _aceptaTerminos;
  String? get emailError => _emailError;
  String? get passwordError => _passwordError;
  String? get nombreError => _nombreError;
  String? get telefonoError => _telefonoError;
  String? get confirmPasswordError => _confirmPasswordError;
  String? get errorMessage => _errorMessage;

  // Validar formulario de login
  bool get isLoginFormValid {
    return _emailError == null &&
        _passwordError == null &&
        emailController.text.isNotEmpty &&
        passwordController.text.isNotEmpty;
  }

  // Validar formulario de registro
  bool get isRegisterFormValid {
    return _emailError == null &&
        _passwordError == null &&
        _nombreError == null &&
        _telefonoError == null &&
        _confirmPasswordError == null &&
        emailController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        nombreController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty &&
        _aceptaTerminos;
  }

  // Métodos para alternar visibilidad de contraseñas
  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  // Métodos para cambiar estados
  void setRecordarme(bool value) {
    _recordarme = value;
    notifyListeners();
  }

  void setAceptaTerminos(bool value) {
    _aceptaTerminos = value;
    notifyListeners();
  }

  // Limpiar mensaje de error
  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  // Validaciones en tiempo real
  void validateEmail() {
    final result = AuthValidationService.validateLoginEmail(emailController.text);
    _emailError = result.isValid ? null : result.errorMessage;
    notifyListeners();
  }

  void validateRegisterEmail() {
    final result = AuthValidationService.validateRegisterEmail(emailController.text);
    _emailError = result.isValid ? null : result.errorMessage;
    notifyListeners();
  }

  void validatePassword() {
    final result = AuthValidationService.validateLoginPassword(passwordController.text);
    _passwordError = result.isValid ? null : result.errorMessage;
    notifyListeners();
  }

  void validateRegisterPassword() {
    final result = AuthValidationService.validateRegisterPassword(passwordController.text);
    _passwordError = result.isValid ? null : result.errorMessage;

    // También validar confirmación si ya tiene texto
    if (confirmPasswordController.text.isNotEmpty) {
      validateConfirmPassword();
    }
    notifyListeners();
  }

  void validateNombre() {
    final result = AuthValidationService.validateNombreCompleto(nombreController.text);
    _nombreError = result.isValid ? null : result.errorMessage;
    notifyListeners();
  }

  void validateTelefono() {
    final result = AuthValidationService.validateTelefonoOpcional(telefonoController.text);
    _telefonoError = result.isValid ? null : result.errorMessage;
    notifyListeners();
  }

  void validateConfirmPassword() {
    final result = AuthValidationService.validateConfirmPassword(
      passwordController.text,
      confirmPasswordController.text,
    );
    _confirmPasswordError = result.isValid ? null : result.errorMessage;
    notifyListeners();
  }

  // Método de login
  Future<bool> login() async {
    if (!isLoginFormValid) {
      _errorMessage = 'Por favor completa todos los campos correctamente';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    clearErrorMessage();

    try {
      final datos = DatosLogin(
        email: AuthValidationService.normalizeEmail(emailController.text),
        password: passwordController.text,
        recordarme: _recordarme,
      );

      // Usar método mock para desarrollo
      final response = await _authService.loginMock(datos);

      if (response.isSuccess && response.data != null) {
        await _authProvider.setAuthenticatedUser(
          response.data!.usuario,
          response.data!.token,
          response.data!.refreshToken,
        );

        _limpiarFormulario();
        _setLoading(false);
        return true;
      } else {
        _errorMessage = response.error?.message ?? 'Error desconocido en el login';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error de conexión. Intenta nuevamente.';
      _setLoading(false);
      return false;
    }
  }

  // Método de registro
  Future<bool> register() async {
    if (!isRegisterFormValid) {
      _errorMessage = 'Por favor completa todos los campos correctamente';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    clearErrorMessage();

    try {
      final datos = DatosRegistro(
        email: AuthValidationService.normalizeEmail(emailController.text),
        password: passwordController.text,
        nombre: AuthValidationService.normalizeNombre(nombreController.text),
        telefono: AuthValidationService.normalizeTelefono(telefonoController.text),
        direccion: direccionController.text.isNotEmpty ? direccionController.text.trim() : null,
        aceptaTerminos: _aceptaTerminos,
      );

      // Usar método mock para desarrollo
      final response = await _authService.registerMock(datos);

      if (response.isSuccess && response.data != null) {
        await _authProvider.setAuthenticatedUser(
          response.data!.usuario,
          response.data!.token,
          response.data!.refreshToken,
        );

        _limpiarFormulario();
        _setLoading(false);
        return true;
      } else {
        _errorMessage = response.error?.message ?? 'Error desconocido en el registro';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error de conexión. Intenta nuevamente.';
      _setLoading(false);
      return false;
    }
  }

  // Método de logout
  Future<void> logout() async {
    _setLoading(true);

    try {
      // Si hay un token, intentar logout del servidor
      if (_authProvider.isAuthenticated) {
        await _authService.logout(_authProvider.token!);
      }
    } catch (e) {
      // Ignorar errores del servidor en logout
      debugPrint('Error en logout del servidor: $e');
    } finally {
      // Siempre limpiar el estado local
      await _authProvider.logout();
      _limpiarFormulario();
      _setLoading(false);
    }
  }

  // Verificar si el email existe
  Future<bool> checkEmailExists(String email) async {
    if (email.isEmpty) return false;

    try {
      final response = await _authService.checkEmailExists(email);
      return response.isSuccess && response.data == true;
    } catch (e) {
      return false;
    }
  }

  // Solicitar recuperación de contraseña
  Future<bool> requestPasswordReset(String email) async {
    if (email.isEmpty) {
      _errorMessage = 'Ingresa tu email';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    clearErrorMessage();

    try {
      final response = await _authService.requestPasswordReset(email);

      if (response.isSuccess) {
        _setLoading(false);
        return true;
      } else {
        _errorMessage = response.error?.message ?? 'Error al solicitar recuperación';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error de conexión. Intenta nuevamente.';
      _setLoading(false);
      return false;
    }
  }

  // Métodos privados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _limpiarFormulario() {
    emailController.clear();
    passwordController.clear();
    nombreController.clear();
    telefonoController.clear();
    direccionController.clear();
    confirmPasswordController.clear();

    _recordarme = false;
    _aceptaTerminos = false;
    _obscurePassword = true;
    _obscureConfirmPassword = true;

    _clearAllErrors();
  }

  void _clearAllErrors() {
    _emailError = null;
    _passwordError = null;
    _nombreError = null;
    _telefonoError = null;
    _confirmPasswordError = null;
    _errorMessage = null;
  }

  // Validar todo el formulario de login
  bool validateLoginForm() {
    validateEmail();
    validatePassword();
    return isLoginFormValid;
  }

  // Validar todo el formulario de registro
  bool validateRegisterForm() {
    validateRegisterEmail();
    validateRegisterPassword();
    validateNombre();
    validateTelefono();
    validateConfirmPassword();
    return isRegisterFormValid;
  }

  // Limpiar formulario específico
  void clearLoginForm() {
    emailController.clear();
    passwordController.clear();
    _recordarme = false;
    _clearAllErrors();
    notifyListeners();
  }

  void clearRegisterForm() {
    emailController.clear();
    passwordController.clear();
    nombreController.clear();
    telefonoController.clear();
    direccionController.clear();
    confirmPasswordController.clear();
    _aceptaTerminos = false;
    _clearAllErrors();
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nombreController.dispose();
    telefonoController.dispose();
    direccionController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}