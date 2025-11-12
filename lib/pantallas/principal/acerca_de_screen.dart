import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../main.dart'; // For InformacionNegocioProvider

class AcercaDeScreen extends StatelessWidget {
  const AcercaDeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final info = InformacionNegocioProvider.instance.info;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acerca de Nosotros'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con imagen
            Container(
              width: double.infinity,
              height: 200,
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cake, size: 80, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    info.galeria.nombre,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Historia
                  _buildSeccion(
                    context,
                    'Nuestra Historia',
                    info.galeria.historia,
                    info.galeria.historiaImagenUrl,
                    Icons.history,
                    const Color(0xFFB8956C), // Café/Dorado del logo
                  ),
                  const SizedBox(height: 24),

                  // Misión
                  _buildSeccion(
                    context,
                    'Misión',
                    info.galeria.mision,
                    info.galeria.misionImagenUrl,
                    Icons.flag,
                    const Color(0xFFD4A574), // Dorado claro
                  ),
                  const SizedBox(height: 24),

                  // Visión
                  _buildSeccion(
                    context,
                    'Visión',
                    info.galeria.vision,
                    info.galeria.visionImagenUrl,
                    Icons.visibility,
                    const Color(0xFF8B6F47), // Café oscuro
                  ),
                  const SizedBox(height: 32),

                  // Sección de Contacto y Ubicación
                  const Text(
                    'Contáctanos',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccion(
    BuildContext context,
    String titulo,
    String contenido,
    String? imagenUrl,
    IconData icono,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: color, size: 28),
              const SizedBox(width: 12),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (imagenUrl != null && imagenUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imagenUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            contenido,
            style: const TextStyle(fontSize: 16, height: 1.5),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildContactoYUbicacionSection(BuildContext context, info) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // En móvil (ancho < 700), mostrar vertical
        if (constraints.maxWidth < 700) {
          return Column(
            children: [
              // Información de contacto
              _buildContactoInfoCard(info),
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
              child: _buildContactoInfoCard(info),
            ),
            const SizedBox(width: 24),
            // Mapa de ubicación (derecha)
            Expanded(
              flex: 1,
              child: _buildMapSection(info),
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

    return Container(
      height: 450,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: ubicacionUrl != null && ubicacionUrl.isNotEmpty
            ? Stack(
                children: [
                  // Vista previa del mapa con gradiente y diseño mejorado
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFF5F0), // Beige muy claro
                          Color(0xFFFFEFE5), // Beige/rosa muy suave
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 120, color: const Color(0xFFD4A574)), // Dorado claro
                        const SizedBox(height: 24),
                        const Text(
                          'Nuestra Ubicación',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Haz clic en el botón para ver nuestra ubicación en Google Maps',
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botón para abrir en Google Maps
                  Positioned(
                    bottom: 30,
                    left: 30,
                    right: 30,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _abrirUrl(ubicacionUrl),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB8956C), // Café/Dorado del logo
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on, color: Colors.white, size: 32),
                              SizedBox(width: 12),
                              Text(
                                'Abrir en Google Maps',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.open_in_new, color: Colors.white, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'El administrador puede configurar la ubicación en la sección de configuración',
                          style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                          textAlign: TextAlign.center,
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

