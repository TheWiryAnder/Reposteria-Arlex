import 'package:flutter/material.dart';
import '../../servicios/notificaciones_service.dart';

class EnviarNotificacionesScreen extends StatefulWidget {
  const EnviarNotificacionesScreen({super.key});

  @override
  State<EnviarNotificacionesScreen> createState() =>
      _EnviarNotificacionesScreenState();
}

class _EnviarNotificacionesScreenState
    extends State<EnviarNotificacionesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _mensajeController = TextEditingController();
  String _tipoNotificacion = 'admin';
  bool _enviando = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enviar Notificaciones'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Título de la sección
                  const Text(
                    'Enviar Notificación Masiva',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Esta notificación se enviará a todos los usuarios registrados',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Card con el formulario
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Tipo de notificación
                          const Text(
                            'Tipo de Notificación',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _tipoNotificacion,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'admin',
                                child: Row(
                                  children: [
                                    Icon(Icons.notifications,
                                        color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('Notificación General'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'promocion',
                                child: Row(
                                  children: [
                                    Icon(Icons.local_offer,
                                        color: Colors.orange),
                                    SizedBox(width: 8),
                                    Text('Promoción'),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _tipoNotificacion = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 24),

                          // Campo de título
                          const Text(
                            'Título',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _tituloController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Ej: ¡Nueva Promoción!',
                              prefixIcon: Icon(Icons.title),
                            ),
                            maxLength: 50,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Por favor ingrese un título';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Campo de mensaje
                          const Text(
                            'Mensaje',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _mensajeController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText:
                                  'Ej: Descuento del 20% en todos nuestros productos esta semana',
                              prefixIcon: Icon(Icons.message),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 4,
                            maxLength: 200,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Por favor ingrese un mensaje';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Botón de enviar
                          ElevatedButton.icon(
                            onPressed: _enviando ? null : _enviarNotificacion,
                            icon: _enviando
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send),
                            label: Text(
                              _enviando
                                  ? 'Enviando...'
                                  : 'Enviar a Todos los Usuarios',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Información adicional
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Las notificaciones aparecerán en la bandeja de cada usuario y recibirán una notificación en tiempo real.',
                              style: TextStyle(
                                color: Colors.blue.shade900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Future<void> _enviarNotificacion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Confirmar con el usuario
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Envío'),
        content: const Text(
          '¿Estás seguro de que deseas enviar esta notificación a todos los usuarios registrados?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      _enviando = true;
    });

    try {
      final notificacionesService = NotificacionesService();

      await notificacionesService.crearNotificacionMasiva(
        titulo: _tituloController.text.trim(),
        mensaje: _mensajeController.text.trim(),
        tipo: _tipoNotificacion,
      );

      if (!mounted) return;

      // Limpiar formulario
      _tituloController.clear();
      _mensajeController.clear();
      setState(() {
        _tipoNotificacion = 'admin';
      });

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notificación enviada exitosamente a todos los usuarios'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar notificación: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }
}
