import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';
import '../../modelos/informacion_negocio_modelo.dart';
import '../../servicios/informacion_negocio_service.dart';
import '../../compartidos/widgets/message_helpers.dart';

class ConfiguracionNegocioCompletaScreen extends StatefulWidget {
  const ConfiguracionNegocioCompletaScreen({super.key});

  @override
  State<ConfiguracionNegocioCompletaScreen> createState() =>
      _ConfiguracionNegocioCompletaScreenState();
}

class _ConfiguracionNegocioCompletaScreenState
    extends State<ConfiguracionNegocioCompletaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Controladores para Información General
  late TextEditingController _nombreController;
  late TextEditingController _logoController;
  late TextEditingController _logoSecundarioController;
  late TextEditingController _sloganController;

  // Controladores para Historia, Misión y Visión
  late TextEditingController _historiaController;
  late TextEditingController _historiaImagenController;
  late TextEditingController _misionController;
  late TextEditingController _misionImagenController;
  late TextEditingController _visionController;
  late TextEditingController _visionImagenController;

  // Controladores para Contacto
  late TextEditingController _direccionController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  late TextEditingController _whatsappController;
  late TextEditingController _ubicacionMapsController;

  // Controladores para Horarios
  late TextEditingController _lunesViernesController;
  late TextEditingController _sabadoController;
  late TextEditingController _domingoController;

  // Controladores para Redes Sociales
  late TextEditingController _facebookController;
  late TextEditingController _instagramController;
  late TextEditingController _tiktokController;
  late TextEditingController _twitterController;
  late TextEditingController _youtubeController;

  // Controladores para Métodos de Pago
  late TextEditingController _yapeQRController;
  late TextEditingController _plinQRController;

  // Lista de valores
  List<String> _valores = [];
  final _valorController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);

    final info = InformacionNegocioProvider.instance.info;

    // Información General
    _nombreController = TextEditingController(text: info.galeria.nombre);
    _logoController = TextEditingController(text: info.galeria.logo);
    _logoSecundarioController = TextEditingController(text: info.galeria.logoSecundario);
    _sloganController = TextEditingController(text: info.redesSociales.slogan);

    // Historia, Misión y Visión
    _historiaController = TextEditingController(text: info.galeria.historia);
    _historiaImagenController = TextEditingController(text: info.galeria.historiaImagenUrl ?? '');
    _misionController = TextEditingController(text: info.galeria.mision);
    _misionImagenController = TextEditingController(text: info.galeria.misionImagenUrl ?? '');
    _visionController = TextEditingController(text: info.galeria.vision);
    _visionImagenController = TextEditingController(text: info.galeria.visionImagenUrl ?? '');

    // Contacto
    _direccionController = TextEditingController(text: info.direccion);
    _emailController = TextEditingController(text: info.email);
    _telefonoController = TextEditingController(text: info.redesSociales.telefono);
    _whatsappController = TextEditingController(text: info.whatsapp);
    _ubicacionMapsController = TextEditingController(text: info.ubicacionMapsUrl ?? '');

    // Horarios
    _lunesViernesController = TextEditingController(text: info.galeria.horarioAtencion.lunesViernes);
    _sabadoController = TextEditingController(text: info.galeria.horarioAtencion.sabado);
    _domingoController = TextEditingController(text: info.galeria.horarioAtencion.domingo);

    // Redes Sociales
    _facebookController = TextEditingController(text: info.redesSociales.facebook);
    _instagramController = TextEditingController(text: info.redesSociales.instagram);
    _tiktokController = TextEditingController(text: info.redesSociales.tiktok);
    _twitterController = TextEditingController(text: info.redesSociales.twitter);
    _youtubeController = TextEditingController(text: info.redesSociales.youtube);

    // Métodos de Pago - Inicializar vacíos, se cargarán desde Firebase
    _yapeQRController = TextEditingController();
    _plinQRController = TextEditingController();

    // Valores
    _valores = List.from(info.galeria.valores);

    // Cargar métodos de pago
    _cargarMetodosPago();
  }

  Future<void> _cargarMetodosPago() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('configuracion')
          .doc('metodosPago')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          _yapeQRController.text = data['yapeQR'] as String? ?? '';
          _plinQRController.text = data['plinQR'] as String? ?? '';
        }
      }
    } catch (e) {
      // Error silencioso, los campos quedarán vacíos
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nombreController.dispose();
    _logoController.dispose();
    _logoSecundarioController.dispose();
    _sloganController.dispose();
    _historiaController.dispose();
    _historiaImagenController.dispose();
    _misionController.dispose();
    _misionImagenController.dispose();
    _visionController.dispose();
    _visionImagenController.dispose();
    _direccionController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _whatsappController.dispose();
    _ubicacionMapsController.dispose();
    _lunesViernesController.dispose();
    _sabadoController.dispose();
    _domingoController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _twitterController.dispose();
    _youtubeController.dispose();
    _valorController.dispose();
    _yapeQRController.dispose();
    _plinQRController.dispose();
    super.dispose();
  }

  /// Limpiar URLs problemáticas que causan errores CORS
  Future<void> _limpiarURLsProblematicas() async {
    // Mostrar confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar URLs Problemáticas'),
        content: const Text(
          'Esta acción eliminará todas las URLs de imágenes externas que causan errores CORS '
          '(como senamhi.gob.pe y cloudfront.net).\n\n'
          'Las imágenes serán removidas pero podrás agregar nuevas URLs válidas después.\n\n'
          '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Limpiar URLs'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);

    try {
      final provider = InformacionNegocioProvider.instance;
      final service = InformacionNegocioService();

      // Ejecutar limpieza
      final resultado = await service.limpiarImagenesProblematicas(
        actualizadoPor: 'admin', // TODO: Obtener usuario actual
      );

      if (!mounted) return;

      if (resultado['success'] == true) {
        final urlsLimpiadas = resultado['urlsLimpiadas'] ?? 0;

        // Recargar información
        await provider.recargar();

        // Actualizar controladores con nueva información
        final info = provider.info;
        _historiaImagenController.text = info.galeria.historiaImagenUrl ?? '';
        _misionImagenController.text = info.galeria.misionImagenUrl ?? '';
        _visionImagenController.text = info.galeria.visionImagenUrl ?? '';
        _logoController.text = info.galeria.logo;
        _logoSecundarioController.text = info.galeria.logoSecundario;

        if (mounted) {
          showAppMessage(
            context,
            urlsLimpiadas > 0
                ? 'Se limpiaron $urlsLimpiadas URLs problemáticas'
                : 'No se encontraron URLs problemáticas',
            type: urlsLimpiadas > 0 ? MessageType.success : MessageType.info,
          );
        }
      } else {
        if (mounted) {
          showAppMessage(
            context,
            resultado['message'] ?? 'Error al limpiar URLs',
            type: MessageType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showAppMessage(
          context,
          'Error al limpiar URLs: $e',
          type: MessageType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      showAppMessage(context, 'Por favor completa todos los campos requeridos', type: MessageType.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = InformacionNegocioProvider.instance;
      final infoActual = provider.info;

      // Crear nuevos objetos con los datos actualizados
      final nuevaGaleria = infoActual.galeria.copyWith(
        nombre: _nombreController.text.trim(),
        logo: _logoController.text.trim(),
        logoSecundario: _logoSecundarioController.text.trim(),
        historia: _historiaController.text.trim(),
        historiaImagenUrl: _historiaImagenController.text.trim().isEmpty ? null : _historiaImagenController.text.trim(),
        mision: _misionController.text.trim(),
        misionImagenUrl: _misionImagenController.text.trim().isEmpty ? null : _misionImagenController.text.trim(),
        vision: _visionController.text.trim(),
        visionImagenUrl: _visionImagenController.text.trim().isEmpty ? null : _visionImagenController.text.trim(),
        valores: _valores,
        horarioAtencion: HorarioAtencion(
          lunesViernes: _lunesViernesController.text.trim(),
          sabado: _sabadoController.text.trim(),
          domingo: _domingoController.text.trim(),
        ),
      );

      final nuevasRedesSociales = infoActual.redesSociales.copyWith(
        slogan: _sloganController.text.trim(),
        telefono: _telefonoController.text.trim(),
        facebook: _facebookController.text.trim(),
        instagram: _instagramController.text.trim(),
        tiktok: _tiktokController.text.trim(),
        twitter: _twitterController.text.trim(),
        youtube: _youtubeController.text.trim(),
      );

      // Actualizar información completa
      final nuevaInfo = infoActual.copyWith(
        galeria: nuevaGaleria,
        redesSociales: nuevasRedesSociales,
        direccion: _direccionController.text.trim(),
        email: _emailController.text.trim(),
        whatsapp: _whatsappController.text.trim(),
        ubicacionMapsUrl: _ubicacionMapsController.text.trim().isEmpty ? null : _ubicacionMapsController.text.trim(),
      );

      await provider.actualizarInformacion(nuevaInfo);

      // Guardar métodos de pago en Firebase
      await FirebaseFirestore.instance
          .collection('configuracion')
          .doc('metodosPago')
          .set({
        'yapeQR': _yapeQRController.text.trim(),
        'plinQR': _plinQRController.text.trim(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context);
        showAppMessage(
          context,
          'Configuración guardada exitosamente',
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
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.business, size: 20), text: 'General'),
            Tab(icon: Icon(Icons.description, size: 20), text: 'Historia'),
            Tab(icon: Icon(Icons.contact_mail, size: 20), text: 'Contacto'),
            Tab(icon: Icon(Icons.schedule, size: 20), text: 'Horarios'),
            Tab(icon: Icon(Icons.share, size: 20), text: 'Redes Sociales'),
            Tab(icon: Icon(Icons.payment, size: 20), text: 'Métodos de Pago'),
          ],
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.cleaning_services),
              onPressed: _limpiarURLsProblematicas,
              tooltip: 'Limpiar URLs problemáticas',
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _guardarCambios,
              tooltip: 'Guardar cambios',
            ),
          ],
        ],
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildGeneralTab(),
            _buildHistoriaTab(),
            _buildContactoTab(),
            _buildHorariosTab(),
            _buildRedesSocialesTab(),
            _buildMetodosPagoTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _guardarCambios,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'Guardando...' : 'Guardar Todos los Cambios'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralTab() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Información General',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Nombre del Negocio
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Negocio *',
                hintText: 'Ej: Repostería Arlex',
                prefixIcon: Icon(Icons.store),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.trim().isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),

            // Slogan
            TextFormField(
              controller: _sloganController,
              decoration: const InputDecoration(
                labelText: 'Slogan',
                hintText: 'Ej: Endulzando tus momentos especiales',
                prefixIcon: Icon(Icons.format_quote),
                border: OutlineInputBorder(),
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 16),

            // Logo Principal
            TextFormField(
              controller: _logoController,
              decoration: const InputDecoration(
                labelText: 'URL del Logo Principal *',
                hintText: 'https://ejemplo.com/logo.png',
                prefixIcon: Icon(Icons.image),
                border: OutlineInputBorder(),
                helperText: 'URL de la imagen del logo principal',
              ),
              keyboardType: TextInputType.url,
              validator: (value) => value?.trim().isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 8),
            if (_logoController.text.isNotEmpty)
              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Image.network(
                    _logoController.text,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 48, color: Colors.grey),
                          Text('Error al cargar imagen', style: TextStyle(color: Colors.grey)),
                        ],
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Logo Secundario
            TextFormField(
              controller: _logoSecundarioController,
              decoration: const InputDecoration(
                labelText: 'URL del Logo Secundario (opcional)',
                hintText: 'https://ejemplo.com/logo-secundario.png',
                prefixIcon: Icon(Icons.image_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),

            // Valores de la empresa
            const Text(
              'Valores de la Empresa',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._valores.asMap().entries.map((entry) {
              final index = entry.key;
              final valor = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(valor),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _valores.removeAt(index);
                      });
                    },
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _valorController,
                    decoration: const InputDecoration(
                      labelText: 'Agregar valor',
                      hintText: 'Ej: Calidad, Innovación, Compromiso',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_valorController.text.trim().isNotEmpty) {
                      setState(() {
                        _valores.add(_valorController.text.trim());
                        _valorController.clear();
                      });
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoriaTab() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Historia, Misión y Visión',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Historia
            const Row(
              children: [
                Icon(Icons.history, color: Colors.orange),
                SizedBox(width: 8),
                Text('Historia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _historiaController,
              decoration: const InputDecoration(
                hintText: 'Cuéntanos la historia de tu negocio...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              validator: (value) => value?.trim().isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _historiaImagenController,
              decoration: const InputDecoration(
                labelText: 'URL de Imagen para Historia (opcional)',
                hintText: 'https://ejemplo.com/historia.jpg',
                prefixIcon: Icon(Icons.image),
                border: OutlineInputBorder(),
                helperText: 'Imagen que acompañará la historia del negocio',
              ),
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}),
            ),
            if (_historiaImagenController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _historiaImagenController.text,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Error al cargar imagen', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      },
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Misión
            const Row(
              children: [
                Icon(Icons.flag, color: Colors.blue),
                SizedBox(width: 8),
                Text('Misión', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _misionController,
              decoration: const InputDecoration(
                hintText: '¿Cuál es el propósito de tu negocio?',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) => value?.trim().isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _misionImagenController,
              decoration: const InputDecoration(
                labelText: 'URL de Imagen para Misión (opcional)',
                hintText: 'https://ejemplo.com/mision.jpg',
                prefixIcon: Icon(Icons.image),
                border: OutlineInputBorder(),
                helperText: 'Imagen que acompañará la misión del negocio',
              ),
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}),
            ),
            if (_misionImagenController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _misionImagenController.text,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Error al cargar imagen', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      },
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Visión
            const Row(
              children: [
                Icon(Icons.visibility, color: Colors.green),
                SizedBox(width: 8),
                Text('Visión', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _visionController,
              decoration: const InputDecoration(
                hintText: '¿Hacia dónde se dirige tu negocio?',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) => value?.trim().isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _visionImagenController,
              decoration: const InputDecoration(
                labelText: 'URL de Imagen para Visión (opcional)',
                hintText: 'https://ejemplo.com/vision.jpg',
                prefixIcon: Icon(Icons.image),
                border: OutlineInputBorder(),
                helperText: 'Imagen que acompañará la visión del negocio',
              ),
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}),
            ),
            if (_visionImagenController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _visionImagenController.text,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Error al cargar imagen', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactoTab() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Información de Contacto',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Dirección
            TextFormField(
              controller: _direccionController,
              decoration: const InputDecoration(
                labelText: 'Dirección *',
                hintText: 'Calle 123 #45-67, Ciudad',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) => value?.trim().isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                hintText: 'contacto@negocio.com',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.trim().isEmpty ?? true) return 'Campo requerido';
                if (!value!.contains('@')) return 'Email inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Teléfono
            TextFormField(
              controller: _telefonoController,
              decoration: const InputDecoration(
                labelText: 'Teléfono *',
                hintText: '+51 999 999 999',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) => value?.trim().isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),

            // WhatsApp
            TextFormField(
              controller: _whatsappController,
              decoration: const InputDecoration(
                labelText: 'WhatsApp *',
                hintText: '+51 999 999 999',
                prefixIcon: Icon(Icons.chat),
                border: OutlineInputBorder(),
                helperText: 'Incluye el código de país (ej: +51)',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) => value?.trim().isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),

            // Código HTML de Google Maps
            TextFormField(
              controller: _ubicacionMapsController,
              decoration: const InputDecoration(
                labelText: 'Código HTML de Google Maps (opcional)',
                hintText: '<iframe src="https://www.google.com/maps/embed?pb=..." width="600" height="450" ...></iframe>',
                prefixIcon: Icon(Icons.map),
                border: OutlineInputBorder(),
                helperText: 'Pega aquí el código HTML del iframe de Google Maps. Obtén el código desde Google Maps > Compartir > Insertar mapa.',
              ),
              keyboardType: TextInputType.multiline,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
            ),
            if (_ubicacionMapsController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'El mapa se mostrará en la sección "Acerca de Nosotros" de forma interactiva.',
                                style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Código HTML detectado',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'El mapa será insertado en la página web usando el código HTML proporcionado.',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildHorariosTab() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Horarios de Atención',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Lunes a Viernes
            TextFormField(
              controller: _lunesViernesController,
              decoration: const InputDecoration(
                labelText: 'Lunes a Viernes *',
                hintText: 'Ej: 8:00 AM - 6:00 PM',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.trim().isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),

            // Sábado
            TextFormField(
              controller: _sabadoController,
              decoration: const InputDecoration(
                labelText: 'Sábado *',
                hintText: 'Ej: 9:00 AM - 2:00 PM',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.trim().isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),

            // Domingo
            TextFormField(
              controller: _domingoController,
              decoration: const InputDecoration(
                labelText: 'Domingo *',
                hintText: 'Ej: Cerrado',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.trim().isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),

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
                        'Los horarios se mostrarán en la sección "Acerca de Nosotros" y en la información de contacto.',
                        style: TextStyle(color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedesSocialesTab() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Redes Sociales',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ingresa las URLs completas de tus redes sociales',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Facebook
            _buildSocialMediaField(
              controller: _facebookController,
              label: 'Facebook',
              icon: Icons.facebook,
              color: Colors.blue.shade800,
              hint: 'https://facebook.com/tunegocio',
            ),
            const SizedBox(height: 16),

            // Instagram
            _buildSocialMediaField(
              controller: _instagramController,
              label: 'Instagram',
              icon: Icons.camera_alt,
              color: Colors.purple,
              hint: 'https://instagram.com/tunegocio',
            ),
            const SizedBox(height: 16),

            // TikTok
            _buildSocialMediaField(
              controller: _tiktokController,
              label: 'TikTok',
              icon: Icons.music_note,
              color: Colors.black,
              hint: 'https://tiktok.com/@tunegocio',
            ),
            const SizedBox(height: 16),

            // Twitter
            _buildSocialMediaField(
              controller: _twitterController,
              label: 'Twitter (X)',
              icon: Icons.tag,
              color: Colors.blue.shade400,
              hint: 'https://twitter.com/tunegocio',
            ),
            const SizedBox(height: 16),

            // YouTube
            _buildSocialMediaField(
              controller: _youtubeController,
              label: 'YouTube',
              icon: Icons.play_circle_outline,
              color: Colors.red,
              hint: 'https://youtube.com/@tunegocio',
            ),
            const SizedBox(height: 24),

            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tip: Los enlaces se abrirán cuando los clientes hagan clic en los iconos de redes sociales.',
                        style: TextStyle(color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialMediaField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'URL de $label',
            hintText: hint,
            prefixIcon: Icon(Icons.link, color: Colors.grey),
            border: const OutlineInputBorder(),
            suffixIcon: controller.text.isNotEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (Uri.tryParse(controller.text)?.hasAbsolutePath ?? false)
                        Icon(Icons.check_circle, color: Colors.green),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            controller.clear();
                          });
                        },
                      ),
                    ],
                  )
                : null,
          ),
          keyboardType: TextInputType.url,
          onChanged: (value) {
            setState(() {}); // Para actualizar el ícono de limpiar
          },
        ),
      ],
    );
  }

  Widget _buildMetodosPagoTab() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Configuración de Métodos de Pago',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configura los códigos QR para pagos con Yape y Plin',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Yape QR
            const Row(
              children: [
                Icon(Icons.qr_code, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'Código QR de Yape',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _yapeQRController,
              decoration: const InputDecoration(
                labelText: 'URL del Código QR de Yape',
                hintText: 'https://ejemplo.com/yape-qr.png',
                prefixIcon: Icon(Icons.image),
                border: OutlineInputBorder(),
                helperText: 'Ingresa la URL de la imagen del código QR de Yape',
              ),
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}),
            ),
            if (_yapeQRController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Vista previa:', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        height: 200,
                        width: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _yapeQRController.text,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('Error al cargar imagen', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(child: CircularProgressIndicator()),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            // Plin QR
            const Row(
              children: [
                Icon(Icons.qr_code, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'Código QR de Plin',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _plinQRController,
              decoration: const InputDecoration(
                labelText: 'URL del Código QR de Plin',
                hintText: 'https://ejemplo.com/plin-qr.png',
                prefixIcon: Icon(Icons.image),
                border: OutlineInputBorder(),
                helperText: 'Ingresa la URL de la imagen del código QR de Plin',
              ),
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}),
            ),
            if (_plinQRController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Vista previa:', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        height: 200,
                        width: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _plinQRController.text,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('Error al cargar imagen', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(child: CircularProgressIndicator()),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Información adicional
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Consejos',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('• Ingresa la URL completa de la imagen del código QR'),
                  Text('• Puedes subir las imágenes a servicios como Imgur, Google Drive, etc.'),
                  Text('• El código QR debe ser visible y fácil de escanear'),
                  Text('• Los clientes verán este QR al seleccionar el método de pago'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}