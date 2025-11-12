import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_firestore_service.dart';

/// Servicio para gestionar la información del negocio
class InformacionNegocioService {
  static final InformacionNegocioService _instance =
      InformacionNegocioService._internal();
  factory InformacionNegocioService() => _instance;
  InformacionNegocioService._internal();

  final FirebaseFirestoreService _firestore = FirebaseFirestoreService();
  static const String _coleccion = 'informacion_negocio';
  static const String _documentId = 'config';

  // ============================================================================
  // OBTENER INFORMACIÓN
  // ============================================================================

  /// Obtener información completa del negocio
  Future<Map<String, dynamic>?> obtenerInformacion() async {
    return await _firestore.leer(
      coleccion: _coleccion,
      documentId: _documentId,
    );
  }

  /// Stream de información del negocio
  Stream<Map<String, dynamic>?> streamInformacion() {
    return _firestore.streamDocumento(
      coleccion: _coleccion,
      documentId: _documentId,
    );
  }

  // ============================================================================
  // ACTUALIZAR INFORMACIÓN
  // ============================================================================

  /// Actualizar información básica
  Future<Map<String, dynamic>> actualizarInformacionBasica({
    String? nombre,
    String? slogan,
    String? logoUrl,
    String? logoSecundarioUrl,
    required String actualizadoPor,
  }) async {
    final Map<String, dynamic> cambios = {
      'fechaActualizacion': FieldValue.serverTimestamp(),
      'actualizadoPor': actualizadoPor,
    };

    if (nombre != null) cambios['nombre'] = nombre;
    if (slogan != null) cambios['slogan'] = slogan;
    if (logoUrl != null) cambios['logo'] = logoUrl;
    if (logoSecundarioUrl != null) cambios['logoSecundario'] = logoSecundarioUrl;

    return await _firestore.actualizar(
      coleccion: _coleccion,
      documentId: _documentId,
      datos: cambios,
    );
  }

  /// Actualizar historia y valores
  Future<Map<String, dynamic>> actualizarHistoriaValores({
    String? historia,
    String? mision,
    String? vision,
    List<String>? valores,
    required String actualizadoPor,
  }) async {
    final Map<String, dynamic> cambios = {
      'fechaActualizacion': FieldValue.serverTimestamp(),
      'actualizadoPor': actualizadoPor,
    };

    if (historia != null) cambios['historia'] = historia;
    if (mision != null) cambios['mision'] = mision;
    if (vision != null) cambios['vision'] = vision;
    if (valores != null) cambios['valores'] = valores;

    return await _firestore.actualizar(
      coleccion: _coleccion,
      documentId: _documentId,
      datos: cambios,
    );
  }

  /// Actualizar información de contacto
  Future<Map<String, dynamic>> actualizarContacto({
    String? telefono,
    String? email,
    String? whatsapp,
    String? direccion,
    Map<String, String>? horarioAtencion,
    required String actualizadoPor,
  }) async {
    final Map<String, dynamic> cambios = {
      'fechaActualizacion': FieldValue.serverTimestamp(),
      'actualizadoPor': actualizadoPor,
    };

    if (telefono != null) cambios['telefono'] = telefono;
    if (email != null) cambios['email'] = email;
    if (whatsapp != null) cambios['whatsapp'] = whatsapp;
    if (direccion != null) cambios['direccion'] = direccion;
    if (horarioAtencion != null) cambios['horarioAtencion'] = horarioAtencion;

    return await _firestore.actualizar(
      coleccion: _coleccion,
      documentId: _documentId,
      datos: cambios,
    );
  }

  /// Actualizar redes sociales
  Future<Map<String, dynamic>> actualizarRedesSociales({
    String? facebook,
    String? instagram,
    String? tiktok,
    String? twitter,
    String? youtube,
    required String actualizadoPor,
  }) async {
    final Map<String, dynamic> redesSociales = {};

    if (facebook != null) redesSociales['facebook'] = facebook;
    if (instagram != null) redesSociales['instagram'] = instagram;
    if (tiktok != null) redesSociales['tiktok'] = tiktok;
    if (twitter != null) redesSociales['twitter'] = twitter;
    if (youtube != null) redesSociales['youtube'] = youtube;

    return await _firestore.actualizar(
      coleccion: _coleccion,
      documentId: _documentId,
      datos: {
        'redesSociales': redesSociales,
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'actualizadoPor': actualizadoPor,
      },
    );
  }

  /// Actualizar configuración del negocio
  Future<Map<String, dynamic>> actualizarConfiguracion({
    bool? aceptaPedidosOnline,
    int? tiempoPreparacionMinimo,
    double? montoMinimoEnvio,
    double? costoEnvio,
    int? radiusEntregaKm,
    double? iva,
    bool? aceptaReservas,
    required String actualizadoPor,
  }) async {
    final Map<String, dynamic> configuracion = {};

    if (aceptaPedidosOnline != null) {
      configuracion['aceptaPedidosOnline'] = aceptaPedidosOnline;
    }
    if (tiempoPreparacionMinimo != null) {
      configuracion['tiempoPreparacionMinimo'] = tiempoPreparacionMinimo;
    }
    if (montoMinimoEnvio != null) {
      configuracion['montoMinimoEnvio'] = montoMinimoEnvio;
    }
    if (costoEnvio != null) configuracion['costoEnvio'] = costoEnvio;
    if (radiusEntregaKm != null) {
      configuracion['radiusEntregaKm'] = radiusEntregaKm;
    }
    if (iva != null) configuracion['iva'] = iva;
    if (aceptaReservas != null) configuracion['aceptaReservas'] = aceptaReservas;

    return await _firestore.actualizar(
      coleccion: _coleccion,
      documentId: _documentId,
      datos: {
        'configuracion': configuracion,
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'actualizadoPor': actualizadoPor,
      },
    );
  }

  /// Actualizar toda la información del negocio de una sola vez
  Future<Map<String, dynamic>> actualizarInformacionCompleta({
    required String nombre,
    required String mision,
    required String vision,
    required String historia,
    required String telefono,
    required String email,
    required String direccion,
    required String horario,
    required String facebook,
    required String instagram,
    required String whatsapp,
    String? slogan,
    String? logo,
    List<String>? valores,
    required String actualizadoPor,
  }) async {
    // Construir objeto horarioAtencion
    final Map<String, String> horarioAtencion = {};

    // Parsear el horario simple a un objeto estructurado
    // Por ahora, guardamos el horario completo en cada día
    final lineasHorario = horario.split('\n');
    for (var linea in lineasHorario) {
      linea = linea.trim();
      if (linea.isEmpty) continue;

      // Buscar patrones como "Lunes-Viernes: 8:00 AM - 6:00 PM"
      if (linea.toLowerCase().contains('lunes') && linea.toLowerCase().contains('viernes')) {
        final partes = linea.split(':');
        if (partes.length > 1) {
          horarioAtencion['lunes_viernes'] = partes.sublist(1).join(':').trim();
        }
      } else if (linea.toLowerCase().contains('sábado') || linea.toLowerCase().contains('sabado')) {
        final partes = linea.split(':');
        if (partes.length > 1) {
          horarioAtencion['sabado'] = partes.sublist(1).join(':').trim();
        }
      } else if (linea.toLowerCase().contains('domingo')) {
        final partes = linea.split(':');
        if (partes.length > 1) {
          horarioAtencion['domingo'] = partes.sublist(1).join(':').trim();
        }
      }
    }

    // Si no se parseó nada, usar valores por defecto
    if (horarioAtencion.isEmpty) {
      horarioAtencion['lunes_viernes'] = horario;
      horarioAtencion['sabado'] = horario;
      horarioAtencion['domingo'] = 'Cerrado';
    }

    final Map<String, dynamic> cambios = {
      'nombre': nombre,
      'mision': mision,
      'vision': vision,
      'historia': historia,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'horarioAtencion': horarioAtencion,
      'redesSociales': {
        'facebook': facebook,
        'instagram': instagram,
      },
      'whatsapp': whatsapp,
      'fechaActualizacion': FieldValue.serverTimestamp(),
      'actualizadoPor': actualizadoPor,
    };

    if (slogan != null) cambios['slogan'] = slogan;
    if (logo != null) cambios['logo'] = logo;
    if (valores != null) cambios['valores'] = valores;

    return await _firestore.actualizar(
      coleccion: _coleccion,
      documentId: _documentId,
      datos: cambios,
    );
  }

  /// Actualizar galería
  Future<Map<String, dynamic>> actualizarGaleria({
    required List<Map<String, dynamic>> galeria,
    required String actualizadoPor,
  }) async {
    return await _firestore.actualizar(
      coleccion: _coleccion,
      documentId: _documentId,
      datos: {
        'galeria': galeria,
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'actualizadoPor': actualizadoPor,
      },
    );
  }

  /// Agregar imagen a la galería
  Future<Map<String, dynamic>> agregarImagenGaleria({
    required String url,
    String? descripcion,
    required String actualizadoPor,
  }) async {
    final info = await obtenerInformacion();

    if (info == null) {
      return {
        'success': false,
        'message': 'No se pudo obtener la información del negocio',
      };
    }

    final galeria = List<Map<String, dynamic>>.from(info['galeria'] ?? []);

    final nuevaImagen = {
      'url': url,
      'descripcion': descripcion ?? '',
      'orden': galeria.length,
    };

    galeria.add(nuevaImagen);

    return await actualizarGaleria(
      galeria: galeria,
      actualizadoPor: actualizadoPor,
    );
  }

  /// Eliminar imagen de la galería
  Future<Map<String, dynamic>> eliminarImagenGaleria({
    required int indice,
    required String actualizadoPor,
  }) async {
    final info = await obtenerInformacion();

    if (info == null) {
      return {
        'success': false,
        'message': 'No se pudo obtener la información del negocio',
      };
    }

    final galeria = List<Map<String, dynamic>>.from(info['galeria'] ?? []);

    if (indice < 0 || indice >= galeria.length) {
      return {
        'success': false,
        'message': 'Índice inválido',
      };
    }

    galeria.removeAt(indice);

    // Reordenar
    for (int i = 0; i < galeria.length; i++) {
      galeria[i]['orden'] = i;
    }

    return await actualizarGaleria(
      galeria: galeria,
      actualizadoPor: actualizadoPor,
    );
  }

  // ============================================================================
  // INICIALIZACIÓN
  // ============================================================================

  /// Crear información inicial del negocio
  Future<Map<String, dynamic>> crearInformacionInicial({
    required String nombre,
    required String email,
    required String telefono,
    required String creadoPor,
  }) async {
    final datosIniciales = {
      'nombre': nombre,
      'slogan': 'Endulzando tus momentos especiales',
      'logo': '',
      'logoSecundario': '',
      'historia': '',
      'mision': '',
      'vision': '',
      'valores': <String>[],
      'telefono': telefono,
      'email': email,
      'whatsapp': telefono,
      'direccion': '',
      'horarioAtencion': {
        'lunes_viernes': '8:00 AM - 6:00 PM',
        'sabado': '9:00 AM - 5:00 PM',
        'domingo': 'Cerrado',
      },
      'redesSociales': {
        'facebook': '',
        'instagram': '',
        'tiktok': '',
        'twitter': '',
        'youtube': '',
      },
      'configuracion': {
        'aceptaPedidosOnline': true,
        'tiempoPreparacionMinimo': 24,
        'montoMinimoEnvio': 20.0,
        'costoEnvio': 5.0,
        'radiusEntregaKm': 10,
        'iva': 0.0,
        'aceptaReservas': true,
      },
      'galeria': <Map<String, dynamic>>[],
      'fechaActualizacion': FieldValue.serverTimestamp(),
      'actualizadoPor': creadoPor,
    };

    return await _firestore.crear(
      coleccion: _coleccion,
      documentId: _documentId,
      datos: datosIniciales,
    );
  }

  /// Verificar si existe información del negocio
  Future<bool> existeInformacion() async {
    return await _firestore.existeDocumento(
      coleccion: _coleccion,
      documentId: _documentId,
    );
  }

  // ============================================================================
  // LIMPIEZA Y MANTENIMIENTO
  // ============================================================================

  /// Limpiar URLs de imágenes problemáticas que causan errores CORS
  /// Remueve URLs externas que no son de Firebase Storage o servicios CORS-habilitados
  Future<Map<String, dynamic>> limpiarImagenesProblematicas({
    required String actualizadoPor,
  }) async {
    try {
      final info = await obtenerInformacion();

      if (info == null) {
        return {
          'success': false,
          'message': 'No se pudo obtener la información del negocio',
        };
      }

      int urlsLimpiadas = 0;
      final Map<String, dynamic> cambios = {
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'actualizadoPor': actualizadoPor,
      };

      // Lista de dominios problemáticos conocidos
      final dominiosProblematicos = [
        'senamhi.gob.pe',
        'd1yjjnpx0p53s8.cloudfront.net',
      ];

      bool esUrlProblematica(String? url) {
        if (url == null || url.isEmpty) return false;
        return dominiosProblematicos.any((dominio) => url.contains(dominio));
      }

      // Limpiar galería
      if (info.containsKey('galeria') && info['galeria'] is Map) {
        final galeria = Map<String, dynamic>.from(info['galeria']);
        final galeriaActualizada = <String, dynamic>{};

        // Limpiar imagen de historia
        if (esUrlProblematica(galeria['historiaImagenUrl'])) {
          galeriaActualizada['historiaImagenUrl'] = null;
          urlsLimpiadas++;
        }

        // Limpiar imagen de misión
        if (esUrlProblematica(galeria['misionImagenUrl'])) {
          galeriaActualizada['misionImagenUrl'] = null;
          urlsLimpiadas++;
        }

        // Limpiar imagen de visión
        if (esUrlProblematica(galeria['visionImagenUrl'])) {
          galeriaActualizada['visionImagenUrl'] = null;
          urlsLimpiadas++;
        }

        // Limpiar logo
        if (esUrlProblematica(galeria['logo'])) {
          galeriaActualizada['logo'] = '';
          urlsLimpiadas++;
        }

        // Limpiar logo secundario
        if (esUrlProblematica(galeria['logoSecundario'])) {
          galeriaActualizada['logoSecundario'] = '';
          urlsLimpiadas++;
        }

        if (galeriaActualizada.isNotEmpty) {
          cambios['galeria'] = galeriaActualizada;
        }
      }

      // Si no hay cambios, retornar éxito sin actualizar
      if (cambios.length == 2) { // Solo tiene fechaActualizacion y actualizadoPor
        return {
          'success': true,
          'message': 'No se encontraron URLs problemáticas',
          'urlsLimpiadas': 0,
        };
      }

      // Actualizar en Firebase
      await _firestore.actualizar(
        coleccion: _coleccion,
        documentId: _documentId,
        datos: cambios,
      );

      return {
        'success': true,
        'message': 'URLs problemáticas limpiadas exitosamente',
        'urlsLimpiadas': urlsLimpiadas,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al limpiar URLs: $e',
        'urlsLimpiadas': 0,
      };
    }
  }
}
