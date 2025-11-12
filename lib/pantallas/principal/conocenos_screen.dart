import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../main.dart'; // For InformacionNegocioProvider
import 'widgets/map_widget.dart';

/// Pantalla "Conócenos" que muestra información del negocio con imágenes
class ConocenosScreen extends StatelessWidget {
  const ConocenosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conócenos'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListenableBuilder(
        listenable: InformacionNegocioProvider.instance,
        builder: (context, child) {
          final provider = InformacionNegocioProvider.instance;

          if (provider.cargando) {
            return const Center(child: CircularProgressIndicator());
          }

          final info = provider.info;

          return SingleChildScrollView(
            child: Column(
              children: [

                // Contenido
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      // Historia - Imagen a la derecha
                      _buildSeccionIntercalada(
                        context,
                        'Nuestra Historia',
                        info.galeria.historia,
                        info.galeria.historiaImagenUrl,
                        Icons.history,
                        const Color(0xFFB8956C), // Café/Dorado del logo
                        imagenDerecha: true,
                      ),
                      const SizedBox(height: 32),

                      // Misión - Imagen a la izquierda (intercalado)
                      _buildSeccionIntercalada(
                        context,
                        'Misión',
                        info.galeria.mision,
                        info.galeria.misionImagenUrl,
                        Icons.flag,
                        const Color(0xFFD4A574), // Dorado claro
                        imagenDerecha: false,
                      ),
                      const SizedBox(height: 32),

                      // Visión - Imagen a la derecha (intercalado)
                      _buildSeccionIntercalada(
                        context,
                        'Visión',
                        info.galeria.vision,
                        info.galeria.visionImagenUrl,
                        Icons.visibility,
                        const Color(0xFF8B6F47), // Café oscuro
                        imagenDerecha: true,
                      ),
                      const SizedBox(height: 48),

                      // Sección de Contacto y Ubicación
                      _buildContactoYUbicacionSection(context, info),

                      const SizedBox(height: 32),

                      // Redes sociales
                      const Text(
                        'Síguenos',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSocialButton(
                            context,
                            'Facebook',
                            Icons.facebook,
                            const Color(0xFFB8956C), // Café/Dorado
                            () => _abrirUrl(info.redesSociales.facebook),
                          ),
                          _buildSocialButton(
                            context,
                            'Instagram',
                            Icons.camera_alt,
                            const Color(0xFFD4A574), // Dorado claro
                            () => _abrirUrl(info.redesSociales.instagram),
                          ),
                          _buildSocialButton(
                            context,
                            'WhatsApp',
                            Icons.chat,
                            const Color(0xFF8B6F47), // Café oscuro
                            () => _abrirWhatsApp(info.whatsapp),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSeccionIntercalada(
    BuildContext context,
    String titulo,
    String contenido,
    String? imagenUrl,
    IconData icono,
    Color color, {
    required bool imagenDerecha,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // En móvil (< 700px), mostrar vertical
        if (constraints.maxWidth < 700) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Row(
                  children: [
                    Icon(icono, color: color, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Imagen
                if (imagenUrl != null && imagenUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imagenUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                // Texto
                Text(
                  contenido,
                  style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          );
        }

        // En escritorio, mostrar horizontal intercalado
        final contenidoWidget = Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(icono, color: color, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  contenido,
                  style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        );

        final imagenWidget = imagenUrl != null && imagenUrl.isNotEmpty
            ? Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imagenUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 280,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 280,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      },
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink();

        return Container(
          constraints: const BoxConstraints(minHeight: 280),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: imagenDerecha
                ? [
                    contenidoWidget,
                    const SizedBox(width: 20),
                    imagenWidget,
                  ]
                : [
                    imagenWidget,
                    const SizedBox(width: 20),
                    contenidoWidget,
                  ],
          ),
        );
      },
    );
  }

  Widget _buildContactoYUbicacionSection(BuildContext context, info) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // En móvil (ancho < 700), mostrar vertical
        if (constraints.maxWidth < 700) {
          return Column(
            children: [
              // Título Contáctanos
              const Text(
                'Contáctanos',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Información de contacto
              _buildContactoInfoCard(info),
              const SizedBox(height: 32),
              // Título Ubícanos
              const Text(
                'Ubícanos',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Mapa de ubicación
              _buildMapSection(info),
            ],
          );
        }

        // En escritorio, mostrar horizontal
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información de contacto (izquierda)
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contáctanos',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildContactoInfoCard(info),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Mapa de ubicación (derecha)
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ubícanos',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildMapSection(info),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContactoInfoCard(info) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F0), // Beige claro
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4A574), width: 2), // Dorado claro
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A574).withValues(alpha: 0.3), // Dorado claro transparente
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.contact_phone, color: Color(0xFF8B6F47), size: 28), // Café oscuro
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Información de Contacto',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B6F47), // Café oscuro
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildContactoItem(Icons.location_on, 'Dirección', info.direccion),
          const SizedBox(height: 16),
          _buildContactoItem(Icons.phone, 'Teléfono', info.redesSociales.telefono),
          const SizedBox(height: 16),
          _buildContactoItem(Icons.email, 'Email', info.email),
          const SizedBox(height: 16),
          _buildContactoItem(
            Icons.access_time,
            'Horario de Atención',
            'Lunes - Viernes: ${info.galeria.horarioAtencion.lunesViernes}\nSábado: ${info.galeria.horarioAtencion.sabado}\nDomingo: ${info.galeria.horarioAtencion.domingo}',
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(info) {
    final ubicacionUrl = info.ubicacionMapsUrl;

    // Coordenadas de Repostería Arlex en Nueva Cajamarca
    const lat = -5.94002;
    const lng = -77.3061913;

    // Usar iframe embed de Google Maps (no requiere API key para visualización básica)
    final embedUrl = 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3953.5!2d$lng!3d$lat!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x0%3A0x0!2zNcKwNTYnMjQuMSJTIDc3wrAxOCcyMi4zIlc!5e0!3m2!1ses!2spe!4v1234567890!5m2!1ses!2spe';

    debugPrint('🗺️ URL del mapa embed: $embedUrl');

    return Container(
      height: 450,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4A574), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: ubicacionUrl != null && ubicacionUrl.isNotEmpty
            ? MapWidget(
                mapUrl: ubicacionUrl,
                onTap: () => _abrirUrl(ubicacionUrl),
              )
            : Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_outlined, size: 100, color: Colors.grey[400]),
                      const SizedBox(height: 20),
                      Text(
                        'Ubicación no disponible',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildContactoItem(IconData icono, String titulo, String contenido) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFD4A574).withValues(alpha: 0.3), // Dorado claro transparente
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icono, color: const Color(0xFFB8956C), size: 26), // Café/Dorado
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF8B6F47), // Café oscuro
                ),
              ),
              const SizedBox(height: 6),
              Text(
                contenido,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(
    BuildContext context,
    String nombre,
    IconData icono,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icono, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              nombre,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirUrl(String url) async {
    if (url.isEmpty) return;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _abrirWhatsApp(String numero) async {
    if (numero.isEmpty) return;

    // Limpiar el número (quitar espacios, guiones, etc.)
    final numeroLimpio = numero.replaceAll(RegExp(r'[^\d+]'), '');
    final url = 'https://wa.me/$numeroLimpio';

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
