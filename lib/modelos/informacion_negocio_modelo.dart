import 'package:cloud_firestore/cloud_firestore.dart';

class ConfiguracionNegocio {
  final bool aceptaPedidosOnline;
  final bool aceptaReservas;
  final double costoEnvio;
  final double iva;
  final int montoMinimoEnvio;
  final int radiusEntregaKm;
  final int tiempoPreparacionMinimo;

  ConfiguracionNegocio({
    required this.aceptaPedidosOnline,
    required this.aceptaReservas,
    required this.costoEnvio,
    required this.iva,
    required this.montoMinimoEnvio,
    required this.radiusEntregaKm,
    required this.tiempoPreparacionMinimo,
  });

  factory ConfiguracionNegocio.fromMap(Map<String, dynamic> map) {
    return ConfiguracionNegocio(
      aceptaPedidosOnline: map['aceptaPedidosOnline'] ?? false,
      aceptaReservas: map['aceptaReservas'] ?? false,
      costoEnvio: (map['costoEnvio'] ?? 0).toDouble(),
      iva: (map['iva'] ?? 0).toDouble(),
      montoMinimoEnvio: map['montoMinimoEnvio'] ?? 0,
      radiusEntregaKm: map['radiusEntregaKm'] ?? 10,
      tiempoPreparacionMinimo: map['tiempoPreparacionMinimo'] ?? 24,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'aceptaPedidosOnline': aceptaPedidosOnline,
      'aceptaReservas': aceptaReservas,
      'costoEnvio': costoEnvio,
      'iva': iva,
      'montoMinimoEnvio': montoMinimoEnvio,
      'radiusEntregaKm': radiusEntregaKm,
      'tiempoPreparacionMinimo': tiempoPreparacionMinimo,
    };
  }

  ConfiguracionNegocio copyWith({
    bool? aceptaPedidosOnline,
    bool? aceptaReservas,
    double? costoEnvio,
    double? iva,
    int? montoMinimoEnvio,
    int? radiusEntregaKm,
    int? tiempoPreparacionMinimo,
  }) {
    return ConfiguracionNegocio(
      aceptaPedidosOnline: aceptaPedidosOnline ?? this.aceptaPedidosOnline,
      aceptaReservas: aceptaReservas ?? this.aceptaReservas,
      costoEnvio: costoEnvio ?? this.costoEnvio,
      iva: iva ?? this.iva,
      montoMinimoEnvio: montoMinimoEnvio ?? this.montoMinimoEnvio,
      radiusEntregaKm: radiusEntregaKm ?? this.radiusEntregaKm,
      tiempoPreparacionMinimo: tiempoPreparacionMinimo ?? this.tiempoPreparacionMinimo,
    );
  }
}

class HorarioAtencion {
  final String domingo;
  final String lunesViernes;
  final String sabado;

  HorarioAtencion({
    required this.domingo,
    required this.lunesViernes,
    required this.sabado,
  });

  factory HorarioAtencion.fromMap(Map<String, dynamic> map) {
    return HorarioAtencion(
      domingo: map['domingo'] ?? 'Cerrado',
      lunesViernes: map['lunes_viernes'] ?? 'Lunes a Viernes: 8:00 AM - 6:00 PM',
      sabado: map['sabado'] ?? 'Sábado: 9:00 AM - 2:00 PM',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'domingo': domingo,
      'lunes_viernes': lunesViernes,
      'sabado': sabado,
    };
  }

  HorarioAtencion copyWith({
    String? domingo,
    String? lunesViernes,
    String? sabado,
  }) {
    return HorarioAtencion(
      domingo: domingo ?? this.domingo,
      lunesViernes: lunesViernes ?? this.lunesViernes,
      sabado: sabado ?? this.sabado,
    );
  }
}

class Galeria {
  final String historia;
  final String? historiaImagenUrl;
  final HorarioAtencion horarioAtencion;
  final String logo;
  final String logoSecundario;
  final String mision;
  final String? misionImagenUrl;
  final String nombre;
  final List<String> valores;
  final String vision;
  final String? visionImagenUrl;

  Galeria({
    required this.historia,
    this.historiaImagenUrl,
    required this.horarioAtencion,
    required this.logo,
    required this.logoSecundario,
    required this.mision,
    this.misionImagenUrl,
    required this.nombre,
    required this.valores,
    required this.vision,
    this.visionImagenUrl,
  });

  factory Galeria.fromMap(Map<String, dynamic> map) {
    return Galeria(
      historia: map['historia'] ?? 'Repostería Arlex nace de la pasión por crear momentos dulces e inolvidables. Con más de 10 años de experiencia, nos especializamos en productos artesanales de la más alta calidad.',
      historiaImagenUrl: map['historiaImagenUrl'],
      horarioAtencion: HorarioAtencion.fromMap(map['horarioAtencion'] ?? {}),
      logo: map['logo'] ?? 'https://i.imgur.com/NwgQZo6.jpeg',
      logoSecundario: map['logoSecundario'] ?? '',
      mision: map['mision'] ?? 'Endulzar la vida de nuestros clientes con productos de repostería artesanal de la más alta calidad, elaborados con amor y dedicación.',
      misionImagenUrl: map['misionImagenUrl'],
      nombre: map['nombre'] ?? 'Repostería Arlex',
      valores: List<String>.from(map['valores'] ?? []),
      vision: map['vision'] ?? 'Ser la repostería líder en la región, reconocida por la excelencia de nuestros productos y el servicio excepcional a nuestros clientes.',
      visionImagenUrl: map['visionImagenUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'historia': historia,
      'historiaImagenUrl': historiaImagenUrl,
      'horarioAtencion': horarioAtencion.toMap(),
      'logo': logo,
      'logoSecundario': logoSecundario,
      'mision': mision,
      'misionImagenUrl': misionImagenUrl,
      'nombre': nombre,
      'valores': valores,
      'vision': vision,
      'visionImagenUrl': visionImagenUrl,
    };
  }

  Galeria copyWith({
    String? historia,
    String? historiaImagenUrl,
    HorarioAtencion? horarioAtencion,
    String? logo,
    String? logoSecundario,
    String? mision,
    String? misionImagenUrl,
    String? nombre,
    List<String>? valores,
    String? vision,
    String? visionImagenUrl,
  }) {
    return Galeria(
      historia: historia ?? this.historia,
      historiaImagenUrl: historiaImagenUrl ?? this.historiaImagenUrl,
      horarioAtencion: horarioAtencion ?? this.horarioAtencion,
      logo: logo ?? this.logo,
      logoSecundario: logoSecundario ?? this.logoSecundario,
      mision: mision ?? this.mision,
      misionImagenUrl: misionImagenUrl ?? this.misionImagenUrl,
      nombre: nombre ?? this.nombre,
      valores: valores ?? this.valores,
      vision: vision ?? this.vision,
      visionImagenUrl: visionImagenUrl ?? this.visionImagenUrl,
    );
  }
}

class BannerPrincipal {
  final String titulo;
  final String subtitulo;
  final String? imagenUrl;
  final double altura;
  final bool activo;

  BannerPrincipal({
    required this.titulo,
    required this.subtitulo,
    this.imagenUrl,
    this.altura = 200,
    this.activo = true,
  });

  factory BannerPrincipal.fromMap(Map<String, dynamic> map) {
    return BannerPrincipal(
      titulo: map['titulo'] ?? 'Bienvenido a Repostería Arlex',
      subtitulo: map['subtitulo'] ?? 'Descubre nuestros productos artesanales',
      imagenUrl: map['imagenUrl'],
      altura: (map['altura'] ?? 200).toDouble(),
      activo: map['activo'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'subtitulo': subtitulo,
      'imagenUrl': imagenUrl,
      'altura': altura,
      'activo': activo,
    };
  }

  BannerPrincipal copyWith({
    String? titulo,
    String? subtitulo,
    String? imagenUrl,
    double? altura,
    bool? activo,
  }) {
    return BannerPrincipal(
      titulo: titulo ?? this.titulo,
      subtitulo: subtitulo ?? this.subtitulo,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      altura: altura ?? this.altura,
      activo: activo ?? this.activo,
    );
  }
}

class RedesSociales {
  final String facebook;
  final String instagram;
  final String tiktok;
  final String twitter;
  final String youtube;
  final String slogan;
  final String telefono;

  RedesSociales({
    required this.facebook,
    required this.instagram,
    required this.tiktok,
    required this.twitter,
    required this.youtube,
    required this.slogan,
    required this.telefono,
  });

  factory RedesSociales.fromMap(Map<String, dynamic> map) {
    return RedesSociales(
      facebook: map['facebook'] ?? 'https://facebook.com/reposteriaarlex',
      instagram: map['instagram'] ?? 'https://instagram.com/reposteriaarlex',
      tiktok: map['tiktok'] ?? '',
      twitter: map['twitter'] ?? '',
      youtube: map['youtube'] ?? '',
      slogan: map['slogan'] ?? 'Endulzando tus momentos especiales',
      telefono: map['telefono'] ?? '+51 920 258 777',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'facebook': facebook,
      'instagram': instagram,
      'tiktok': tiktok,
      'twitter': twitter,
      'youtube': youtube,
      'slogan': slogan,
      'telefono': telefono,
    };
  }

  RedesSociales copyWith({
    String? facebook,
    String? instagram,
    String? tiktok,
    String? twitter,
    String? youtube,
    String? slogan,
    String? telefono,
  }) {
    return RedesSociales(
      facebook: facebook ?? this.facebook,
      instagram: instagram ?? this.instagram,
      tiktok: tiktok ?? this.tiktok,
      twitter: twitter ?? this.twitter,
      youtube: youtube ?? this.youtube,
      slogan: slogan ?? this.slogan,
      telefono: telefono ?? this.telefono,
    );
  }
}

class InformacionNegocio {
  final ConfiguracionNegocio configuracion;
  final String direccion;
  final String email;
  final DateTime fechaActualizacion;
  final Galeria galeria;
  final RedesSociales redesSociales;
  final String whatsapp;
  final BannerPrincipal bannerPrincipal;
  final String? ubicacionMapsUrl;

  InformacionNegocio({
    required this.configuracion,
    required this.direccion,
    required this.email,
    required this.fechaActualizacion,
    required this.galeria,
    required this.redesSociales,
    required this.whatsapp,
    required this.bannerPrincipal,
    this.ubicacionMapsUrl,
  });

  factory InformacionNegocio.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Documento vacío');
    }
    return InformacionNegocio.fromMap(data);
  }

  factory InformacionNegocio.fromMap(Map<String, dynamic> map) {
    return InformacionNegocio(
      configuracion: ConfiguracionNegocio.fromMap(map['configuracion'] ?? {}),
      direccion: map['direccion'] ?? 'Calle 123 #45-67, Ciudad, País',
      email: map['email'] ?? 'contacto@reposteriaarlex.com',
      fechaActualizacion: (map['fechaActualizacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      galeria: Galeria.fromMap(map['galeria'] ?? {}),
      redesSociales: RedesSociales.fromMap(map['redesSociales'] ?? {}),
      whatsapp: map['whatsapp'] ?? '+51 920 258 777',
      bannerPrincipal: BannerPrincipal.fromMap(map['bannerPrincipal'] ?? {}),
      ubicacionMapsUrl: map['ubicacionMapsUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'configuracion': configuracion.toMap(),
      'direccion': direccion,
      'email': email,
      'fechaActualizacion': Timestamp.fromDate(fechaActualizacion),
      'galeria': galeria.toMap(),
      'redesSociales': redesSociales.toMap(),
      'whatsapp': whatsapp,
      'bannerPrincipal': bannerPrincipal.toMap(),
      'ubicacionMapsUrl': ubicacionMapsUrl,
    };
  }

  InformacionNegocio copyWith({
    ConfiguracionNegocio? configuracion,
    String? direccion,
    String? email,
    DateTime? fechaActualizacion,
    Galeria? galeria,
    RedesSociales? redesSociales,
    String? whatsapp,
    BannerPrincipal? bannerPrincipal,
    String? ubicacionMapsUrl,
  }) {
    return InformacionNegocio(
      configuracion: configuracion ?? this.configuracion,
      direccion: direccion ?? this.direccion,
      email: email ?? this.email,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      galeria: galeria ?? this.galeria,
      redesSociales: redesSociales ?? this.redesSociales,
      whatsapp: whatsapp ?? this.whatsapp,
      bannerPrincipal: bannerPrincipal ?? this.bannerPrincipal,
      ubicacionMapsUrl: ubicacionMapsUrl ?? this.ubicacionMapsUrl,
    );
  }
}