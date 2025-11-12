import 'package:flutter/material.dart';

/// Widget para cargar imágenes de red con manejo de errores CORS
class SafeNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final Widget? placeholder;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    this.placeholder,
  });

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    // Rechazar URLs de Google y otros redirects
    if (url.contains('google.com/url?') ||
        url.contains('google.com/search?') ||
        url.contains('redirect') ||
        url.startsWith('www.') && !url.startsWith('http')) {
      return false;
    }

    // Verificar que sea una URL válida
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isValidImageUrl(imageUrl)) {
      // Si la URL no es válida, mostrar el widget de error directamente
      if (errorBuilder != null) {
        return errorBuilder!(context, Exception('Invalid URL'), null);
      }
      return placeholder ?? Icon(Icons.image_not_supported, size: width ?? height ?? 50);
    }

    return Image.network(
      imageUrl!,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: errorBuilder ?? (context, error, stackTrace) {
        return placeholder ?? Icon(Icons.broken_image, size: width ?? height ?? 50);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
    );
  }
}
