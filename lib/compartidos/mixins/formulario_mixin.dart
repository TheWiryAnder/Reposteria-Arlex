import 'package:flutter/material.dart';

mixin FormularioMixin<T extends StatefulWidget> on State<T> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final Map<String, String> errores = {};
  bool isLoading = false;

  bool validarFormulario() {
    final form = formKey.currentState;
    if (form == null) return false;

    // Limpiar errores previos
    setState(() {
      errores.clear();
    });

    final isValid = form.validate();

    // Validaciones adicionales personalizadas
    final customValidations = validacionesPersonalizadas();
    errores.addAll(customValidations);

    if (errores.isNotEmpty) {
      setState(() {});
      return false;
    }

    return isValid;
  }

  Map<String, String> validacionesPersonalizadas() {
    // Override en las clases que usen este mixin para validaciones específicas
    return {};
  }

  void limpiarErrores() {
    setState(() {
      errores.clear();
    });
  }

  void agregarError(String campo, String mensaje) {
    setState(() {
      errores[campo] = mensaje;
    });
  }

  String? obtenerError(String campo) {
    return errores[campo];
  }

  void setLoading(bool loading) {
    setState(() {
      isLoading = loading;
    });
  }

  Future<void> enviarFormulario() async {
    if (!validarFormulario()) return;

    setLoading(true);
    try {
      await procesarFormulario();
      onFormularioExitoso();
    } catch (error) {
      onFormularioError(error);
    } finally {
      setLoading(false);
    }
  }

  // Métodos abstractos que deben ser implementados
  Future<void> procesarFormulario();
  void onFormularioExitoso();
  void onFormularioError(dynamic error);

  // Validadores comunes reutilizables
  String? validarEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un email válido';
    }

    return null;
  }

  String? validarPassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < minLength) {
      return 'La contraseña debe tener al menos $minLength caracteres';
    }

    return null;
  }

  String? validarTelefono(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es requerido';
    }

    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
      return 'Ingresa un teléfono válido';
    }

    return null;
  }

  String? validarRequerido(String? value, String campo) {
    if (value == null || value.trim().isEmpty) {
      return '$campo es requerido';
    }
    return null;
  }

  String? validarNumero(String? value, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return 'Este campo es requerido';
    }

    final numero = double.tryParse(value);
    if (numero == null) {
      return 'Ingresa un número válido';
    }

    if (min != null && numero < min) {
      return 'El valor debe ser mayor o igual a $min';
    }

    if (max != null && numero > max) {
      return 'El valor debe ser menor o igual a $max';
    }

    return null;
  }

  String? validarConfirmarPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }

    if (value != password) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }
}