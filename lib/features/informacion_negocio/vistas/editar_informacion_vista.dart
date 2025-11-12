import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
// import 'package:provider/provider.dart';
// import '../../../controladores/informacion_controlador.dart';
// import '../../../modelos/informacion_negocio_modelo.dart';

class EditarInformacionVista extends StatefulWidget {
  const EditarInformacionVista({super.key});

  @override
  State<EditarInformacionVista> createState() => _EditarInformacionVistaState();
}

class _EditarInformacionVistaState extends State<EditarInformacionVista>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controladores de texto para información general
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _emailController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _telefonoController = TextEditingController();

  // Controladores para galería
  final _historiaController = TextEditingController();
  final _misionController = TextEditingController();
  final _visionController = TextEditingController();
  final _logoController = TextEditingController();
  final _logoSecundarioController = TextEditingController();

  // Controladores para horarios
  final _domingoController = TextEditingController();
  final _lunesViernesController = TextEditingController();
  final _sabadoController = TextEditingController();

  // Controladores para redes sociales
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _twitterController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _sloganController = TextEditingController();

  // Controladores para configuración
  final _costoEnvioController = TextEditingController();
  final _ivaController = TextEditingController();
  final _montoMinimoController = TextEditingController();
  final _radiusEntregaController = TextEditingController();
  final _tiempoPreparacionController = TextEditingController();

  // Estados de configuración
  bool _aceptaPedidosOnline = true;
  bool _aceptaReservas = true;

  // Lista de valores
  List<String> _valores = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    // TODO: Implementar carga de datos con el controlador
    // final controlador = context.read<InformacionControlador>();
    // await controlador.cargarInformacion();

    // if (controlador.informacion != null) {
    //   _llenarFormulario(controlador.informacion!);
    // }
  }

  // void _llenarFormulario(InformacionNegocio info) {
  //   // Información general
  //   _nombreController.text = info.galeria.nombre;
  //   _direccionController.text = info.direccion;
  //   _emailController.text = info.email;
  //   _whatsappController.text = info.whatsapp;
  //   _telefonoController.text = info.redesSociales.telefono;

  //   // Galería
  //   _historiaController.text = info.galeria.historia;
  //   _misionController.text = info.galeria.mision;
  //   _visionController.text = info.galeria.vision;
  //   _logoController.text = info.galeria.logo;
  //   _logoSecundarioController.text = info.galeria.logoSecundario;

  //   // Horarios
  //   _domingoController.text = info.galeria.horarioAtencion.domingo;
  //   _lunesViernesController.text = info.galeria.horarioAtencion.lunesViernes;
  //   _sabadoController.text = info.galeria.horarioAtencion.sabado;

  //   // Redes sociales
  //   _facebookController.text = info.redesSociales.facebook;
  //   _instagramController.text = info.redesSociales.instagram;
  //   _tiktokController.text = info.redesSociales.tiktok;
  //   _twitterController.text = info.redesSociales.twitter;
  //   _youtubeController.text = info.redesSociales.youtube;
  //   _sloganController.text = info.redesSociales.slogan;

  //   // Configuración
  //   _costoEnvioController.text = info.configuracion.costoEnvio.toString();
  //   _ivaController.text = info.configuracion.iva.toString();
  //   _montoMinimoController.text = info.configuracion.montoMinimoEnvio.toString();
  //   _radiusEntregaController.text = info.configuracion.radiusEntregaKm.toString();
  //   _tiempoPreparacionController.text = info.configuracion.tiempoPreparacionMinimo.toString();

  //   setState(() {
  //     _aceptaPedidosOnline = info.configuracion.aceptaPedidosOnline;
  //     _aceptaReservas = info.configuracion.aceptaReservas;
  //     _valores = List.from(info.galeria.valores);
  //   });
  // }

  @override
  void dispose() {
    _tabController.dispose();
    _nombreController.dispose();
    _direccionController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    _telefonoController.dispose();
    _historiaController.dispose();
    _misionController.dispose();
    _visionController.dispose();
    _logoController.dispose();
    _logoSecundarioController.dispose();
    _domingoController.dispose();
    _lunesViernesController.dispose();
    _sabadoController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _twitterController.dispose();
    _youtubeController.dispose();
    _sloganController.dispose();
    _costoEnvioController.dispose();
    _ivaController.dispose();
    _montoMinimoController.dispose();
    _radiusEntregaController.dispose();
    _tiempoPreparacionController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    // TODO: Implementar guardado con el controlador
    // final controlador = context.read<InformacionControlador>();

    // if (controlador.informacion == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('No hay información para actualizar')),
    //   );
    //   return;
    // }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función en desarrollo')),
    );
    return;

    // // Crear objeto actualizado
    // final informacionActualizada = InformacionNegocio(
    //   configuracion: ConfiguracionNegocio(
    //     aceptaPedidosOnline: _aceptaPedidosOnline,
    //     aceptaReservas: _aceptaReservas,
    //     costoEnvio: double.tryParse(_costoEnvioController.text) ?? 0,
    //     iva: double.tryParse(_ivaController.text) ?? 0,
    //     montoMinimoEnvio: int.tryParse(_montoMinimoController.text) ?? 0,
    //     radiusEntregaKm: int.tryParse(_radiusEntregaController.text) ?? 10,
    //     tiempoPreparacionMinimo: int.tryParse(_tiempoPreparacionController.text) ?? 24,
    //   ),
    //   direccion: _direccionController.text,
    //   email: _emailController.text,
    //   fechaActualizacion: DateTime.now(),
    //   galeria: Galeria(
    //     historia: _historiaController.text,
    //     horarioAtencion: HorarioAtencion(
    //       domingo: _domingoController.text,
    //       lunesViernes: _lunesViernesController.text,
    //       sabado: _sabadoController.text,
    //     ),
    //     logo: _logoController.text,
    //     logoSecundario: _logoSecundarioController.text,
    //     mision: _misionController.text,
    //     nombre: _nombreController.text,
    //     valores: _valores,
    //     vision: _visionController.text,
    //   ),
    //   redesSociales: RedesSociales(
    //     facebook: _facebookController.text,
    //     instagram: _instagramController.text,
    //     tiktok: _tiktokController.text,
    //     twitter: _twitterController.text,
    //     youtube: _youtubeController.text,
    //     slogan: _sloganController.text,
    //     telefono: _telefonoController.text,
    //   ),
    //   whatsapp: _whatsappController.text,
    // );

    // final resultado = await controlador.actualizarInformacion(informacionActualizada);

    // if (!mounted) return;

    // if (resultado) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('Información actualizada exitosamente'),
    //       backgroundColor: Colors.green,
    //     ),
    //   );
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text(controlador.error ?? 'Error al actualizar'),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    // }
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
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(text: 'General', icon: Icon(Icons.info, size: 20)),
            Tab(text: 'Galería', icon: Icon(Icons.photo_library, size: 20)),
            Tab(text: 'Redes Sociales', icon: Icon(Icons.share, size: 20)),
            Tab(text: 'Configuración', icon: Icon(Icons.settings, size: 20)),
            Tab(text: 'Métodos de Pago', icon: Icon(Icons.payment, size: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _guardarCambios,
            tooltip: 'Guardar cambios',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralTab(),
          _buildGaleriaTab(),
          _buildRedesSocialesTab(),
          _buildConfiguracionTab(),
          _buildMetodosPagoTab(),
        ],
      ),
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información General',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nombreController,
            decoration: const InputDecoration(
              labelText: 'Nombre del Negocio',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _direccionController,
            decoration: const InputDecoration(
              labelText: 'Dirección',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _whatsappController,
            decoration: const InputDecoration(
              labelText: 'WhatsApp',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _telefonoController,
            decoration: const InputDecoration(
              labelText: 'Teléfono',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.call),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          const Text(
            'Horarios de Atención',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _lunesViernesController,
            decoration: const InputDecoration(
              labelText: 'Lunes a Viernes',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.access_time),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _sabadoController,
            decoration: const InputDecoration(
              labelText: 'Sábado',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.access_time),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _domingoController,
            decoration: const InputDecoration(
              labelText: 'Domingo',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.access_time),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaleriaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historia y Misión',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _historiaController,
            decoration: const InputDecoration(
              labelText: 'Historia',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.history_edu),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _misionController,
            decoration: const InputDecoration(
              labelText: 'Misión',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.flag),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _visionController,
            decoration: const InputDecoration(
              labelText: 'Visión',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.visibility),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          const Text(
            'Valores de la Empresa',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._valores.asMap().entries.map((entry) {
            final index = entry.key;
            final valor = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: valor),
                      decoration: InputDecoration(
                        labelText: 'Valor ${index + 1}',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _valores[index] = value;
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _valores.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
            );
          }),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _valores.add('');
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Agregar Valor'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Logos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _logoController,
            decoration: const InputDecoration(
              labelText: 'URL del Logo Principal',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.image),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _logoSecundarioController,
            decoration: const InputDecoration(
              labelText: 'URL del Logo Secundario',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.image),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedesSocialesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Redes Sociales',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _sloganController,
            decoration: const InputDecoration(
              labelText: 'Slogan',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.format_quote),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _facebookController,
            decoration: const InputDecoration(
              labelText: 'Facebook',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.facebook),
              hintText: 'https://facebook.com/...',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _instagramController,
            decoration: const InputDecoration(
              labelText: 'Instagram',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.camera_alt),
              hintText: 'https://instagram.com/...',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tiktokController,
            decoration: const InputDecoration(
              labelText: 'TikTok',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.music_note),
              hintText: 'https://tiktok.com/...',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _twitterController,
            decoration: const InputDecoration(
              labelText: 'Twitter/X',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.alternate_email),
              hintText: 'https://twitter.com/...',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _youtubeController,
            decoration: const InputDecoration(
              labelText: 'YouTube',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.video_library),
              hintText: 'https://youtube.com/...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfiguracionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuración de Pedidos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Aceptar Pedidos Online'),
            subtitle: const Text('Permitir que los clientes realicen pedidos en línea'),
            value: _aceptaPedidosOnline,
            onChanged: (value) {
              setState(() {
                _aceptaPedidosOnline = value;
              });
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Aceptar Reservas'),
            subtitle: const Text('Permitir que los clientes hagan reservas'),
            value: _aceptaReservas,
            onChanged: (value) {
              setState(() {
                _aceptaReservas = value;
              });
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Precios y Costos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _costoEnvioController,
            decoration: const InputDecoration(
              labelText: 'Costo de Envío',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.local_shipping),
              prefixText: '\$ ',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ivaController,
            decoration: const InputDecoration(
              labelText: 'IVA (%)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.percent),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _montoMinimoController,
            decoration: const InputDecoration(
              labelText: 'Monto Mínimo para Envío',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
              prefixText: '\$ ',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          const Text(
            'Parámetros de Entrega',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _radiusEntregaController,
            decoration: const InputDecoration(
              labelText: 'Radio de Entrega (Km)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.map),
              suffixText: 'Km',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tiempoPreparacionController,
            decoration: const InputDecoration(
              labelText: 'Tiempo Mínimo de Preparación (horas)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.timer),
              suffixText: 'horas',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildMetodosPagoTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('configuracion')
          .doc('metodosPago')
          .snapshots(),
      builder: (context, snapshot) {
        // Manejo de errores
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar los métodos de pago',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Por favor, intenta nuevamente',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {}); // Forzar reconstrucción
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cargando métodos de pago...'),
              ],
            ),
          );
        }

        // Obtener datos actuales
        String? yapeQR;
        String? plinQR;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          yapeQR = data?['yapeQR'] as String?;
          plinQR = data?['plinQR'] as String?;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Configuración de Métodos de Pago',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configura los códigos QR para pagos con Yape y Plin',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Card para Yape
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.qr_code, color: Colors.purple, size: 32),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Yape',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (yapeQR != null && yapeQR.isNotEmpty) ...[
                      const Text('Código QR actual:', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            yapeQR,
                            height: 200,
                            width: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                width: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No hay código QR configurado para Yape',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _subirQR('yape'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.upload),
                        label: Text(yapeQR != null && yapeQR.isNotEmpty ? 'Cambiar QR de Yape' : 'Subir QR de Yape'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Card para Plin
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.qr_code, color: Colors.blue, size: 32),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Plin',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (plinQR != null && plinQR.isNotEmpty) ...[
                      const Text('Código QR actual:', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            plinQR,
                            height: 200,
                            width: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                width: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No hay código QR configurado para Plin',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _subirQR('plin'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.upload),
                        label: Text(plinQR != null && plinQR.isNotEmpty ? 'Cambiar QR de Plin' : 'Subir QR de Plin'),
                      ),
                    ),
                  ],
                ),
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
                  Text('• Asegúrate de subir una imagen clara del código QR'),
                  Text('• El código QR debe ser visible y fácil de escanear'),
                  Text('• Formatos aceptados: PNG, JPG, JPEG'),
                  Text('• Los clientes verán este QR al seleccionar el método de pago'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _subirQR(String tipo) async {
    try {
      // Seleccionar imagen
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      if (!mounted) return;

      // Mostrar diálogo de progreso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Subiendo código QR...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Leer bytes de la imagen
      final Uint8List imageBytes = await image.readAsBytes();

      // Subir a Firebase Storage
      final String fileName = 'qr_${tipo}_${DateTime.now().millisecondsSinceEpoch}.png';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('metodos_pago')
          .child(fileName);

      final UploadTask uploadTask = storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/png'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Guardar URL en Firestore
      await FirebaseFirestore.instance
          .collection('configuracion')
          .doc('metodosPago')
          .set({
        '${tipo}QR': downloadUrl,
      }, SetOptions(merge: true));

      if (!mounted) return;

      // Cerrar diálogo de progreso
      Navigator.of(context).pop();

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Código QR de ${tipo.toUpperCase()} actualizado exitosamente'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Cerrar diálogo de progreso si está abierto
      Navigator.of(context).pop();

      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir el código QR: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}