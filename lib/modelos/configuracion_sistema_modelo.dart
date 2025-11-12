import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para gestionar qué módulos y características están visibles para los clientes
class ConfiguracionSistema {
  final String id;

  // Módulos principales
  final ModulosVisibles modulos;

  // Características específicas
  final CaracteristicasHabilitadas caracteristicas;

  // Secciones de la página de inicio
  final SeccionesInicio seccionesInicio;

  // Configuración de productos
  final ConfiguracionProductos productos;

  // Configuración de pedidos
  final ConfiguracionPedidos pedidos;

  // Última actualización
  final DateTime fechaActualizacion;

  // Usuario que realizó la última modificación
  final String? modificadoPor;

  ConfiguracionSistema({
    required this.id,
    required this.modulos,
    required this.caracteristicas,
    required this.seccionesInicio,
    required this.productos,
    required this.pedidos,
    required this.fechaActualizacion,
    this.modificadoPor,
  });

  factory ConfiguracionSistema.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Documento vacío');
    }

    return ConfiguracionSistema(
      id: doc.id,
      modulos: ModulosVisibles.fromMap(data['modulos'] ?? {}),
      caracteristicas: CaracteristicasHabilitadas.fromMap(data['caracteristicas'] ?? {}),
      seccionesInicio: SeccionesInicio.fromMap(data['seccionesInicio'] ?? {}),
      productos: ConfiguracionProductos.fromMap(data['productos'] ?? {}),
      pedidos: ConfiguracionPedidos.fromMap(data['pedidos'] ?? {}),
      fechaActualizacion: (data['fechaActualizacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      modificadoPor: data['modificadoPor'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'modulos': modulos.toMap(),
      'caracteristicas': caracteristicas.toMap(),
      'seccionesInicio': seccionesInicio.toMap(),
      'productos': productos.toMap(),
      'pedidos': pedidos.toMap(),
      'fechaActualizacion': Timestamp.fromDate(fechaActualizacion),
      if (modificadoPor != null) 'modificadoPor': modificadoPor,
    };
  }

  ConfiguracionSistema copyWith({
    String? id,
    ModulosVisibles? modulos,
    CaracteristicasHabilitadas? caracteristicas,
    SeccionesInicio? seccionesInicio,
    ConfiguracionProductos? productos,
    ConfiguracionPedidos? pedidos,
    DateTime? fechaActualizacion,
    String? modificadoPor,
  }) {
    return ConfiguracionSistema(
      id: id ?? this.id,
      modulos: modulos ?? this.modulos,
      caracteristicas: caracteristicas ?? this.caracteristicas,
      seccionesInicio: seccionesInicio ?? this.seccionesInicio,
      productos: productos ?? this.productos,
      pedidos: pedidos ?? this.pedidos,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      modificadoPor: modificadoPor ?? this.modificadoPor,
    );
  }
}

/// Configuración de módulos visibles en la aplicación
class ModulosVisibles {
  final bool catalogo;
  final bool carrito;
  final bool pedidos;
  final bool reservas;
  final bool promociones;
  final bool sobreNosotros;
  final bool contacto;
  final bool testimonios;
  final bool blog;
  final bool galeria;

  ModulosVisibles({
    this.catalogo = true,
    this.carrito = true,
    this.pedidos = true,
    this.reservas = true,
    this.promociones = true,
    this.sobreNosotros = true,
    this.contacto = true,
    this.testimonios = true,
    this.blog = false,
    this.galeria = true,
  });

  factory ModulosVisibles.fromMap(Map<String, dynamic> map) {
    return ModulosVisibles(
      catalogo: map['catalogo'] ?? true,
      carrito: map['carrito'] ?? true,
      pedidos: map['pedidos'] ?? true,
      reservas: map['reservas'] ?? true,
      promociones: map['promociones'] ?? true,
      sobreNosotros: map['sobreNosotros'] ?? true,
      contacto: map['contacto'] ?? true,
      testimonios: map['testimonios'] ?? true,
      blog: map['blog'] ?? false,
      galeria: map['galeria'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'catalogo': catalogo,
      'carrito': carrito,
      'pedidos': pedidos,
      'reservas': reservas,
      'promociones': promociones,
      'sobreNosotros': sobreNosotros,
      'contacto': contacto,
      'testimonios': testimonios,
      'blog': blog,
      'galeria': galeria,
    };
  }

  ModulosVisibles copyWith({
    bool? catalogo,
    bool? carrito,
    bool? pedidos,
    bool? reservas,
    bool? promociones,
    bool? sobreNosotros,
    bool? contacto,
    bool? testimonios,
    bool? blog,
    bool? galeria,
  }) {
    return ModulosVisibles(
      catalogo: catalogo ?? this.catalogo,
      carrito: carrito ?? this.carrito,
      pedidos: pedidos ?? this.pedidos,
      reservas: reservas ?? this.reservas,
      promociones: promociones ?? this.promociones,
      sobreNosotros: sobreNosotros ?? this.sobreNosotros,
      contacto: contacto ?? this.contacto,
      testimonios: testimonios ?? this.testimonios,
      blog: blog ?? this.blog,
      galeria: galeria ?? this.galeria,
    );
  }
}

/// Características habilitadas en el sistema
class CaracteristicasHabilitadas {
  final bool registroUsuarios;
  final bool loginRequerido;
  final bool comentariosProductos;
  final bool calificacionProductos;
  final bool compartirRedes;
  final bool newsletter;
  final bool cupones;
  final bool programaLealtad;
  final bool notificacionesPush;
  final bool chatEnVivo;

  CaracteristicasHabilitadas({
    this.registroUsuarios = true,
    this.loginRequerido = false,
    this.comentariosProductos = true,
    this.calificacionProductos = true,
    this.compartirRedes = true,
    this.newsletter = true,
    this.cupones = true,
    this.programaLealtad = false,
    this.notificacionesPush = false,
    this.chatEnVivo = false,
  });

  factory CaracteristicasHabilitadas.fromMap(Map<String, dynamic> map) {
    return CaracteristicasHabilitadas(
      registroUsuarios: map['registroUsuarios'] ?? true,
      loginRequerido: map['loginRequerido'] ?? false,
      comentariosProductos: map['comentariosProductos'] ?? true,
      calificacionProductos: map['calificacionProductos'] ?? true,
      compartirRedes: map['compartirRedes'] ?? true,
      newsletter: map['newsletter'] ?? true,
      cupones: map['cupones'] ?? true,
      programaLealtad: map['programaLealtad'] ?? false,
      notificacionesPush: map['notificacionesPush'] ?? false,
      chatEnVivo: map['chatEnVivo'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'registroUsuarios': registroUsuarios,
      'loginRequerido': loginRequerido,
      'comentariosProductos': comentariosProductos,
      'calificacionProductos': calificacionProductos,
      'compartirRedes': compartirRedes,
      'newsletter': newsletter,
      'cupones': cupones,
      'programaLealtad': programaLealtad,
      'notificacionesPush': notificacionesPush,
      'chatEnVivo': chatEnVivo,
    };
  }

  CaracteristicasHabilitadas copyWith({
    bool? registroUsuarios,
    bool? loginRequerido,
    bool? comentariosProductos,
    bool? calificacionProductos,
    bool? compartirRedes,
    bool? newsletter,
    bool? cupones,
    bool? programaLealtad,
    bool? notificacionesPush,
    bool? chatEnVivo,
  }) {
    return CaracteristicasHabilitadas(
      registroUsuarios: registroUsuarios ?? this.registroUsuarios,
      loginRequerido: loginRequerido ?? this.loginRequerido,
      comentariosProductos: comentariosProductos ?? this.comentariosProductos,
      calificacionProductos: calificacionProductos ?? this.calificacionProductos,
      compartirRedes: compartirRedes ?? this.compartirRedes,
      newsletter: newsletter ?? this.newsletter,
      cupones: cupones ?? this.cupones,
      programaLealtad: programaLealtad ?? this.programaLealtad,
      notificacionesPush: notificacionesPush ?? this.notificacionesPush,
      chatEnVivo: chatEnVivo ?? this.chatEnVivo,
    );
  }
}

/// Secciones visibles en la página de inicio
class SeccionesInicio {
  final bool bannerPrincipal;
  final bool productosDestacados;
  final bool promociones;
  final bool categorias;
  final bool testimonios;
  final bool sobreNosotros;
  final bool galeria;
  final bool blog;
  final bool newsletter;
  final bool redesSociales;

  SeccionesInicio({
    this.bannerPrincipal = true,
    this.productosDestacados = true,
    this.promociones = true,
    this.categorias = true,
    this.testimonios = true,
    this.sobreNosotros = true,
    this.galeria = true,
    this.blog = false,
    this.newsletter = true,
    this.redesSociales = true,
  });

  factory SeccionesInicio.fromMap(Map<String, dynamic> map) {
    return SeccionesInicio(
      bannerPrincipal: map['bannerPrincipal'] ?? true,
      productosDestacados: map['productosDestacados'] ?? true,
      promociones: map['promociones'] ?? true,
      categorias: map['categorias'] ?? true,
      testimonios: map['testimonios'] ?? true,
      sobreNosotros: map['sobreNosotros'] ?? true,
      galeria: map['galeria'] ?? true,
      blog: map['blog'] ?? false,
      newsletter: map['newsletter'] ?? true,
      redesSociales: map['redesSociales'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bannerPrincipal': bannerPrincipal,
      'productosDestacados': productosDestacados,
      'promociones': promociones,
      'categorias': categorias,
      'testimonios': testimonios,
      'sobreNosotros': sobreNosotros,
      'galeria': galeria,
      'blog': blog,
      'newsletter': newsletter,
      'redesSociales': redesSociales,
    };
  }

  SeccionesInicio copyWith({
    bool? bannerPrincipal,
    bool? productosDestacados,
    bool? promociones,
    bool? categorias,
    bool? testimonios,
    bool? sobreNosotros,
    bool? galeria,
    bool? blog,
    bool? newsletter,
    bool? redesSociales,
  }) {
    return SeccionesInicio(
      bannerPrincipal: bannerPrincipal ?? this.bannerPrincipal,
      productosDestacados: productosDestacados ?? this.productosDestacados,
      promociones: promociones ?? this.promociones,
      categorias: categorias ?? this.categorias,
      testimonios: testimonios ?? this.testimonios,
      sobreNosotros: sobreNosotros ?? this.sobreNosotros,
      galeria: galeria ?? this.galeria,
      blog: blog ?? this.blog,
      newsletter: newsletter ?? this.newsletter,
      redesSociales: redesSociales ?? this.redesSociales,
    );
  }
}

/// Configuración de visualización de productos
class ConfiguracionProductos {
  final bool mostrarPrecio;
  final bool mostrarDescuento;
  final bool mostrarStock;
  final bool mostrarCalificaciones;
  final bool mostrarComentarios;
  final bool permitirCompraDirecta;
  final bool mostrarProductosRelacionados;
  final bool mostrarImagenesAdicionales;

  ConfiguracionProductos({
    this.mostrarPrecio = true,
    this.mostrarDescuento = true,
    this.mostrarStock = true,
    this.mostrarCalificaciones = true,
    this.mostrarComentarios = true,
    this.permitirCompraDirecta = true,
    this.mostrarProductosRelacionados = true,
    this.mostrarImagenesAdicionales = true,
  });

  factory ConfiguracionProductos.fromMap(Map<String, dynamic> map) {
    return ConfiguracionProductos(
      mostrarPrecio: map['mostrarPrecio'] ?? true,
      mostrarDescuento: map['mostrarDescuento'] ?? true,
      mostrarStock: map['mostrarStock'] ?? true,
      mostrarCalificaciones: map['mostrarCalificaciones'] ?? true,
      mostrarComentarios: map['mostrarComentarios'] ?? true,
      permitirCompraDirecta: map['permitirCompraDirecta'] ?? true,
      mostrarProductosRelacionados: map['mostrarProductosRelacionados'] ?? true,
      mostrarImagenesAdicionales: map['mostrarImagenesAdicionales'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mostrarPrecio': mostrarPrecio,
      'mostrarDescuento': mostrarDescuento,
      'mostrarStock': mostrarStock,
      'mostrarCalificaciones': mostrarCalificaciones,
      'mostrarComentarios': mostrarComentarios,
      'permitirCompraDirecta': permitirCompraDirecta,
      'mostrarProductosRelacionados': mostrarProductosRelacionados,
      'mostrarImagenesAdicionales': mostrarImagenesAdicionales,
    };
  }

  ConfiguracionProductos copyWith({
    bool? mostrarPrecio,
    bool? mostrarDescuento,
    bool? mostrarStock,
    bool? mostrarCalificaciones,
    bool? mostrarComentarios,
    bool? permitirCompraDirecta,
    bool? mostrarProductosRelacionados,
    bool? mostrarImagenesAdicionales,
  }) {
    return ConfiguracionProductos(
      mostrarPrecio: mostrarPrecio ?? this.mostrarPrecio,
      mostrarDescuento: mostrarDescuento ?? this.mostrarDescuento,
      mostrarStock: mostrarStock ?? this.mostrarStock,
      mostrarCalificaciones: mostrarCalificaciones ?? this.mostrarCalificaciones,
      mostrarComentarios: mostrarComentarios ?? this.mostrarComentarios,
      permitirCompraDirecta: permitirCompraDirecta ?? this.permitirCompraDirecta,
      mostrarProductosRelacionados: mostrarProductosRelacionados ?? this.mostrarProductosRelacionados,
      mostrarImagenesAdicionales: mostrarImagenesAdicionales ?? this.mostrarImagenesAdicionales,
    );
  }
}

/// Configuración de pedidos y reservas
class ConfiguracionPedidos {
  final bool permitirPedidosOnline;
  final bool permitirReservas;
  final bool requerirConfirmacion;
  final bool mostrarEstadoPedido;
  final bool permitirCancelacion;
  final bool notificarCliente;
  final bool permitirPagoOnline;
  final bool permitirPagoContraentrega;

  ConfiguracionPedidos({
    this.permitirPedidosOnline = true,
    this.permitirReservas = true,
    this.requerirConfirmacion = true,
    this.mostrarEstadoPedido = true,
    this.permitirCancelacion = true,
    this.notificarCliente = true,
    this.permitirPagoOnline = false,
    this.permitirPagoContraentrega = true,
  });

  factory ConfiguracionPedidos.fromMap(Map<String, dynamic> map) {
    return ConfiguracionPedidos(
      permitirPedidosOnline: map['permitirPedidosOnline'] ?? true,
      permitirReservas: map['permitirReservas'] ?? true,
      requerirConfirmacion: map['requerirConfirmacion'] ?? true,
      mostrarEstadoPedido: map['mostrarEstadoPedido'] ?? true,
      permitirCancelacion: map['permitirCancelacion'] ?? true,
      notificarCliente: map['notificarCliente'] ?? true,
      permitirPagoOnline: map['permitirPagoOnline'] ?? false,
      permitirPagoContraentrega: map['permitirPagoContraentrega'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'permitirPedidosOnline': permitirPedidosOnline,
      'permitirReservas': permitirReservas,
      'requerirConfirmacion': requerirConfirmacion,
      'mostrarEstadoPedido': mostrarEstadoPedido,
      'permitirCancelacion': permitirCancelacion,
      'notificarCliente': notificarCliente,
      'permitirPagoOnline': permitirPagoOnline,
      'permitirPagoContraentrega': permitirPagoContraentrega,
    };
  }

  ConfiguracionPedidos copyWith({
    bool? permitirPedidosOnline,
    bool? permitirReservas,
    bool? requerirConfirmacion,
    bool? mostrarEstadoPedido,
    bool? permitirCancelacion,
    bool? notificarCliente,
    bool? permitirPagoOnline,
    bool? permitirPagoContraentrega,
  }) {
    return ConfiguracionPedidos(
      permitirPedidosOnline: permitirPedidosOnline ?? this.permitirPedidosOnline,
      permitirReservas: permitirReservas ?? this.permitirReservas,
      requerirConfirmacion: requerirConfirmacion ?? this.requerirConfirmacion,
      mostrarEstadoPedido: mostrarEstadoPedido ?? this.mostrarEstadoPedido,
      permitirCancelacion: permitirCancelacion ?? this.permitirCancelacion,
      notificarCliente: notificarCliente ?? this.notificarCliente,
      permitirPagoOnline: permitirPagoOnline ?? this.permitirPagoOnline,
      permitirPagoContraentrega: permitirPagoContraentrega ?? this.permitirPagoContraentrega,
    );
  }
}
