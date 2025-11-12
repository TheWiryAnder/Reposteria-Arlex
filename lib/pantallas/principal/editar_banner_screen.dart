import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import '../../modelos/informacion_negocio_modelo.dart';
import '../../compartidos/widgets/message_helpers.dart';

class EditarBannerScreen extends StatefulWidget {
  const EditarBannerScreen({super.key});

  @override
  State<EditarBannerScreen> createState() => _EditarBannerScreenState();
}

class _EditarBannerScreenState extends State<EditarBannerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _subtituloController;
  late TextEditingController _imagenUrlController;
  late TextEditingController _alturaController;
  late bool _activo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final info = InformacionNegocioProvider.instance.info;
    final banner = info.bannerPrincipal;

    _tituloController = TextEditingController(text: banner.titulo);
    _subtituloController = TextEditingController(text: banner.subtitulo);
    _imagenUrlController = TextEditingController(text: banner.imagenUrl ?? '');
    _alturaController = TextEditingController(text: banner.altura.toString());
    _activo = banner.activo;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _subtituloController.dispose();
    _imagenUrlController.dispose();
    _alturaController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = InformacionNegocioProvider.instance;
      final infoActual = provider.info;

      // Crear nuevo banner con los cambios
      final nuevoBanner = BannerPrincipal(
        titulo: _tituloController.text.trim(),
        subtitulo: _subtituloController.text.trim(),
        imagenUrl: _imagenUrlController.text.trim().isEmpty
            ? null
            : _imagenUrlController.text.trim(),
        altura: double.tryParse(_alturaController.text) ?? 200,
        activo: _activo,
      );

      // Actualizar la información completa con el nuevo banner
      final nuevaInfo = infoActual.copyWith(
        bannerPrincipal: nuevoBanner,
      );

      await provider.actualizarInformacion(nuevaInfo);

      if (mounted) {
        Navigator.pop(context);
        showAppMessage(
          context,
          'Banner actualizado exitosamente',
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
        title: const Text('Editar Banner Principal'),
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
                // Vista previa del banner
                _buildPreview(),
                const SizedBox(height: 32),

                // Título
                TextFormField(
                  controller: _tituloController,
                  decoration: const InputDecoration(
                    labelText: 'Título del Banner',
                    hintText: 'Ej: Bienvenido a Repostería Arlex',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 50,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El título es obligatorio';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // Subtítulo
                TextFormField(
                  controller: _subtituloController,
                  decoration: const InputDecoration(
                    labelText: 'Subtítulo',
                    hintText: 'Ej: Descubre nuestros productos artesanales',
                    prefixIcon: Icon(Icons.subtitles),
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 100,
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El subtítulo es obligatorio';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // URL de imagen
                TextFormField(
                  controller: _imagenUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL de la Imagen de Fondo (opcional)',
                    hintText: 'https://ejemplo.com/imagen.jpg',
                    prefixIcon: Icon(Icons.image),
                    border: OutlineInputBorder(),
                    helperText: 'Si no se proporciona, se usará un gradiente de color',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // Altura del banner
                TextFormField(
                  controller: _alturaController,
                  decoration: const InputDecoration(
                    labelText: 'Altura del Banner (píxeles)',
                    hintText: '200',
                    prefixIcon: Icon(Icons.height),
                    border: OutlineInputBorder(),
                    helperText: 'Altura recomendada: entre 150 y 400 píxeles',
                    suffixText: 'px',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La altura es obligatoria';
                    }
                    final altura = double.tryParse(value);
                    if (altura == null || altura < 100 || altura > 600) {
                      return 'La altura debe estar entre 100 y 600 píxeles';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),

                // Switch para activar/desactivar
                SwitchListTile(
                  title: const Text('Banner Activo'),
                  subtitle: const Text(
                    'Mostrar u ocultar el banner en la pantalla de inicio',
                  ),
                  value: _activo,
                  onChanged: (value) => setState(() => _activo = value),
                  secondary: Icon(
                    _activo ? Icons.visibility : Icons.visibility_off,
                    color: _activo ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),

                // Información adicional
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Consejos para el banner',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• El banner se adapta automáticamente a diferentes tamaños de pantalla\n'
                          '• Para mejor legibilidad, usa imágenes con buena iluminación\n'
                          '• El texto siempre se muestra sobre un degradado oscuro\n'
                          '• Altura recomendada en móvil: 200px, en desktop: 300-400px',
                          style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
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

  Widget _buildPreview() {
    final altura = double.tryParse(_alturaController.text) ?? 200;
    final titulo = _tituloController.text.isEmpty
        ? 'Título del Banner'
        : _tituloController.text;
    final subtitulo = _subtituloController.text.isEmpty
        ? 'Subtítulo del banner'
        : _subtituloController.text;
    final imagenUrl = _imagenUrlController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vista Previa',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          height: altura.clamp(100, 400),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Imagen de fondo o gradiente
                if (imagenUrl.isNotEmpty)
                  Positioned.fill(
                    child: Image.network(
                      imagenUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.broken_image, size: 48, color: Colors.white70),
                                SizedBox(height: 8),
                                Text(
                                  'Error al cargar imagen',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Overlay oscuro
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                // Texto
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitulo,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                // Indicador de desactivado
                if (!_activo)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility_off, size: 48, color: Colors.white),
                            SizedBox(height: 8),
                            Text(
                              'BANNER DESACTIVADO',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
