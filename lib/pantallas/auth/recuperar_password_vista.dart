import 'package:flutter/material.dart';
import '../../servicios/recuperacion_password_service.dart';
import '../../compartidos/widgets/message_helpers.dart';

class RecuperarPasswordVista extends StatefulWidget {
  const RecuperarPasswordVista({super.key});

  @override
  State<RecuperarPasswordVista> createState() => _RecuperarPasswordVistaState();
}

class _RecuperarPasswordVistaState extends State<RecuperarPasswordVista> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codigoController = TextEditingController();
  final _nuevaPasswordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();
  final _recuperacionService = RecuperacionPasswordService();

  bool _isLoading = false;
  int _pasoActual = 1; // 1: Email, 2: Código, 3: Nueva contraseña
  String? _telefonoOculto;
  bool _mostrarPassword = false;
  bool _mostrarConfirmarPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codigoController.dispose();
    _nuevaPasswordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verificarEmailYPasarPaso2() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Primero verificar si el email existe
    final resultado = await _recuperacionService.generarCodigoParaUsuario(
      _emailController.text.trim(),
    );

    if (resultado['success']) {
      setState(() {
        _pasoActual = 2;
        _telefonoOculto = resultado['telefonoOculto'] as String?;
      });

      if (mounted) {
        showAppMessage(
          context,
          'Usuario encontrado. Número registrado: $_telefonoOculto',
          type: MessageType.success,
        );
      }
    } else {
      if (mounted) {
        showAppMessage(
          context,
          resultado['message'] ?? 'Error al verificar email',
          type: MessageType.error,
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _enviarCodigoATelefono() async {
    setState(() => _isLoading = true);

    final resultado = await _recuperacionService.generarCodigoParaUsuario(
      _emailController.text.trim(),
    );

    if (resultado['success']) {
      // Enviar código por SMS
      final envioResultado = await _recuperacionService.enviarCodigoPorSMS(
        resultado['telefono'] as String,
        resultado['codigo'] as String,
      );

      if (mounted) {
        // Verificar si se debe mostrar el código al usuario
        final requiereMostrar = envioResultado['requiereMostrarCodigo'] as bool? ?? false;
        final codigo = envioResultado['codigo'] as String? ?? resultado['codigo'] as String;

        if (requiereMostrar) {
          // Mostrar código en diálogo (para Firebase con limitaciones o desarrollo)
          _mostrarDialogoCodigoEnConsola(codigo);
        } else if (envioResultado['success']) {
          // SMS enviado exitosamente por servicio externo
          showAppMessage(
            context,
            'Código enviado por SMS a tu número registrado: $_telefonoOculto',
            type: MessageType.success,
          );
        } else {
          // Error al enviar
          showAppMessage(
            context,
            envioResultado['message'] ?? 'Error al enviar código',
            type: MessageType.error,
          );
        }
      }
    } else {
      if (mounted) {
        showAppMessage(
          context,
          resultado['message'] ?? 'Error al enviar código',
          type: MessageType.error,
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _mostrarDialogoCodigoEnConsola(String codigo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Código Generado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tu código de verificación es:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: Center(
                child: Text(
                  codigo,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ingresa este código en el campo de verificación para continuar.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            const Text(
              'Nota: Firebase Phone Auth tiene limitaciones en Perú. Por seguridad, el código se muestra aquí pero también está guardado de forma segura en la base de datos.',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _verificarCodigo() async {
    if (_codigoController.text.trim().isEmpty) {
      showAppMessage(
        context,
        'Por favor ingresa el código',
        type: MessageType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    final resultado = await _recuperacionService.verificarCodigo(
      _emailController.text.trim(),
      _codigoController.text.trim(),
    );

    if (resultado['success']) {
      setState(() => _pasoActual = 3);

      if (mounted) {
        showAppMessage(
          context,
          'Código verificado. Ahora ingresa tu nueva contraseña',
          type: MessageType.success,
        );
      }
    } else {
      if (mounted) {
        showAppMessage(
          context,
          resultado['message'] ?? 'Código incorrecto',
          type: MessageType.error,
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _cambiarPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_nuevaPasswordController.text != _confirmarPasswordController.text) {
      showAppMessage(
        context,
        'Las contraseñas no coinciden',
        type: MessageType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    final resultado = await _recuperacionService.cambiarPassword(
      email: _emailController.text.trim(),
      codigo: _codigoController.text.trim(),
      nuevaPassword: _nuevaPasswordController.text,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (resultado['success']) {
        showAppMessage(
          context,
          'Nueva contraseña establecida. Ahora puedes iniciar sesión con ella.',
          type: MessageType.success,
        );

        // Esperar un momento y volver al login
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        showAppMessage(
          context,
          resultado['message'] ?? 'Error al cambiar contraseña',
          type: MessageType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _pasoActual == 3 ? Icons.lock_reset : Icons.phone_android,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Recuperar Contraseña',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _obtenerSubtitulo(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: _buildContenidoPaso(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _obtenerSubtitulo() {
    switch (_pasoActual) {
      case 1:
        return 'Paso 1 de 3: Ingresa tu email';
      case 2:
        return 'Paso 2 de 3: Verifica el código';
      case 3:
        return 'Paso 3 de 3: Nueva contraseña';
      default:
        return '';
    }
  }

  Widget _buildContenidoPaso() {
    switch (_pasoActual) {
      case 1:
        return _buildPaso1Email();
      case 2:
        return _buildPaso2Codigo();
      case 3:
        return _buildPaso3NuevaPassword();
      default:
        return const SizedBox();
    }
  }

  Widget _buildPaso1Email() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ingresa tu email',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Te enviaremos un código de validación a tu número de teléfono registrado.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Email requerido';
              if (!value!.contains('@')) return 'Email inválido';
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _verificarEmailYPasarPaso2,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Siguiente'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver al login'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaso2Codigo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Verificación de código',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Se enviará un código de 6 dígitos a tu número registrado:\n$_telefonoOculto',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Botón para enviar código al teléfono
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _enviarCodigoATelefono,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: const Icon(Icons.send),
          label: const Text('Enviar código al teléfono'),
        ),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        const Text(
          'Ingresa el código recibido',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Campo para ingresar el código
        TextFormField(
          controller: _codigoController,
          decoration: const InputDecoration(
            labelText: 'Código de validación',
            prefixIcon: Icon(Icons.pin),
            border: OutlineInputBorder(),
            hintText: '000000',
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Botón para verificar código
        ElevatedButton(
          onPressed: _isLoading ? null : _verificarCodigo,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Verificar código'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _pasoActual = 1),
          child: const Text('Cambiar email'),
        ),
      ],
    );
  }

  Widget _buildPaso3NuevaPassword() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Nueva contraseña',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Ingresa tu nueva contraseña',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nuevaPasswordController,
            decoration: InputDecoration(
              labelText: 'Nueva contraseña',
              prefixIcon: const Icon(Icons.lock),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _mostrarPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => _mostrarPassword = !_mostrarPassword);
                },
              ),
            ),
            obscureText: !_mostrarPassword,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Contraseña requerida';
              if (value!.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmarPasswordController,
            decoration: InputDecoration(
              labelText: 'Confirmar contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _mostrarConfirmarPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() =>
                      _mostrarConfirmarPassword = !_mostrarConfirmarPassword);
                },
              ),
            ),
            obscureText: !_mostrarConfirmarPassword,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Confirma tu contraseña';
              if (value != _nuevaPasswordController.text) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _cambiarPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Cambiar contraseña'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}
