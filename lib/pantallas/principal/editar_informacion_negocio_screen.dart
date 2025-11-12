import 'package:flutter/material.dart';
import '../../main.dart';
import '../../compartidos/widgets/message_helpers.dart';

/// Pantalla simplificada para editar información básica del negocio
/// NOTA: Esta es una versión simplificada. Para editar el banner,
/// usa el botón "Editar Banner" en la pantalla principal.
class EditarInformacionNegocioScreen extends StatefulWidget {
  const EditarInformacionNegocioScreen({super.key});

  @override
  State<EditarInformacionNegocioScreen> createState() =>
      _EditarInformacionNegocioScreenState();
}

class _EditarInformacionNegocioScreenState
    extends State<EditarInformacionNegocioScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _direccionController;
  late TextEditingController _emailController;
  late TextEditingController _whatsappController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final info = InformacionNegocioProvider.instance.info;
    _direccionController = TextEditingController(text: info.direccion);
    _emailController = TextEditingController(text: info.email);
    _whatsappController = TextEditingController(text: info.whatsapp);
  }

  @override
  void dispose() {
    _direccionController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = InformacionNegocioProvider.instance;
      final infoActual = provider.info;

      // Actualizar solo los campos básicos
      final nuevaInfo = infoActual.copyWith(
        direccion: _direccionController.text.trim(),
        email: _emailController.text.trim(),
        whatsapp: _whatsappController.text.trim(),
      );

      await provider.actualizarInformacion(nuevaInfo);

      if (mounted) {
        Navigator.pop(context);
        showAppMessage(
          context,
          'Información actualizada exitosamente',
          type: MessageType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppMessage(
          context,
          'Error al guardar: $e',
          type: MessageType.error,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración del Negocio'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Mensaje informativo
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Esta es una configuración básica. Para editar el banner, '
                            'usa el botón "Editar Banner" en la pantalla principal.',
                            style: TextStyle(color: Colors.blue.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Dirección
                TextFormField(
                  controller: _direccionController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    hintText: 'Calle 123, Ciudad',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La dirección es obligatoria';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'contacto@negocio.com',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El email es obligatorio';
                    }
                    if (!value.contains('@')) {
                      return 'Ingresa un email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // WhatsApp
                TextFormField(
                  controller: _whatsappController,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp',
                    hintText: '+51 999 999 999',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El WhatsApp es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _guardarCambios,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isLoading ? 'Guardando...' : 'Guardar Cambios'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
