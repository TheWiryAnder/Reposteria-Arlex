import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:universal_html/html.dart' as html;

/// Widget para mostrar el mapa de Google Maps embebido
class MapWidget extends StatefulWidget {
  final String mapUrl;
  final VoidCallback? onTap;
  final double? height;

  const MapWidget({
    super.key,
    required this.mapUrl,
    this.onTap,
    this.height,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  static int _viewIdCounter = 0;
  late String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'google-maps-embed-${_viewIdCounter++}';
    _registerMapIframe();
  }

  /// Extrae la URL del src desde el código HTML del iframe
  String _extractSrcFromIframeHtml(String htmlCode) {
    try {
      // Buscar el atributo src dentro del HTML del iframe
      final srcRegex = RegExp(r'src\s*=\s*["\x27]([^"\x27]+)["\x27]', caseSensitive: false);
      final match = srcRegex.firstMatch(htmlCode);

      if (match != null && match.groupCount >= 1) {
        final srcUrl = match.group(1)!;
        debugPrint('✅ URL del mapa extraída: $srcUrl');
        return srcUrl;
      }

      // Si no se encuentra el patrón del iframe, asumir que es una URL directa
      if (htmlCode.startsWith('http')) {
        debugPrint('✅ URL directa detectada: $htmlCode');
        return htmlCode;
      }

      debugPrint('⚠️ No se pudo extraer URL del iframe, usando URL por defecto');
      // URL por defecto (Nueva Cajamarca)
      return 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d906.8406093051519!2d-77.30586690842254!3d-5.9399615819247655!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x91b6ddea76c59dc3%3A0xa3d15d7666874d78!2sHospital%20Rural%20De%20Nueva%20Cajamarca%20(S.I.S)!5e1!3m2!1ses!2spe!4v1762624618457!5m2!1ses!2spe';
    } catch (e) {
      debugPrint('❌ Error al extraer URL del iframe: $e');
      // URL por defecto en caso de error
      return 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d906.8406093051519!2d-77.30586690842254!3d-5.9399615819247655!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x91b6ddea76c59dc3%3A0xa3d15d7666874d78!2sHospital%20Rural%20De%20Nueva%20Cajamarca%20(S.I.S)!5e1!3m2!1ses!2spe!4v1762624618457!5m2!1ses!2spe';
    }
  }

  void _registerMapIframe() {
    // Extraer URL del código HTML del iframe
    final mapSrcUrl = _extractSrcFromIframeHtml(widget.mapUrl);

    debugPrint('🗺️ Registrando iframe con view type: $_viewType');
    debugPrint('🗺️ URL final del mapa: $mapSrcUrl');

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = mapSrcUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allowFullscreen = true;
        iframe.setAttribute('loading', 'lazy');
        iframe.setAttribute('referrerpolicy', 'no-referrer-when-downgrade');
        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Usar altura proporcionada o calcular basada en restricciones del contenedor
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : null;
        final containerHeight = widget.height ?? availableHeight ?? 250.0;

        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            height: containerHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: HtmlElementView(
              viewType: _viewType,
            ),
          ),
        );
      },
    );
  }
}
