import 'package:cloud_firestore/cloud_firestore.dart';

/// Script para inicializar datos en Firebase
/// Ejecutar solo UNA VEZ al configurar el proyecto por primera vez
class InitFirebaseData {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Ejecutar este método para crear todos los datos iniciales
  static Future<void> inicializarDatos() async {
    try {
      print('🚀 Iniciando creación de datos...');

      await crearCategorias();
      await crearInformacionNegocio();
      await crearProductosEjemplo();
      await crearPromocionesCarrusel();

      print('✅ Todos los datos iniciales creados exitosamente!');
    } catch (e) {
      print('❌ Error al crear datos: $e');
    }
  }

  /// Crear categorías
  static Future<void> crearCategorias() async {
    print('📁 Creando categorías...');

    final categorias = [
      {
        'id': 'cat_tortas',
        'nombre': 'Tortas',
        'descripcion': 'Deliciosas tortas para toda ocasión',
        'icono': 'cake',
        'orden': 1,
        'activa': true,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      },
      {
        'id': 'cat_galletas',
        'nombre': 'Galletas',
        'descripcion': 'Galletas artesanales crujientes',
        'icono': 'cookie',
        'orden': 2,
        'activa': true,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      },
      {
        'id': 'cat_postres',
        'nombre': 'Postres',
        'descripcion': 'Exquisitos postres caseros',
        'icono': 'emoji_food_beverage',
        'orden': 3,
        'activa': true,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      },
      {
        'id': 'cat_pasteles',
        'nombre': 'Pasteles',
        'descripcion': 'Pasteles individuales y porciones',
        'icono': 'cake_outlined',
        'orden': 4,
        'activa': true,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      },
      {
        'id': 'cat_bocaditos',
        'nombre': 'Bocaditos',
        'descripcion': 'Pequeños bocados dulces',
        'icono': 'breakfast_dining',
        'orden': 5,
        'activa': true,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      },
    ];

    for (var categoria in categorias) {
      await _firestore
          .collection('categorias')
          .doc(categoria['id'] as String)
          .set(categoria);
      print('  ✓ Categoría creada: ${categoria['nombre']}');
    }
  }

  /// Crear información del negocio
  static Future<void> crearInformacionNegocio() async {
    print('🏪 Creando información del negocio...');

    await _firestore.collection('informacion_negocio').doc('config').set({
      'nombre': 'Repostería Arlex',
      'slogan': 'Endulzando tus momentos especiales',
      'logo': '',
      'logoSecundario': '',
      'historia':
          'Repostería Arlex nace de la pasión por crear momentos dulces e inolvidables. Con más de 10 años de experiencia, nos especializamos en productos artesanales de la más alta calidad.',
      'mision':
          'Endulzar la vida de nuestros clientes con productos de repostería artesanal de la más alta calidad, elaborados con amor y dedicación.',
      'vision':
          'Ser la repostería líder en la región, reconocida por la excelencia de nuestros productos y el servicio excepcional a nuestros clientes.',
      'valores': [
        'Calidad',
        'Compromiso',
        'Innovación',
        'Pasión',
        'Servicio al cliente'
      ],
      'telefono': '+573001234567',
      'email': 'contacto@reposteriaarlex.com',
      'whatsapp': '+573001234567',
      'direccion': 'Calle 123 #45-67, Ciudad, País',
      'horarioAtencion': {
        'lunes_viernes': '8:00 AM - 6:00 PM',
        'sabado': '9:00 AM - 5:00 PM',
        'domingo': 'Cerrado',
      },
      'redesSociales': {
        'facebook': 'https://facebook.com/reposteriaarlex',
        'instagram': 'https://instagram.com/reposteriaarlex',
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
      'galeria': [],
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });

    print('  ✓ Información del negocio creada');
  }

  /// Crear productos de ejemplo
  static Future<void> crearProductosEjemplo() async {
    print('🍰 Creando productos de ejemplo...');

    final productos = [
      {
        'id': 'torta_1',
        'nombre': 'Torta de Chocolate',
        'descripcion': 'Deliciosa torta de chocolate con crema de mantequilla y decoración elegante',
        'precio': 45000.0,
        'categoria': 'cat_tortas',
        'imagenUrl': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=500',
        'stock': 10,
        'stockMinimo': 5,
        'requierePreparacion': true,
        'tiempoPreparacionHoras': 24,
        'disponible': true,
        'destacado': true,
        'peso': 1000,
        'porciones': 8,
        'ingredientes': [
          'Harina de trigo',
          'Chocolate',
          'Huevos',
          'Mantequilla',
          'Azúcar'
        ],
        'alergenos': ['Gluten', 'Huevo', 'Lácteos'],
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'totalVendidos': 45,
        'calificacionPromedio': 4.8,
        'numeroCalificaciones': 23,
      },
      {
        'id': 'torta_2',
        'nombre': 'Torta de Vainilla',
        'descripcion': 'Suave torta de vainilla decorada con fondant y flores comestibles',
        'precio': 42000.0,
        'categoria': 'cat_tortas',
        'imagenUrl': 'https://images.unsplash.com/photo-1588195538326-c5b1e5b2e6e7?w=500',
        'stock': 8,
        'stockMinimo': 5,
        'requierePreparacion': true,
        'tiempoPreparacionHoras': 24,
        'disponible': true,
        'destacado': true,
        'peso': 1000,
        'porciones': 8,
        'ingredientes': ['Harina de trigo', 'Vainilla', 'Huevos', 'Mantequilla', 'Azúcar'],
        'alergenos': ['Gluten', 'Huevo', 'Lácteos'],
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'totalVendidos': 38,
        'calificacionPromedio': 4.6,
        'numeroCalificaciones': 19,
      },
      {
        'id': 'torta_3',
        'nombre': 'Torta Red Velvet',
        'descripcion': 'Espectacular torta red velvet con queso crema y decoración premium',
        'precio': 48000.0,
        'categoria': 'cat_tortas',
        'imagenUrl': 'https://images.unsplash.com/photo-1586985289688-ca3cf47d3e6e?w=500',
        'stock': 6,
        'stockMinimo': 3,
        'requierePreparacion': true,
        'tiempoPreparacionHoras': 24,
        'disponible': true,
        'destacado': true,
        'peso': 1200,
        'porciones': 10,
        'ingredientes': ['Harina de trigo', 'Cacao', 'Queso crema', 'Huevos', 'Colorante rojo'],
        'alergenos': ['Gluten', 'Huevo', 'Lácteos'],
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'totalVendidos': 52,
        'calificacionPromedio': 4.9,
        'numeroCalificaciones': 31,
      },
      {
        'id': 'cupcake_1',
        'nombre': 'Cupcakes de Chocolate',
        'descripcion': 'Set de 6 cupcakes de chocolate con buttercream de vainilla',
        'precio': 18000.0,
        'categoria': 'cat_pasteles',
        'imagenUrl': 'https://images.unsplash.com/photo-1426869884541-df7117556757?w=500',
        'stock': 25,
        'stockMinimo': 10,
        'requierePreparacion': true,
        'tiempoPreparacionHoras': 4,
        'disponible': true,
        'destacado': true,
        'peso': 300,
        'porciones': 6,
        'ingredientes': ['Harina', 'Chocolate', 'Huevos', 'Mantequilla'],
        'alergenos': ['Gluten', 'Huevo', 'Lácteos'],
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'totalVendidos': 78,
        'calificacionPromedio': 4.7,
        'numeroCalificaciones': 42,
      },
      {
        'id': 'cupcake_2',
        'nombre': 'Cupcakes Red Velvet',
        'descripcion': 'Set de 6 cupcakes red velvet con frosting de queso crema',
        'precio': 20000.0,
        'categoria': 'cat_pasteles',
        'imagenUrl': 'https://images.unsplash.com/photo-1519869325930-281384150729?w=500',
        'stock': 20,
        'stockMinimo': 10,
        'requierePreparacion': true,
        'tiempoPreparacionHoras': 4,
        'disponible': true,
        'destacado': true,
        'peso': 300,
        'porciones': 6,
        'ingredientes': ['Harina', 'Cacao', 'Queso crema', 'Huevos'],
        'alergenos': ['Gluten', 'Huevo', 'Lácteos'],
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'totalVendidos': 65,
        'calificacionPromedio': 4.8,
        'numeroCalificaciones': 38,
      },
      {
        'id': 'galleta_1',
        'nombre': 'Galletas de Avena',
        'descripcion': 'Crujientes galletas de avena con pasas y nueces - Pack de 12 unidades',
        'precio': 12000.0,
        'categoria': 'cat_galletas',
        'imagenUrl': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=500',
        'stock': 40,
        'stockMinimo': 15,
        'requierePreparacion': false,
        'tiempoPreparacionHoras': 0,
        'disponible': true,
        'destacado': true,
        'peso': 250,
        'porciones': 12,
        'ingredientes': ['Avena', 'Harina de trigo', 'Pasas', 'Mantequilla', 'Azúcar'],
        'alergenos': ['Gluten', 'Lácteos', 'Frutos secos'],
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'totalVendidos': 125,
        'calificacionPromedio': 4.5,
        'numeroCalificaciones': 67,
      },
      {
        'id': 'galleta_2',
        'nombre': 'Galletas de Chocolate Chips',
        'descripcion': 'Deliciosas galletas con chispas de chocolate - Pack de 12 unidades',
        'precio': 13000.0,
        'categoria': 'cat_galletas',
        'imagenUrl': 'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=500',
        'stock': 35,
        'stockMinimo': 15,
        'requierePreparacion': false,
        'tiempoPreparacionHoras': 0,
        'disponible': true,
        'destacado': false,
        'peso': 250,
        'porciones': 12,
        'ingredientes': ['Harina', 'Chocolate chips', 'Mantequilla', 'Azúcar'],
        'alergenos': ['Gluten', 'Lácteos'],
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'totalVendidos': 98,
        'calificacionPromedio': 4.6,
        'numeroCalificaciones': 54,
      },
      {
        'id': 'postre_1',
        'nombre': 'Flan de Caramelo',
        'descripcion': 'Cremoso flan casero con caramelo líquido',
        'precio': 8000.0,
        'categoria': 'cat_postres',
        'imagenUrl': 'https://images.unsplash.com/photo-1624353365286-3f8d62daad51?w=500',
        'stock': 15,
        'stockMinimo': 8,
        'requierePreparacion': true,
        'tiempoPreparacionHoras': 12,
        'disponible': true,
        'destacado': false,
        'peso': 200,
        'porciones': 1,
        'ingredientes': ['Leche', 'Huevos', 'Azúcar', 'Vainilla'],
        'alergenos': ['Huevo', 'Lácteos'],
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'totalVendidos': 87,
        'calificacionPromedio': 4.4,
        'numeroCalificaciones': 45,
      },
      {
        'id': 'postre_2',
        'nombre': 'Cheesecake de Frutos Rojos',
        'descripcion': 'Exquisito cheesecake con salsa de frutos rojos',
        'precio': 15000.0,
        'categoria': 'cat_postres',
        'imagenUrl': 'https://images.unsplash.com/photo-1533134242820-b02e8c8d25fd?w=500',
        'stock': 12,
        'stockMinimo': 6,
        'requierePreparacion': true,
        'tiempoPreparacionHoras': 24,
        'disponible': true,
        'destacado': true,
        'peso': 150,
        'porciones': 1,
        'ingredientes': ['Queso crema', 'Galletas', 'Frutos rojos', 'Azúcar'],
        'alergenos': ['Gluten', 'Lácteos', 'Huevo'],
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'totalVendidos': 92,
        'calificacionPromedio': 4.9,
        'numeroCalificaciones': 51,
      },
      {
        'id': 'bocadito_1',
        'nombre': 'Brownies',
        'descripcion': 'Brownies de chocolate con nueces - Pack de 4 unidades',
        'precio': 10000.0,
        'categoria': 'cat_bocaditos',
        'imagenUrl': 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=500',
        'stock': 30,
        'stockMinimo': 12,
        'requierePreparacion': false,
        'tiempoPreparacionHoras': 0,
        'disponible': true,
        'destacado': true,
        'peso': 200,
        'porciones': 4,
        'ingredientes': ['Chocolate', 'Harina', 'Huevos', 'Nueces', 'Azúcar'],
        'alergenos': ['Gluten', 'Huevo', 'Frutos secos'],
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'totalVendidos': 145,
        'calificacionPromedio': 4.7,
        'numeroCalificaciones': 78,
      },
      {
        'id': 'bocadito_2',
        'nombre': 'Macarons Surtidos',
        'descripcion': 'Delicados macarons franceses en 6 sabores diferentes',
        'precio': 16000.0,
        'categoria': 'cat_bocaditos',
        'imagenUrl': 'https://images.unsplash.com/photo-1569864358642-9d1684040f43?w=500',
        'stock': 20,
        'stockMinimo': 8,
        'requierePreparacion': true,
        'tiempoPreparacionHoras': 6,
        'disponible': true,
        'destacado': true,
        'peso': 120,
        'porciones': 6,
        'ingredientes': ['Almendras', 'Azúcar glass', 'Claras de huevo'],
        'alergenos': ['Frutos secos', 'Huevo'],
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'totalVendidos': 73,
        'calificacionPromedio': 4.9,
        'numeroCalificaciones': 41,
      },
    ];

    for (var producto in productos) {
      await _firestore
          .collection('productos')
          .doc(producto['id'] as String)
          .set(producto);
      print('  ✓ Producto creado: ${producto['nombre']}');
    }
  }

  /// Crear promociones para el carrusel
  static Future<void> crearPromocionesCarrusel() async {
    print('🎨 Creando promociones para el carrusel...');

    final promociones = [
      {
        'id': 'promo_1',
        'titulo': 'Tortas Personalizadas',
        'descripcion': 'Creamos la torta perfecta para tu celebración especial',
        'imagenUrl': 'https://images.unsplash.com/photo-1558636508-e0db3814bd1d?w=800',
        'activa': true,
        'orden': 1,
        'tipo': 'carrusel',
        'fechaCreacion': FieldValue.serverTimestamp(),
      },
      {
        'id': 'promo_2',
        'titulo': 'Cupcakes Artesanales',
        'descripcion': 'Deliciosos cupcakes hechos con los mejores ingredientes',
        'imagenUrl': 'https://images.unsplash.com/photo-1426869884541-df7117556757?w=800',
        'activa': true,
        'orden': 2,
        'tipo': 'carrusel',
        'fechaCreacion': FieldValue.serverTimestamp(),
      },
      {
        'id': 'promo_3',
        'titulo': 'Postres del Día',
        'descripcion': 'Frescos y deliciosos postres preparados diariamente',
        'imagenUrl': 'https://images.unsplash.com/photo-1464347744102-11db6282f854?w=800',
        'activa': true,
        'orden': 3,
        'tipo': 'carrusel',
        'fechaCreacion': FieldValue.serverTimestamp(),
      },
    ];

    for (var promo in promociones) {
      await _firestore
          .collection('promociones')
          .doc(promo['id'] as String)
          .set(promo);
      print('  ✓ Promoción creada: ${promo['titulo']}');
    }
  }

  /// Verificar si ya existen datos
  static Future<bool> yaTieneDatos() async {
    final categoriasSnapshot =
        await _firestore.collection('categorias').limit(1).get();
    return categoriasSnapshot.docs.isNotEmpty;
  }
}
