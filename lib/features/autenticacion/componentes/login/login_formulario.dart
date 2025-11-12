import 'package:flutter/material.dart';
import '../../controladores/auth_controlador.dart';
import 'login_boton.dart';

class LoginFormulario extends StatefulWidget {
  final AuthControlador controller;
  final bool isRegisterMode;
  final VoidCallback onSuccess;

  const LoginFormulario({
    super.key,
    required this.controller,
    required this.isRegisterMode,
    required this.onSuccess,
  });

  @override
  State<LoginFormulario> createState() => _LoginFormularioState();
}

class _LoginFormularioState extends State<LoginFormulario> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Título del formulario
                Text(
                  widget.isRegisterMode ? 'Crear Cuenta' : 'Iniciar Sesión',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                // Campo de nombre (solo para registro)
                if (widget.isRegisterMode) ...[
                  _buildNombreField(),
                  const SizedBox(height: 20),
                ],

                // Campo de email
                _buildEmailField(),
                const SizedBox(height: 20),

                // Campo de teléfono (solo para registro)
                if (widget.isRegisterMode) ...[
                  _buildTelefonoField(),
                  const SizedBox(height: 20),
                ],

                // Campo de contraseña
                _buildPasswordField(),
                const SizedBox(height: 20),

                // Campo de confirmar contraseña (solo para registro)
                if (widget.isRegisterMode) ...[
                  _buildConfirmPasswordField(),
                  const SizedBox(height: 20),
                ],

                // Checkbox "Recordarme" (solo para login)
                if (!widget.isRegisterMode) ...[
                  _buildRecordarmeCheckbox(),
                  const SizedBox(height: 20),
                ],

                // Checkbox "Acepto términos" (solo para registro)
                if (widget.isRegisterMode) ...[
                  _buildTerminosCheckbox(),
                  const SizedBox(height: 20),
                ],

                // Mensaje de error general
                if (widget.controller.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.controller.errorMessage!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: widget.controller.clearErrorMessage,
                          iconSize: 16,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Botón de acción principal
                LoginBoton(
                  controller: widget.controller,
                  isRegisterMode: widget.isRegisterMode,
                  onPressed: () => _handleSubmit(),
                ),

                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: widget.controller.emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'ejemplo@email.com',
        prefixIcon: const Icon(Icons.email_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        errorText: widget.controller.emailError,
      ),
      onChanged: (_) {
        if (widget.isRegisterMode) {
          widget.controller.validateRegisterEmail();
        } else {
          widget.controller.validateEmail();
        }
      },
      validator: (value) {
        final result = widget.isRegisterMode
            ? widget.controller.emailError
            : widget.controller.emailError;
        return result;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: widget.controller.passwordController,
      obscureText: widget.controller.obscurePassword,
      decoration: InputDecoration(
        labelText: 'Contraseña',
        hintText: widget.isRegisterMode ? 'Mínimo 8 caracteres' : 'Tu contraseña',
        prefixIcon: const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(
            widget.controller.obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: widget.controller.togglePasswordVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        errorText: widget.controller.passwordError,
      ),
      onChanged: (_) {
        if (widget.isRegisterMode) {
          widget.controller.validateRegisterPassword();
        } else {
          widget.controller.validatePassword();
        }
      },
      validator: (value) => widget.controller.passwordError,
    );
  }

  Widget _buildNombreField() {
    return TextFormField(
      controller: widget.controller.nombreController,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: 'Nombre Completo',
        hintText: 'Tu nombre completo',
        prefixIcon: const Icon(Icons.person_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        errorText: widget.controller.nombreError,
      ),
      onChanged: (_) => widget.controller.validateNombre(),
      validator: (value) => widget.controller.nombreError,
    );
  }

  Widget _buildTelefonoField() {
    return TextFormField(
      controller: widget.controller.telefonoController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: 'Teléfono (Opcional)',
        hintText: '+57 300 123 4567',
        prefixIcon: const Icon(Icons.phone_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        errorText: widget.controller.telefonoError,
      ),
      onChanged: (_) => widget.controller.validateTelefono(),
      validator: (value) => widget.controller.telefonoError,
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: widget.controller.confirmPasswordController,
      obscureText: widget.controller.obscureConfirmPassword,
      decoration: InputDecoration(
        labelText: 'Confirmar Contraseña',
        hintText: 'Repite tu contraseña',
        prefixIcon: const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(
            widget.controller.obscureConfirmPassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: widget.controller.toggleConfirmPasswordVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        errorText: widget.controller.confirmPasswordError,
      ),
      onChanged: (_) => widget.controller.validateConfirmPassword(),
      validator: (value) => widget.controller.confirmPasswordError,
    );
  }

  Widget _buildRecordarmeCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: widget.controller.recordarme,
          onChanged: (value) => widget.controller.setRecordarme(value ?? false),
        ),
        const Expanded(
          child: Text('Recordarme en este dispositivo'),
        ),
      ],
    );
  }

  Widget _buildTerminosCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: widget.controller.aceptaTerminos,
          onChanged: (value) => widget.controller.setAceptaTerminos(value ?? false),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => widget.controller.setAceptaTerminos(!widget.controller.aceptaTerminos),
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  const TextSpan(text: 'Acepto los '),
                  TextSpan(
                    text: 'Términos y Condiciones',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' y la '),
                  TextSpan(
                    text: 'Política de Privacidad',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    bool success;

    if (widget.isRegisterMode) {
      if (!widget.controller.validateRegisterForm()) return;
      success = await widget.controller.register();
    } else {
      if (!widget.controller.validateLoginForm()) return;
      success = await widget.controller.login();
    }

    if (success && mounted) {
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isRegisterMode
              ? '¡Cuenta creada exitosamente!'
              : '¡Inicio de sesión exitoso!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Llamar al callback de éxito
      widget.onSuccess();
    }
  }
}