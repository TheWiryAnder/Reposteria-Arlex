import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../modelos/informacion_negocio_modelo.dart';

class InformacionServicio {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _coleccion = 'informacion_negocio';
  final String _documentoConfig = 'config';

  // Obtener la información del negocio
  Future<InformacionNegocio?> obtenerInformacion() async {
    try {
      final doc = await _firestore
          .collection(_coleccion)
          .doc(_documentoConfig)
          .get();

      if (!doc.exists) {
        return null;
      }

      return InformacionNegocio.fromFirestore(doc);
    } catch (e) {
      print('Error al obtener información del negocio: $e');
      rethrow;
    }
  }

  // Stream para escuchar cambios en tiempo real
  Stream<InformacionNegocio?> streamInformacion() {
    return _firestore
        .collection(_coleccion)
        .doc(_documentoConfig)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return null;
      }
      return InformacionNegocio.fromFirestore(doc);
    });
  }

  // Actualizar toda la información del negocio
  Future<void> actualizarInformacion(InformacionNegocio informacion) async {
    try {
      final data = informacion.toFirestore();
      data['fechaActualizacion'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(_coleccion)
          .doc(_documentoConfig)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      print('Error al actualizar información del negocio: $e');
      rethrow;
    }
  }

  // Actualizar solo la configuración
  Future<void> actualizarConfiguracion(ConfiguracionNegocio configuracion) async {
    try {
      await _firestore
          .collection(_coleccion)
          .doc(_documentoConfig)
          .update({
        'configuracion': configuracion.toMap(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error al actualizar configuración: $e');
      rethrow;
    }
  }

  // Actualizar solo la galería
  Future<void> actualizarGaleria(Galeria galeria) async {
    try {
      await _firestore
          .collection(_coleccion)
          .doc(_documentoConfig)
          .update({
        'galeria': galeria.toMap(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error al actualizar galería: $e');
      rethrow;
    }
  }

  // Actualizar solo las redes sociales
  Future<void> actualizarRedesSociales(RedesSociales redesSociales) async {
    try {
      await _firestore
          .collection(_coleccion)
          .doc(_documentoConfig)
          .update({
        'redesSociales': redesSociales.toMap(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error al actualizar redes sociales: $e');
      rethrow;
    }
  }

  // Actualizar información de contacto
  Future<void> actualizarContacto({
    String? direccion,
    String? email,
    String? whatsapp,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'fechaActualizacion': FieldValue.serverTimestamp(),
      };

      if (direccion != null) updates['direccion'] = direccion;
      if (email != null) updates['email'] = email;
      if (whatsapp != null) updates['whatsapp'] = whatsapp;

      await _firestore
          .collection(_coleccion)
          .doc(_documentoConfig)
          .update(updates);
    } catch (e) {
      print('Error al actualizar información de contacto: $e');
      rethrow;
    }
  }

  // Actualizar horarios de atención
  Future<void> actualizarHorarios(HorarioAtencion horarios) async {
    try {
      await _firestore
          .collection(_coleccion)
          .doc(_documentoConfig)
          .update({
        'galeria.horarioAtencion': horarios.toMap(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error al actualizar horarios: $e');
      rethrow;
    }
  }

  // Actualizar valores de la empresa
  Future<void> actualizarValores(List<String> valores) async {
    try {
      await _firestore
          .collection(_coleccion)
          .doc(_documentoConfig)
          .update({
        'galeria.valores': valores,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error al actualizar valores: $e');
      rethrow;
    }
  }

  // Actualizar un campo específico de configuración
  Future<void> actualizarCampoConfiguracion(String campo, dynamic valor) async {
    try {
      await _firestore
          .collection(_coleccion)
          .doc(_documentoConfig)
          .update({
        'configuracion.$campo': valor,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error al actualizar campo de configuración: $e');
      rethrow;
    }
  }

  // Actualizar estado de aceptación de pedidos
  Future<void> togglePedidosOnline(bool estado) async {
    try {
      await actualizarCampoConfiguracion('aceptaPedidosOnline', estado);
    } catch (e) {
      print('Error al cambiar estado de pedidos online: $e');
      rethrow;
    }
  }

  // Actualizar estado de aceptación de reservas
  Future<void> toggleReservas(bool estado) async {
    try {
      await actualizarCampoConfiguracion('aceptaReservas', estado);
    } catch (e) {
      print('Error al cambiar estado de reservas: $e');
      rethrow;
    }
  }

  // Verificar si existe la configuración
  Future<bool> existeConfiguracion() async {
    try {
      final doc = await _firestore
          .collection(_coleccion)
          .doc(_documentoConfig)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error al verificar existencia de configuración: $e');
      return false;
    }
  }

  // Crear configuración inicial (solo si no existe)
  Future<void> crearConfiguracionInicial() async {
    try {
      final existe = await existeConfiguracion();
      if (existe) {
        print('La configuración ya existe');
        return;
      }

      // Configuración inicial por defecto
      final configuracionInicial = InformacionNegocio(
        configuracion: ConfiguracionNegocio(
          aceptaPedidosOnline: true,
          aceptaReservas: true,
          costoEnvio: 5.0,
          iva: 0.0,
          montoMinimoEnvio: 20,
          radiusEntregaKm: 10,
          tiempoPreparacionMinimo: 24,
        ),
        direccion: '',
        email: '',
        fechaActualizacion: DateTime.now(),
        galeria: Galeria(
          historia: '',
          horarioAtencion: HorarioAtencion(
            domingo: 'Cerrado',
            lunesViernes: '8:00 AM - 6:00 PM',
            sabado: '9:00 AM - 5:00 PM',
          ),
          logo: '',
          logoSecundario: '',
          mision: '',
          nombre: 'Repostería Arlex',
          valores: ['Calidad', 'Compromiso', 'Innovación', 'Pasión', 'Servicio al cliente'],
          vision: '',
        ),
        redesSociales: RedesSociales(
          facebook: '',
          instagram: '',
          tiktok: '',
          twitter: '',
          youtube: '',
          slogan: 'Endulzando tus momentos especiales',
          telefono: '',
        ),
        whatsapp: '',
      );

      await _firestore
          .collection(_coleccion)
          .doc(_documentoConfig)
          .set(configuracionInicial.toFirestore());

      print('Configuración inicial creada exitosamente');
    } catch (e) {
      print('Error al crear configuración inicial: $e');
      rethrow;
    }
  }
}