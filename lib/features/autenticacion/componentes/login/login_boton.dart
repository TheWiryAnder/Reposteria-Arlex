import 'package:flutter/material.dart';
import '../../controladores/auth_controlador.dart';

class LoginBoton extends StatelessWidget {
  final AuthControlador controller;
  final bool isRegisterMode;
  final VoidCallback onPressed;

  const LoginBoton({
    super.key,
    required this.controller,
    required this.isRegisterMode,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final isFormValid = isRegisterMode
            ? controller.isRegisterFormValid
            : controller.isLoginFormValid;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Botón principal
            ElevatedButton(
              onPressed: (controller.isLoading || !isFormValid) ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: controller.isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor.withOpacity(0.7),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isRegisterMode ? 'Creando cuenta...' : 'Iniciando sesión...',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      isRegisterMode ? 'Crear Cuenta' : 'Iniciar Sesión',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),

            // Indicador de validación del formulario
            if (!isFormValid && !controller.isLoading) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getValidationMessage(),
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Botones de redes sociales (para futuras implementaciones)
            const SizedBox(height: 20),
            _buildSocialButtons(context),
          ],
        );
      },
    );
  }

  String _getValidationMessage() {
    if (isRegisterMode) {
      if (controller.emailController.text.isEmpty) {
        return 'Ingresa tu email';
      }
      if (controller.nombreController.text.isEmpty) {
        return 'Ingresa tu nombre completo';
      }
      if (controller.passwordController.text.isEmpty) {
        return 'Ingresa una contraseña';
      }
      if (controller.confirmPasswordController.text.isEmpty) {
        return 'Confirma tu contraseña';
      }
      if (!controller.aceptaTerminos) {
        return 'Debes aceptar los términos y condiciones';
      }
      return 'Completa todos los campos correctamente';
    } else {
      if (controller.emailController.text.isEmpty) {
        return 'Ingresa tu email';
      }
      if (controller.passwordController.text.isEmpty) {
        return 'Ingresa tu contraseña';
      }
      return 'Completa todos los campos correctamente';
    }
  }

  Widget _buildSocialButtons(BuildContext context) {
    return Column(
      children: [
        // Divider con texto "O"
        Row(
          children: [
            Expanded(
              child: Divider(
                thickness: 1,
                color: Colors.grey[300],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'O',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                thickness: 1,
                color: Colors.grey[300],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Botones de redes sociales
        Row(
          children: [
            // Botón de Google
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.isLoading ? null : () => _handleSocialLogin('google'),
                icon: const Icon(Icons.g_mobiledata, color: Colors.red),
                label: const Text('Google'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Botón de Facebook
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.isLoading ? null : () => _handleSocialLogin('facebook'),
                icon: const Icon(
                  Icons.facebook,
                  color: Color(0xFF1877F2),
                ),
                label: const Text('Facebook'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Nota sobre redes sociales
        Text(
          'Las opciones de redes sociales estarán disponibles próximamente',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _handleSocialLogin(String provider) {
    // TODO: Implementar login con redes sociales
    debugPrint('Login con $provider - Próximamente disponible');
  }
}