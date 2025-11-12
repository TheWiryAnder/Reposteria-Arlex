import 'package:flutter/material.dart';
import '../modelos/configuracion_sistema_modelo.dart';
import '../servicios/configuracion_sistema_servicio.dart';

class ConfiguracionSistemaControlador with ChangeNotifier {
  final ConfiguracionSistemaServicio _servicio = ConfiguracionSistemaServicio();

  ConfiguracionSistema? _configuracion;
  bool _isLoading = false;
  String? _error;
  String? _usuarioId;

  ConfiguracionSistema? get configuracion => _configuracion;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Getters de acceso rápido
  ModulosVisibles? get modulos => _configuracion?.modulos;
  CaracteristicasHabilitadas? get caracteristicas => _configuracion?.caracteristicas;
  SeccionesInicio? get seccionesInicio => _configuracion?.seccionesInicio;
  ConfiguracionProductos? get productos => _configuracion?.productos;
  ConfiguracionPedidos? get pedidos => _configuracion?.pedidos;

  // Establecer ID de usuario actual (del admin que está modificando)
  void setUsuarioId(String usuarioId) {
    _usuarioId = usuarioId;
  }

  // Cargar configuración
  Future<void> cargarConfiguracion() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _configuracion = await _servicio.obtenerConfiguracion();
      _error = null;
    } catch (e) {
      _error = 'Error al cargar configuración: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Stream en tiempo real
  Stream<ConfiguracionSistema?> streamConfiguracion() {
    return _servicio.streamConfiguracion();
  }

  // Actualizar toda la configuración
  Future<bool> actualizarConfiguracion(ConfiguracionSistema configuracion) async {
    if (_usuarioId == null) {
      _error = 'No se ha establecido el ID de usuario';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _servicio.actualizarConfiguracion(configuracion, _usuarioId!);
      _configuracion = configuracion.copyWith(
        fechaActualizacion: DateTime.now(),
        modificadoPor: _usuarioId,
      );
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar configuración: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Actualizar módulos
  Future<bool> actualizarModulos(ModulosVisibles modulos) async {
    if (_usuarioId == null) {
      _error = 'No se ha establecido el ID de usuario';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _servicio.actualizarModulos(modulos, _usuarioId!);
      if (_configuracion != null) {
        _configuracion = _configuracion!.copyWith(
          modulos: modulos,
          fechaActualizacion: DateTime.now(),
          modificadoPor: _usuarioId,
        );
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar módulos: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Actualizar características
  Future<bool> actualizarCaracteristicas(CaracteristicasHabilitadas caracteristicas) async {
    if (_usuarioId == null) {
      _error = 'No se ha establecido el ID de usuario';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _servicio.actualizarCaracteristicas(caracteristicas, _usuarioId!);
      if (_configuracion != null) {
        _configuracion = _configuracion!.copyWith(
          caracteristicas: caracteristicas,
          fechaActualizacion: DateTime.now(),
          modificadoPor: _usuarioId,
        );
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar características: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Actualizar secciones de inicio
  Future<bool> actualizarSeccionesInicio(SeccionesInicio secciones) async {
    if (_usuarioId == null) {
      _error = 'No se ha establecido el ID de usuario';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _servicio.actualizarSeccionesInicio(secciones, _usuarioId!);
      if (_configuracion != null) {
        _configuracion = _configuracion!.copyWith(
          seccionesInicio: secciones,
          fechaActualizacion: DateTime.now(),
          modificadoPor: _usuarioId,
        );
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar secciones de inicio: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Actualizar configuración de productos
  Future<bool> actualizarConfiguracionProductos(ConfiguracionProductos productos) async {
    if (_usuarioId == null) {
      _error = 'No se ha establecido el ID de usuario';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _servicio.actualizarConfiguracionProductos(productos, _usuarioId!);
      if (_configuracion != null) {
        _configuracion = _configuracion!.copyWith(
          productos: productos,
          fechaActualizacion: DateTime.now(),
          modificadoPor: _usuarioId,
        );
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar configuración de productos: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Actualizar configuración de pedidos
  Future<bool> actualizarConfiguracionPedidos(ConfiguracionPedidos pedidos) async {
    if (_usuarioId == null) {
      _error = 'No se ha establecido el ID de usuario';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _servicio.actualizarConfiguracionPedidos(pedidos, _usuarioId!);
      if (_configuracion != null) {
        _configuracion = _configuracion!.copyWith(
          pedidos: pedidos,
          fechaActualizacion: DateTime.now(),
          modificadoPor: _usuarioId,
        );
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar configuración de pedidos: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle de módulo específico
  Future<bool> toggleModulo(String nombreModulo, bool estado) async {
    if (_usuarioId == null) {
      _error = 'No se ha establecido el ID de usuario';
      notifyListeners();
      return false;
    }

    try {
      await _servicio.toggleModulo(nombreModulo, estado, _usuarioId!);

      // Actualizar localmente
      if (_configuracion != null) {
        ModulosVisibles nuevosModulos;

        switch (nombreModulo) {
          case 'catalogo':
            nuevosModulos = _configuracion!.modulos.copyWith(catalogo: estado);
            break;
          case 'carrito':
            nuevosModulos = _configuracion!.modulos.copyWith(carrito: estado);
            break;
          case 'pedidos':
            nuevosModulos = _configuracion!.modulos.copyWith(pedidos: estado);
            break;
          case 'reservas':
            nuevosModulos = _configuracion!.modulos.copyWith(reservas: estado);
            break;
          case 'promociones':
            nuevosModulos = _configuracion!.modulos.copyWith(promociones: estado);
            break;
          case 'sobreNosotros':
            nuevosModulos = _configuracion!.modulos.copyWith(sobreNosotros: estado);
            break;
          case 'contacto':
            nuevosModulos = _configuracion!.modulos.copyWith(contacto: estado);
            break;
          case 'testimonios':
            nuevosModulos = _configuracion!.modulos.copyWith(testimonios: estado);
            break;
          case 'blog':
            nuevosModulos = _configuracion!.modulos.copyWith(blog: estado);
            break;
          case 'galeria':
            nuevosModulos = _configuracion!.modulos.copyWith(galeria: estado);
            break;
          default:
            return false;
        }

        _configuracion = _configuracion!.copyWith(modulos: nuevosModulos);
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = 'Error al cambiar estado del módulo: $e';
      notifyListeners();
      return false;
    }
  }

  // Toggle de característica específica
  Future<bool> toggleCaracteristica(String nombreCaracteristica, bool estado) async {
    if (_usuarioId == null) {
      _error = 'No se ha establecido el ID de usuario';
      notifyListeners();
      return false;
    }

    try {
      await _servicio.toggleCaracteristica(nombreCaracteristica, estado, _usuarioId!);
      await cargarConfiguracion(); // Recargar para sincronizar
      return true;
    } catch (e) {
      _error = 'Error al cambiar estado de la característica: $e';
      notifyListeners();
      return false;
    }
  }

  // Toggle de sección de inicio
  Future<bool> toggleSeccionInicio(String nombreSeccion, bool estado) async {
    if (_usuarioId == null) {
      _error = 'No se ha establecido el ID de usuario';
      notifyListeners();
      return false;
    }

    try {
      await _servicio.toggleSeccionInicio(nombreSeccion, estado, _usuarioId!);
      await cargarConfiguracion(); // Recargar para sincronizar
      return true;
    } catch (e) {
      _error = 'Error al cambiar estado de la sección: $e';
      notifyListeners();
      return false;
    }
  }

  // Restaurar configuración por defecto
  Future<bool> restaurarPorDefecto() async {
    if (_usuarioId == null) {
      _error = 'No se ha establecido el ID de usuario';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _servicio.restaurarPorDefecto(_usuarioId!);
      await cargarConfiguracion();
      _error = null;
      return true;
    } catch (e) {
      _error = 'Error al restaurar configuración por defecto: $e';
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
