import 'package:flutter/material.dart';
import '../../../modelos/informacion_negocio_modelo.dart';
import '../servicios/informacion_servicio.dart';

class InformacionControlador with ChangeNotifier {
  final InformacionServicio _servicio = InformacionServicio();

  InformacionNegocio? _informacion;
  bool _isLoading = false;
  String? _error;

  InformacionNegocio? get informacion => _informacion;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Getters de acceso rápido
  ConfiguracionNegocio? get configuracion => _informacion?.configuracion;
  Galeria? get galeria => _informacion?.galeria;
  RedesSociales? get redesSociales => _informacion?.redesSociales;

  // Cargar información del negocio
  Future<void> cargarInformacion() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _informacion = await _servicio.obtenerInformacion();
      _error = null;
    } catch (e) {
      _error = 'Error al cargar la información: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Escuchar cambios en tiempo real
  Stream<InformacionNegocio?> streamInformacion() {
    return _servicio.streamInformacion();
  }

  // Actualizar toda la información
  Future<bool> actualizarInformacion(InformacionNegocio informacion) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _servicio.actualizarInformacion(informacion);
      _informacion = informacion.copyWith(fechaActualizacion: DateTime.now());
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar la información: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Actualizar configuración
  Future<bool> actualizarConfiguracion(ConfiguracionNegocio configuracion) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _servicio.actualizarConfiguracion(configuracion);
      if (_informacion != null) {
        _informacion = _informacion!.copyWith(
          configuracion: configuracion,
          fechaActualizacion: DateTime.now(),
        );
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar la configuración: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Actualizar galería
  Future<bool> actualizarGaleria(Galeria galeria) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _servicio.actualizarGaleria(galeria);
      if (_informacion != null) {
        _informacion = _informacion!.copyWith(
          galeria: galeria,
          fechaActualizacion: DateTime.now(),
        );
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar la galería: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Actualizar redes sociales
  Future<bool> actualizarRedesSociales(RedesSociales redesSociales) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _servicio.actualizarRedesSociales(redesSociales);
      if (_informacion != null) {
        _informacion = _informacion!.copyWith(
          redesSociales: redesSociales,
          fechaActualizacion: DateTime.now(),
        );
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar las redes sociales: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Actualizar información de contacto
  Future<bool> actualizarContacto({
    String? direccion,
    String? email,
    String? whatsapp,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _servicio.actualizarContacto(
        direccion: direccion,
        email: email,
        whatsapp: whatsapp,
      );

      if (_informacion != null) {
        _informacion = _informacion!.copyWith(
          direccion: direccion ?? _informacion!.direccion,
          email: email ?? _informacion!.email,
          whatsapp: whatsapp ?? _informacion!.whatsapp,
          fechaActualizacion: DateTime.now(),
        );
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar información de contacto: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Actualizar horarios
  Future<bool> actualizarHorarios(HorarioAtencion horarios) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _servicio.actualizarHorarios(horarios);
      if (_informacion != null && _informacion!.galeria != null) {
        final galeriaActualizada = _informacion!.galeria.copyWith(
          horarioAtencion: horarios,
        );
        _informacion = _informacion!.copyWith(
          galeria: galeriaActualizada,
          fechaActualizacion: DateTime.now(),
        );
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar horarios: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Actualizar valores
  Future<bool> actualizarValores(List<String> valores) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _servicio.actualizarValores(valores);
      if (_informacion != null && _informacion!.galeria != null) {
        final galeriaActualizada = _informacion!.galeria.copyWith(
          valores: valores,
        );
        _informacion = _informacion!.copyWith(
          galeria: galeriaActualizada,
          fechaActualizacion: DateTime.now(),
        );
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar valores: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle pedidos online
  Future<bool> togglePedidosOnline(bool estado) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _servicio.togglePedidosOnline(estado);
      if (_informacion != null && _informacion!.configuracion != null) {
        final configActualizada = _informacion!.configuracion.copyWith(
          aceptaPedidosOnline: estado,
        );
        _informacion = _informacion!.copyWith(
          configuracion: configActualizada,
          fechaActualizacion: DateTime.now(),
        );
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al cambiar estado de pedidos: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle reservas
  Future<bool> toggleReservas(bool estado) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _servicio.toggleReservas(estado);
      if (_informacion != null && _informacion!.configuracion != null) {
        final configActualizada = _informacion!.configuracion.copyWith(
          aceptaReservas: estado,
        );
        _informacion = _informacion!.copyWith(
          configuracion: configActualizada,
          fechaActualizacion: DateTime.now(),
        );
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al cambiar estado de reservas: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Limpiar error
  void limpiarError() {
    _error = null;
    notifyListeners();
  }
}