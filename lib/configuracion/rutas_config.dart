import 'package:flutter/material.dart';

class RutasConfig {
  // Rutas públicas
  static const String home = '/';
  static const String login = '/login';
  static const String registro = '/registro';
  static const String recuperarPassword = '/recuperar-password';
  static const String catalogo = '/catalogo';
  static const String detalleProducto = '/producto';
  static const String contacto = '/contacto';
  static const String sobreNosotros = '/sobre-nosotros';

  // Rutas de cliente autenticado
  static const String perfilCliente = '/perfil';
  static const String editarPerfil = '/perfil/editar';
  static const String cambiarPassword = '/perfil/cambiar-password';
  static const String carrito = '/carrito';
  static const String checkout = '/checkout';
  static const String confirmarPedido = '/pedido/confirmar';
  static const String misPedidos = '/mis-pedidos';
  static const String detallePedido = '/pedido';
  static const String reservas = '/reservas';
  static const String crearReserva = '/reservas/crear';

  // Rutas de administrador
  static const String adminDashboard = '/admin';
  static const String adminLogin = '/admin/login';

  // Gestión de inventario
  static const String adminInventario = '/admin/inventario';
  static const String adminAgregarProducto = '/admin/producto/agregar';
  static const String adminEditarProducto = '/admin/producto/editar';
  static const String adminCategorias = '/admin/categorias';

  // Gestión de pedidos
  static const String adminPedidos = '/admin/pedidos';
  static const String adminDetallePedido = '/admin/pedido';

  // Gestión de usuarios
  static const String adminUsuarios = '/admin/usuarios';
  static const String adminDetalleUsuario = '/admin/usuario';

  // Gestión financiera
  static const String adminFinanzas = '/admin/finanzas';
  static const String adminReportes = '/admin/reportes';

  // Gestión de promociones
  static const String adminPromociones = '/admin/promociones';
  static const String adminCrearPromocion = '/admin/promocion/crear';

  // Gestión de contenido
  static const String adminContenido = '/admin/contenido';

  // Rutas de configuración
  static const String configuracion = '/configuracion';
  static const String notificaciones = '/notificaciones';

  // Rutas de error
  static const String error404 = '/404';
  static const String errorGeneral = '/error';

  // Método para obtener todas las rutas públicas
  static List<String> get rutasPublicas => [
    home,
    login,
    registro,
    recuperarPassword,
    catalogo,
    detalleProducto,
    contacto,
    sobreNosotros,
    error404,
    errorGeneral,
  ];

  // Método para obtener rutas que requieren autenticación de cliente
  static List<String> get rutasCliente => [
    perfilCliente,
    editarPerfil,
    cambiarPassword,
    carrito,
    checkout,
    confirmarPedido,
    misPedidos,
    detallePedido,
    reservas,
    crearReserva,
    configuracion,
    notificaciones,
  ];

  // Método para obtener rutas que requieren autenticación de admin
  static List<String> get rutasAdmin => [
    adminDashboard,
    adminInventario,
    adminAgregarProducto,
    adminEditarProducto,
    adminCategorias,
    adminPedidos,
    adminDetallePedido,
    adminUsuarios,
    adminDetalleUsuario,
    adminFinanzas,
    adminReportes,
    adminPromociones,
    adminCrearPromocion,
    adminContenido,
  ];

  // Verificar si una ruta es pública
  static bool esRutaPublica(String ruta) {
    return rutasPublicas.contains(ruta);
  }

  // Verificar si una ruta requiere autenticación de cliente
  static bool requiereAuthCliente(String ruta) {
    return rutasCliente.contains(ruta);
  }

  // Verificar si una ruta requiere autenticación de admin
  static bool requiereAuthAdmin(String ruta) {
    return rutasAdmin.contains(ruta) || ruta == adminLogin;
  }

  // Obtener ruta de redirección por tipo de usuario
  static String getRutaInicial(TipoUsuario? tipoUsuario) {
    switch (tipoUsuario) {
      case TipoUsuario.admin:
        return adminDashboard;
      case TipoUsuario.cliente:
        return home;
      case null:
        return home;
    }
  }

  // Construir ruta con parámetros
  static String construirRuta(String rutaBase, Map<String, String>? parametros) {
    if (parametros == null || parametros.isEmpty) {
      return rutaBase;
    }

    String ruta = rutaBase;
    parametros.forEach((key, value) {
      ruta = ruta.replaceAll(':$key', value);
    });

    return ruta;
  }

  // Extraer parámetros de una ruta
  static Map<String, String> extraerParametros(String rutaTemplate, String rutaActual) {
    final Map<String, String> parametros = {};

    final templateSegments = rutaTemplate.split('/');
    final actualSegments = rutaActual.split('/');

    if (templateSegments.length != actualSegments.length) {
      return parametros;
    }

    for (int i = 0; i < templateSegments.length; i++) {
      final templateSegment = templateSegments[i];
      final actualSegment = actualSegments[i];

      if (templateSegment.startsWith(':')) {
        final paramName = templateSegment.substring(1);
        parametros[paramName] = actualSegment;
      }
    }

    return parametros;
  }

  // Generar breadcrumbs para una ruta
  static List<Breadcrumb> generarBreadcrumbs(String ruta) {
    final List<Breadcrumb> breadcrumbs = [];
    final segments = ruta.split('/').where((s) => s.isNotEmpty).toList();

    // Siempre empezar con "Inicio"
    breadcrumbs.add(Breadcrumb(titulo: 'Inicio', ruta: home));

    String rutaAcumulada = '';
    for (int i = 0; i < segments.length; i++) {
      rutaAcumulada += '/${segments[i]}';
      final titulo = _obtenerTituloPorSegmento(segments[i], rutaAcumulada);

      if (titulo != null) {
        breadcrumbs.add(Breadcrumb(
          titulo: titulo,
          ruta: rutaAcumulada,
          esActivo: i == segments.length - 1,
        ));
      }
    }

    return breadcrumbs;
  }

  static String? _obtenerTituloPorSegmento(String segmento, String rutaCompleta) {
    switch (segmento) {
      case 'admin':
        return 'Administración';
      case 'inventario':
        return 'Inventario';
      case 'pedidos':
        return 'Pedidos';
      case 'usuarios':
        return 'Usuarios';
      case 'finanzas':
        return 'Finanzas';
      case 'promociones':
        return 'Promociones';
      case 'contenido':
        return 'Contenido';
      case 'catalogo':
        return 'Catálogo';
      case 'carrito':
        return 'Carrito';
      case 'perfil':
        return 'Mi Perfil';
      case 'reservas':
        return 'Reservas';
      case 'contacto':
        return 'Contacto';
      case 'sobre-nosotros':
        return 'Sobre Nosotros';
      case 'agregar':
        return 'Agregar';
      case 'editar':
        return 'Editar';
      case 'crear':
        return 'Crear';
      default:
        return null;
    }
  }
}

enum TipoUsuario {
  cliente,
  admin,
}

class Breadcrumb {
  final String titulo;
  final String ruta;
  final bool esActivo;

  Breadcrumb({
    required this.titulo,
    required this.ruta,
    this.esActivo = false,
  });
}

// Extensión para facilitar la navegación
extension NavigationExtension on BuildContext {
  void navigateTo(String ruta) {
    Navigator.pushNamed(this, ruta);
  }

  void navigateToAndReplace(String ruta) {
    Navigator.pushReplacementNamed(this, ruta);
  }

  void navigateToAndClearStack(String ruta) {
    Navigator.pushNamedAndRemoveUntil(this, ruta, (route) => false);
  }

  void goBack() {
    Navigator.pop(this);
  }

  bool canGoBack() {
    return Navigator.canPop(this);
  }
}