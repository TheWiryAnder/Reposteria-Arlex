import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:universal_html/html.dart' as html;
import '../../providers/auth_provider_simple.dart';
import '../../main.dart'; // For InformacionNegocioProvider
import '../../compartidos/widgets/message_helpers.dart';
import '../auth/login_vista.dart';
import '../../servicios/productos_service.dart';
import '../../servicios/promociones_service.dart';
import '../../servicios/actividades_service.dart';
import '../../servicios/reporte_excel_service.dart';
import '../../servicios/reporte_pdf_service.dart';
import '../../modelos/producto_modelo.dart';
import 'actividades_screen.dart';
import '../gestion/product_management_firebase_screen.dart';
import '../gestion/order_management_screen.dart';
import '../gestion/category_management_screen.dart';
import '../gestion/promotion_management_screen.dart';
import '../gestion/reports_analytics_screen.dart';
import 'editar_banner_screen.dart';
import 'configuracion_negocio_completa_screen.dart';
import 'widgets/resenas_section.dart';
import 'widgets/sales_charts.dart';
import 'widgets/promociones_modal.dart';
import 'widgets/product_card_with_discount.dart';
import 'widgets/recommended_product_card.dart';
import 'widgets/carousel_section.dart';
import 'widgets/quick_actions_section.dart';
import 'widgets/welcome_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

  // GlobalKey estático para acceder al estado desde fuera
  static final GlobalKey<_HomeScreenState> homeScreenKey = GlobalKey<_HomeScreenState>();
}

// Variable estática para controlar si el modal ya se mostró en esta sesión
bool _modalPromocionesYaMostradoEnSesion = false;

class _HomeScreenState extends State<HomeScreen> {
  final PromocionesService _promocionesService = PromocionesService();
  final ProductosService _productosService = ProductosService();
  final ActividadesService _actividadesService = ActividadesService();

  // Variables para filtros de estadísticas
  String _currentDateFilter = '30_days';
  String _currentCategoryFilter = 'all';

  final ScrollController _scrollController = ScrollController();

  // Método para hacer scroll al inicio de la página
  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Desactivar promociones vencidas al cargar la página
    _desactivarPromocionesVencidas();
    // Mostrar modal de promociones después de que se construya el widget
    _verificarYMostrarModalPromociones();
  }

  /// Verificar si debe mostrarse el modal de promociones
  Future<void> _verificarYMostrarModalPromociones() async {
    // Esperar a que se construya el widget
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _modalPromocionesYaMostradoEnSesion) return;

      try {
        // Obtener promociones activas
        final ahora = DateTime.now();
        final snapshot = await FirebaseFirestore.instance
            .collection('promociones')
            .where('activa', isEqualTo: true)
            .get();

        // Filtrar promociones vigentes
        final promocionesVigentes = snapshot.docs.where((doc) {
          final data = doc.data();
          final fechaInicio = (data['fechaInicio'] as Timestamp?)?.toDate();
          final fechaFin = (data['fechaFin'] as Timestamp?)?.toDate();

          if (fechaInicio == null || fechaFin == null) return false;

          return ahora.isAfter(fechaInicio) && ahora.isBefore(fechaFin);
        }).toList();

        if (promocionesVigentes.isNotEmpty && mounted) {
          _modalPromocionesYaMostradoEnSesion = true;

          // Mostrar modal con un pequeño delay para mejor UX
          await Future.delayed(const Duration(milliseconds: 1000));

          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (context) => PromocionesModal(promociones: promocionesVigentes),
            );
          }
        }
      } catch (e) {
        // Error silencioso para no interrumpir la experiencia del usuario
      }
    });
  }

  /// Método para desactivar automáticamente promociones que hayan pasado su fecha fin
  Future<void> _desactivarPromocionesVencidas() async {
    try {
      final ahora = DateTime.now();
      final ahoraSinHora = DateTime(ahora.year, ahora.month, ahora.day);

      // Obtener todas las promociones activas
      final snapshot = await FirebaseFirestore.instance
          .collection('promociones')
          .where('activa', isEqualTo: true)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final fechaFin = (data['fechaFin'] as Timestamp?)?.toDate();

        if (fechaFin != null) {
          final finSinHora = DateTime(fechaFin.year, fechaFin.month, fechaFin.day, 23, 59, 59);

          // Si la fecha actual es posterior a la fecha fin, desactivar
          if (ahoraSinHora.isAfter(finSinHora)) {
            await FirebaseFirestore.instance
                .collection('promociones')
                .doc(doc.id)
                .update({
              'activa': false,
              'fechaActualizacion': FieldValue.serverTimestamp(),
            });

            print('✅ Promoción "${data['titulo']}" desactivada automáticamente');
          }
        }
      }
    } catch (e) {
      print('Error al desactivar promociones vencidas: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthProvider.instance,
      builder: (context, child) {
        final authProvider = AuthProvider.instance;
        final currentUser = authProvider.currentUser;
        final userRole = currentUser?.rol ?? 'cliente';

        // Para clientes y usuarios sin sesión, mostrar la estructura del modelo HTML
        if (userRole == 'cliente' || authProvider.authState != AuthState.authenticated) {
          return _buildClientHomeScreen();
        }

        // Para admin y empleados, estructura mejorada
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(currentUser),
              const SizedBox(height: 24),
              _buildCarouselSection(),
              const SizedBox(height: 24),
              _buildEnhancedStatsSection(userRole),
              const SizedBox(height: 24),
              _buildQuickActionsSection(),
              const SizedBox(height: 24),
              _buildRecentOrdersSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClientHomeScreen() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          _buildPromotionalBanner(),
          const SizedBox(height: 32),
          _buildPromocionesSection(),
          const SizedBox(height: 32),
          _buildTopSellingProductsSection(),
          const SizedBox(height: 32),
          _buildResenasSection(),
          const SizedBox(height: 32),
          _buildContactSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildResenasSection() {
    return const ResenasSection();
  }

  Widget _buildContactSection() {
    return ListenableBuilder(
      listenable: InformacionNegocioProvider.instance,
      builder: (context, child) {
        final provider = InformacionNegocioProvider.instance;

        if (provider.cargando) {
          return const SizedBox.shrink();
        }

        final info = provider.info;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 800;

                if (isMobile) {
                  // Vista móvil: columnas verticales
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información de contacto
                      _buildContactInfo(info),
                      const SizedBox(height: 24),
                      // Mensaje de copyright
                      _buildCopyright(),
                      const SizedBox(height: 24),
                      // Redes sociales
                      _buildSocialMedia(info),
                    ],
                  );
                }

                // Vista escritorio: 3 columnas
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Columna izquierda: Información de contacto
                    Expanded(
                      flex: 2,
                      child: _buildContactInfo(info),
                    ),
                    const SizedBox(width: 32),
                    // Columna central: Copyright/Mensaje
                    Expanded(
                      flex: 2,
                      child: _buildCopyright(),
                    ),
                    const SizedBox(width: 32),
                    // Columna derecha: Redes sociales
                    Expanded(
                      flex: 1,
                      child: _buildSocialMedia(info),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Sección de información de contacto
  Widget _buildContactInfo(info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contáctanos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildContactInfoRow(Icons.location_on, info.direccion),
        const SizedBox(height: 8),
        _buildContactInfoRow(Icons.phone, info.redesSociales.telefono),
        const SizedBox(height: 8),
        _buildContactInfoRow(Icons.email, info.email),
        const SizedBox(height: 8),
        _buildContactInfoRow(Icons.access_time,
          '${info.galeria.horarioAtencion.lunesViernes}\n${info.galeria.horarioAtencion.sabado}\n${info.galeria.horarioAtencion.domingo}'),
      ],
    );
  }

  // Sección de copyright/mensaje
  Widget _buildCopyright() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acerca de',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Hecho con ❤️ por el equipo de Repostería Arlex',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '© ${DateTime.now().year} Repostería Arlex. Todos los derechos reservados.',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Libre de uso con atribución.',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  // Sección de redes sociales en lista vertical
  Widget _buildSocialMedia(info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Síguenos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildSocialListItem(
          Icons.facebook,
          'Facebook',
          info.redesSociales.facebook,
        ),
        const SizedBox(height: 12),
        _buildSocialListItem(
          Icons.camera_alt,
          'Instagram',
          info.redesSociales.instagram,
        ),
        const SizedBox(height: 12),
        _buildSocialListItem(
          Icons.chat_bubble,
          'WhatsApp',
          info.whatsapp.isNotEmpty
            ? 'https://wa.me/${info.whatsapp.replaceAll(RegExp(r'[^\d+]'), '')}'
            : '',
        ),
      ],
    );
  }

  // Item de red social en lista
  Widget _buildSocialListItem(IconData icono, String nombre, String url) {
    return InkWell(
      onTap: url.isNotEmpty ? () => _abrirEnlace(url) : null,
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: url.isEmpty ? 0.5 : 1.0,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icono, color: const Color(0xFFB8956C), size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              nombre,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoRow(IconData icono, String texto) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }

  // Método para abrir enlaces externos
  Future<void> _abrirEnlace(String url) async {
    if (url.isEmpty) return;

    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          showAppMessage(
            context,
            'No se pudo abrir el enlace: $url',
            type: MessageType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showAppMessage(
          context,
          'Error al abrir el enlace: $e',
          type: MessageType.error,
        );
      }
    }
  }

  Widget _buildWelcomeSection(UsuarioModelo? user) {
    return WelcomeSection(userName: user?.nombre);
  }

  Widget _buildCarouselSection() {
    return const CarouselSection();
  }

  Widget _buildQuickActionsSection() {
    final authProvider = AuthProvider.instance;
    final userRole = authProvider.currentUser?.rol ?? 'cliente';
    final actions = _getQuickActionsForRole(userRole);

    return QuickActionsSection(actions: actions);
  }

  List<QuickAction> _getQuickActionsForRole(String role) {
    switch (role) {
      case 'admin':
        return [
          QuickAction(
            title: 'Gestión de Productos',
            icon: Icons.inventory,
            color: Colors.blue,
            onTap: () => _navigateToAdminModule('products'),
          ),
          QuickAction(
            title: 'Gestión de Categorías',
            icon: Icons.category,
            color: Colors.teal,
            onTap: () => _navigateToAdminModule('categories'),
          ),
          QuickAction(
            title: 'Gestión de Pedidos',
            icon: Icons.assignment,
            color: Colors.green,
            onTap: () => _navigateToAdminModule('orders'),
          ),
          QuickAction(
            title: 'Gestión de Promociones',
            icon: Icons.local_offer,
            color: Colors.purple,
            onTap: () => _navigateToAdminModule('promotions'),
          ),
          QuickAction(
            title: 'Reportes y Analytics',
            icon: Icons.analytics,
            color: Colors.orange,
            onTap: () => _navigateToAdminModule('reports'),
          ),
          QuickAction(
            title: 'Editar Banner',
            icon: Icons.image,
            color: Colors.pink,
            onTap: () => _navigateToAdminModule('banner'),
          ),
          QuickAction(
            title: 'Configuración',
            icon: Icons.settings,
            color: Colors.grey,
            onTap: () => _navigateToAdminModule('settings'),
          ),
          QuickAction(
            title: 'Descargar Reporte Excel',
            icon: Icons.download,
            color: Colors.red,
            onTap: () => _descargarReporteExcel(),
          ),
          QuickAction(
            title: 'Descargar Reporte PDF',
            icon: Icons.picture_as_pdf,
            color: Colors.deepOrange,
            onTap: () => _descargarReportePdf(),
          ),
        ];

      case 'empleado':
        return [
          QuickAction(
            title: 'Pedidos Pendientes',
            icon: Icons.pending_actions,
            color: Colors.orange,
            onTap: () => _navigateToEmployeeModule('pending_orders'),
          ),
          QuickAction(
            title: 'Producción',
            icon: Icons.construction,
            color: Colors.blue,
            onTap: () => _navigateToEmployeeModule('production'),
          ),
          QuickAction(
            title: 'Mi Perfil',
            icon: Icons.person,
            color: Colors.purple,
            onTap: () => _navigateToTab(3),
          ),
        ];

      default: // cliente
        return [
          QuickAction(
            title: 'Ver Productos',
            icon: Icons.cake,
            color: Colors.orange,
            onTap: () => _navigateToTab(1),
          ),
          QuickAction(
            title: 'Mis Pedidos',
            icon: Icons.shopping_bag,
            color: Colors.blue,
            onTap: () => _navigateToTab(2),
          ),
          QuickAction(
            title: 'Hacer Pedido',
            icon: Icons.add_shopping_cart,
            color: Colors.green,
            onTap: () => _navigateToTab(1),
          ),
          QuickAction(
            title: 'Mi Perfil',
            icon: Icons.person,
            color: Colors.purple,
            onTap: () => _navigateToTab(3),
          ),
        ];
    }
  }

  Widget _buildStatsSection() {
    final authProvider = AuthProvider.instance;
    final userRole = authProvider.currentUser?.rol ?? 'cliente';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estadísticas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _getStatsForRole(userRole),
        ],
      ),
    );
  }

  Widget _buildAdminStats() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);

    return FutureBuilder<List<QuerySnapshot>>(
      future: Future.wait([
        // Pedidos de hoy
        FirebaseFirestore.instance
            .collection('pedidos')
            .where('fechaPedido', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .get(),
        // Todos los pedidos activos (pendiente, confirmado, en preparación)
        FirebaseFirestore.instance
            .collection('pedidos')
            .where('estado', whereIn: ['pendiente', 'confirmado', 'en preparacion'])
            .get(),
        // Usuarios
        FirebaseFirestore.instance.collection('usuarios').get(),
        // Productos
        FirebaseFirestore.instance.collection('productos').get(),
        // Pedidos del mes
        FirebaseFirestore.instance
            .collection('pedidos')
            .where('fechaPedido', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
            .get(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Calcular estadísticas
        double ventasHoy = 0;
        int pedidosActivos = 0;
        int usuariosActivos = 0;
        int totalProductos = 0;
        double ingresosMes = 0;
        int alertas = 0;

        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!;

          // Ventas de hoy
          for (var doc in data[0].docs) {
            final pedidoData = doc.data() as Map<String, dynamic>;
            ventasHoy += (pedidoData['total'] ?? 0).toDouble();
          }

          // Pedidos activos
          pedidosActivos = data[1].docs.length;

          // Usuarios activos
          usuariosActivos = data[2].docs.length;

          // Total de productos
          totalProductos = data[3].docs.length;

          // Productos con stock bajo (alertas)
          for (var doc in data[3].docs) {
            final producto = doc.data() as Map<String, dynamic>;
            final stock = producto['stock'] ?? 0;
            if (stock < 10) alertas++;
          }

          // Ingresos del mes
          for (var doc in data[4].docs) {
            final pedidoData = doc.data() as Map<String, dynamic>;
            ingresosMes += (pedidoData['total'] ?? 0).toDouble();
          }
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Ventas Hoy',
                    'S/. ${ventasHoy.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Pedidos Activos',
                    pedidosActivos.toString(),
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Usuarios Activos',
                    usuariosActivos.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Productos',
                    totalProductos.toString(),
                    Icons.inventory,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Ingresos Mes',
                    'S/. ${ingresosMes.toStringAsFixed(2)}',
                    Icons.trending_up,
                    Colors.indigo,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Alertas',
                    alertas.toString(),
                    Icons.warning,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _getStatsForRole(String role) {
    switch (role) {
      case 'admin':
        return _buildAdminStats();

      case 'empleado':
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Tareas Hoy',
                '8',
                Icons.task_alt,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Completadas',
                '5',
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Pendientes',
                '3',
                Icons.pending,
                Colors.orange,
              ),
            ),
          ],
        );

      default: // cliente
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Pedidos',
                '12',
                Icons.shopping_cart,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Favoritos',
                '8',
                Icons.favorite,
                Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard('Puntos', '250', Icons.star, Colors.amber),
            ),
          ],
        );
    }
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersSection() {
    final authProvider = AuthProvider.instance;
    final userRole = authProvider.currentUser?.rol ?? 'cliente';

    // Solo mostrar actividades reales para admin
    if (userRole == 'admin') {
      return _buildAdminActivitiesSection();
    }

    // Para otros roles, mantener la vista anterior
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getSectionTitleForRole(userRole),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => _navigateToRelevantSection(userRole),
                child: const Text('Ver todos'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Column(children: _getRecentItemsForRole(userRole)),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActivitiesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Actividad Reciente',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ActividadesScreen(),
                    ),
                  );
                },
                child: const Text('Ver todas'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _actividadesService.obtenerActividadesRecientes(limit: 5),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }

              // Silenciar errores temporales de Firestore
              if (snapshot.hasError) {
                if (snapshot.error.toString().contains('PERMISSION_DENIED') ||
                    snapshot.error.toString().contains('UNAVAILABLE')) {
                  debugPrint('Error temporal en Firestore (actividades): ${snapshot.error}');
                }
              }

              // Tratar errores (como colección no existente) como sin actividades
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No hay actividades aún',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Las actividades del sistema aparecerán aquí',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final actividades = snapshot.data!.docs;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: List.generate(
                    actividades.length * 2 - 1,
                    (index) {
                      if (index.isOdd) {
                        return const Divider(height: 1);
                      }
                      final actividadIndex = index ~/ 2;
                      final actividad = actividades[actividadIndex].data()
                          as Map<String, dynamic>;
                      return _buildActividadItem(actividad);
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActividadItem(Map<String, dynamic> actividad) {
    final tipo = actividad['tipo'] ?? '';
    final descripcion = actividad['descripcion'] ?? '';
    final usuarioNombre = actividad['usuarioNombre'] ?? 'Usuario';
    final fecha = actividad['fecha'] as Timestamp?;

    final iconData = _getActividadIcon(tipo);
    final color = _getActividadColor(tipo);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(iconData, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  descripcion,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  usuarioNombre,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          if (fecha != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatearTiempoActividad(fecha),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getActividadIcon(String tipo) {
    switch (tipo) {
      case 'pedido':
        return Icons.shopping_bag;
      case 'registro':
        return Icons.person_add;
      case 'credenciales':
        return Icons.lock_reset;
      case 'notificacion':
        return Icons.notifications_active;
      default:
        return Icons.info_outline;
    }
  }

  Color _getActividadColor(String tipo) {
    switch (tipo) {
      case 'pedido':
        return Colors.green;
      case 'registro':
        return Colors.blue;
      case 'credenciales':
        return Colors.orange;
      case 'notificacion':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatearTiempoActividad(Timestamp timestamp) {
    final fecha = timestamp.toDate();
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inMinutes < 1) {
      return 'Ahora';
    } else if (diferencia.inHours < 1) {
      return '${diferencia.inMinutes}m';
    } else if (diferencia.inDays < 1) {
      return '${diferencia.inHours}h';
    } else if (diferencia.inDays < 7) {
      return '${diferencia.inDays}d';
    } else {
      return '${fecha.day}/${fecha.month}';
    }
  }

  String _getSectionTitleForRole(String role) {
    switch (role) {
      case 'admin':
        return 'Actividad Reciente';
      case 'empleado':
        return 'Tareas Recientes';
      default:
        return 'Pedidos Recientes';
    }
  }

  void _navigateToRelevantSection(String role) {
    switch (role) {
      case 'admin':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ActividadesScreen(),
          ),
        );
        break;
      case 'empleado':
        _navigateToEmployeeModule('tasks');
        break;
      default:
        _navigateToTab(2);
    }
  }

  List<Widget> _getRecentItemsForRole(String role) {
    switch (role) {
      case 'admin':
        return [
          _buildOrderItem(
            'Nuevo usuario registrado',
            'María González',
            'Hace 30 min',
            Colors.blue,
          ),
          const Divider(),
          _buildOrderItem(
            'Pedido completado',
            'Torta de Chocolate #1024',
            'Hace 1 hora',
            Colors.green,
          ),
          const Divider(),
          _buildOrderItem(
            'Alerta de inventario',
            'Harina baja en stock',
            'Hace 2 horas',
            Colors.orange,
          ),
        ];

      case 'empleado':
        return [
          _buildOrderItem(
            'Preparar Torta Red Velvet',
            'Pedido #1025',
            'Asignado',
            Colors.blue,
          ),
          const Divider(),
          _buildOrderItem(
            'Cupcakes Vainilla x12',
            'Pedido #1023',
            'Completado',
            Colors.green,
          ),
          const Divider(),
          _buildOrderItem(
            'Decorar Torta Cumpleaños',
            'Pedido #1022',
            'En proceso',
            Colors.orange,
          ),
        ];

      default: // cliente
        return [
          _buildOrderItem(
            'Torta Chocolate',
            'Entregado',
            'Hace 2 días',
            Colors.green,
          ),
          const Divider(),
          _buildOrderItem(
            'Cupcakes Vainilla x6',
            'En preparación',
            'Hoy',
            Colors.orange,
          ),
          const Divider(),
          _buildOrderItem(
            'Cheesecake Fresa',
            'Entregado',
            'Hace 5 días',
            Colors.green,
          ),
        ];
    }
  }

  Widget _buildOrderItem(
    String name,
    String status,
    String date,
    Color statusColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.cake, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TODO: Fix this when MainAppView is properly imported
  void _navigateToTab(int index) {
    // TEMPORARILY DISABLED - Requires _MainAppViewState which is now in separate file
    // final mainAppState = context.findAncestorStateOfType<_MainAppViewState>();
    // if (mainAppState != null) {
    //   mainAppState._tabController.animateTo(index);
    // }
  }

  void _navigateToAdminModule(String module) {
    if (module == 'products') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProductManagementFirebaseScreen(),
        ),
      );
    } else if (module == 'orders') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const OrderManagementScreen()),
      );
    } else if (module == 'categories') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CategoryManagementScreen(),
        ),
      );
    } else if (module == 'promotions') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PromotionManagementScreen(),
        ),
      );
    } else if (module == 'reports') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ReportsAnalyticsScreen(),
        ),
      );
    } else if (module == 'banner') {
      // Navegar al módulo de editar banner principal
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const EditarBannerScreen(),
        ),
      );
    } else if (module == 'settings') {
      // Navegar al módulo de configuración completa del negocio
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ConfiguracionNegocioCompletaScreen(),
        ),
      );
    } else {
      _showModuleDialog(
        'Módulo de Administrador',
        module,
        _getAdminModuleDescription(module),
      );
    }
  }

  void _navigateToEmployeeModule(String module) {
    _showModuleDialog(
      'Módulo de Empleado',
      module,
      _getEmployeeModuleDescription(module),
    );
  }

  Future<void> _descargarReporteExcel() async {
    try {
      // Mostrar mensaje de carga
      showAppMessage(
        context,
        'Generando reporte en Excel...',
        type: MessageType.info,
      );

      // Crear instancia del servicio de reportes
      final reporteService = ReporteExcelService();

      // Generar y descargar el reporte
      await reporteService.generarReporteCompleto();

      // Mostrar mensaje de éxito
      if (mounted) {
        showAppMessage(
          context,
          'Reporte descargado exitosamente',
          type: MessageType.success,
        );
      }
    } catch (e) {
      // Mostrar mensaje de error
      if (mounted) {
        showAppMessage(
          context,
          'Error al generar el reporte: $e',
          type: MessageType.error,
        );
      }
      print('Error al descargar reporte Excel: $e');
    }
  }

  Future<void> _descargarReportePdf() async {
    try {
      // Mostrar mensaje de carga
      showAppMessage(
        context,
        'Generando reporte visual en PDF...',
        type: MessageType.info,
      );

      // Crear instancia del servicio de reportes PDF
      final reporteService = ReportePdfService();

      // Generar y descargar el reporte
      await reporteService.generarReporteCompleto();

      // Mostrar mensaje de éxito
      if (mounted) {
        showAppMessage(
          context,
          'Reporte PDF descargado exitosamente',
          type: MessageType.success,
        );
      }
    } catch (e) {
      // Mostrar mensaje de error
      if (mounted) {
        showAppMessage(
          context,
          'Error al generar el reporte PDF: $e',
          type: MessageType.error,
        );
      }
      print('Error al descargar reporte PDF: $e');
    }
  }

  String _getAdminModuleDescription(String module) {
    switch (module) {
      case 'products':
        return 'Gestiona el catálogo de productos, precios, categorías y disponibilidad.';
      case 'orders':
        return 'Supervisa todos los pedidos: pendientes, en proceso y completados.';
      case 'users':
        return 'Administra usuarios: clientes, empleados y sus permisos.';
      case 'reports':
        return 'Analiza ventas, rendimiento y métricas del negocio.';
      case 'settings':
        return 'Configura la aplicación, métodos de pago y preferencias.';
      case 'activity':
        return 'Visualiza toda la actividad reciente del sistema.';
      default:
        return 'Módulo administrativo para gestión del negocio.';
    }
  }

  String _getEmployeeModuleDescription(String module) {
    switch (module) {
      case 'pending_orders':
        return 'Revisa y gestiona los pedidos asignados para producción.';
      case 'production':
        return 'Registra el progreso de elaboración de productos.';
      case 'tasks':
        return 'Visualiza todas las tareas asignadas y su estado.';
      default:
        return 'Módulo de trabajo para empleados.';
    }
  }

  void _showModuleDialog(String title, String module, String description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                module.toUpperCase().replaceAll('_', ' '),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Text(description),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Este módulo estará disponible próximamente.',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPromotionalBanner() {
    return ListenableBuilder(
      listenable: InformacionNegocioProvider.instance,
      builder: (context, child) {
        final provider = InformacionNegocioProvider.instance;

        // Si está cargando, mostrar un banner simple
        if (provider.cargando) {
          return Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final banner = provider.info.bannerPrincipal;

        // Si el banner no está activo, no mostrar nada
        if (!banner.activo) {
          return const SizedBox.shrink();
        }

        return Container(
          height: banner.altura,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Imagen de fondo o gradiente
                if (banner.imagenUrl != null && banner.imagenUrl!.isNotEmpty)
                  Positioned.fill(
                    child: Image.network(
                      banner.imagenUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.cake,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Overlay oscuro para mejor legibilidad del texto
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                // Texto del banner
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        banner.titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        banner.subtitulo,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPromocionesSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('promociones')
          .where('activa', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          // Silenciar errores temporales de Firestore
          if (snapshot.error.toString().contains('PERMISSION_DENIED') ||
              snapshot.error.toString().contains('UNAVAILABLE')) {
            debugPrint('Error temporal en Firestore (promociones): ${snapshot.error}');
          }
          return const SizedBox.shrink();
        }

        final promociones = snapshot.data?.docs ?? [];

        print('═══════════════════════════════════════════════════════');
        print('DEBUG PROMOCIONES - Total en Firebase: ${promociones.length}');
        print('═══════════════════════════════════════════════════════');

        // Filtrar promociones vigentes
        final promocionesVigentes = promociones.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final fechaInicio = (data['fechaInicio'] as Timestamp?)?.toDate();
          final fechaFin = (data['fechaFin'] as Timestamp?)?.toDate();
          final now = DateTime.now();

          print('\n--- Promoción: "${data['titulo']}" (ID: ${doc.id}) ---');
          print('Fecha Inicio: $fechaInicio');
          print('Fecha Fin: $fechaFin');
          print('Ahora: $now');
          print('Activa: ${data['activa']}');
          print('Productos aplicables: ${data['productosAplicables']}');
          print('Imagen URL: ${data['imagenUrl']}');
          print('Precio Original: ${data['precioOriginal']}');
          print('Precio Descuento: ${data['precioDescuento']}');
          print('Descuento: ${data['descuento']}%');

          if (fechaInicio == null || fechaFin == null) {
            print('DEBUG: ❌ Fechas nulas, se descarta');
            return false;
          }

          // Obtener la fecha sin hora para comparación
          final inicioSinHora = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
          final finSinHora = DateTime(fechaFin.year, fechaFin.month, fechaFin.day, 23, 59, 59);
          final ahoraSinHora = DateTime(now.year, now.month, now.day, now.hour, now.minute);

          // La promoción es vigente si hoy está entre inicio y fin (inclusivo)
          final esVigente = !ahoraSinHora.isBefore(inicioSinHora) && !ahoraSinHora.isAfter(finSinHora);

          print('DEBUG: - Comparación: $inicioSinHora <= $ahoraSinHora <= $finSinHora');
          print('DEBUG: ${esVigente ? "✅" : "❌"} Es vigente: $esVigente');

          // Verificar que sea una promoción activa
          final activa = data['activa'] as bool? ?? false;
          if (!activa) {
            print('DEBUG: ❌ Promoción no está activa');
            return false;
          }

          // Las promociones pueden tener productos o ser manuales (sin productos)
          // Ambas son válidas, así que no filtramos por productosAplicables
          final productosAplicables = data['productosAplicables'] as List?;
          final tieneProductos = productosAplicables != null && productosAplicables.isNotEmpty;

          // Verificar que promociones manuales tengan los datos necesarios
          if (!tieneProductos) {
            final titulo = data['titulo'] as String?;
            if (titulo == null || titulo.isEmpty) {
              print('DEBUG: ❌ Promoción manual sin título');
              return false;
            }
            print('DEBUG: ✅ Promoción manual válida: $titulo');
          } else {
            print('DEBUG: ✅ Promoción con productos: ${productosAplicables.length} productos');
          }

          return esVigente;
        }).toList();

        print('DEBUG: Promociones vigentes: ${promocionesVigentes.length}');

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Promociones',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              if (promocionesVigentes.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No hay promociones disponibles',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vuelve pronto para ver nuestras ofertas especiales',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                // Mostrar todas las promociones con sus productos en grid de 4 columnas
                _buildPromocionesGrid(promocionesVigentes),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPromocionesGrid(List<QueryDocumentSnapshot> promocionesVigentes) {
    // Separar promociones en dos tipos:
    // 1. Promociones basadas en productos (tienen productosAplicables)
    // 2. Promociones manuales (no tienen productosAplicables, tienen sus propios datos)

    final promocionesDeProductos = <Map<String, dynamic>>[];
    final promocionesDirectas = <Map<String, dynamic>>[];

    for (var promoDoc in promocionesVigentes) {
      final data = promoDoc.data() as Map<String, dynamic>;
      final productosIds = List<String>.from(data['productosAplicables'] ?? []);

      if (productosIds.isEmpty) {
        // Promoción manual - tiene sus propios datos
        promocionesDirectas.add({
          'id': promoDoc.id,
          'titulo': data['titulo'] ?? '',
          'descripcion': data['descripcion'] ?? '',
          'imagenUrl': data['imagenUrl'],
          'precioOriginal': (data['precioOriginal'] as num?)?.toDouble(),
          'precioDescuento': (data['precioDescuento'] as num?)?.toDouble(),
          'descuento': (data['descuento'] as num?)?.toDouble() ?? 0.0,
        });
      } else {
        // Promoción basada en productos
        final descuento = (data['descuento'] as num?)?.toDouble() ?? 0.0;
        for (var productoId in productosIds) {
          promocionesDeProductos.add({
            'productoId': productoId,
            'descuento': descuento,
          });
        }
      }
    }

    return FutureBuilder<List<dynamic>>(
      future: _obtenerTodasLasPromociones(promocionesDeProductos, promocionesDirectas),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            child: Text(
              'No se encontraron productos en promoción',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          );
        }

        final width = MediaQuery.of(context).size.width;
        final isMobile = width < 600;

        // Grid de 4 columnas en desktop, 2 en móvil
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 2 : 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isMobile ? 0.7 : 0.65,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            if (item is ProductoModelo) {
              return _buildProductCardWithDiscount(item);
            } else {
              // Es una promoción directa
              return _buildPromocionDirectaCard(item as Map<String, dynamic>);
            }
          },
        );
      },
    );
  }

  // Nuevo método para obtener ambos tipos de promociones
  Future<List<dynamic>> _obtenerTodasLasPromociones(
    List<Map<String, dynamic>> promocionesDeProductos,
    List<Map<String, dynamic>> promocionesDirectas,
  ) async {
    final items = <dynamic>[];

    // Agregar productos con descuento
    if (promocionesDeProductos.isNotEmpty) {
      final productos = await _obtenerProductosConDescuentos(promocionesDeProductos);
      items.addAll(productos);
    }

    // Agregar promociones directas
    items.addAll(promocionesDirectas);

    return items;
  }

  Future<List<ProductoModelo>> _obtenerProductosConDescuentos(List<Map<String, dynamic>> productosData) async {
    if (productosData.isEmpty) return [];

    try {
      final productos = <ProductoModelo>[];
      final productosVistos = <String>{};

      for (var data in productosData) {
        final id = data['productoId'] as String;
        final descuento = data['descuento'] as double;

        // Evitar duplicados
        if (productosVistos.contains(id)) continue;
        productosVistos.add(id);

        final producto = await _productosService.obtenerProducto(id);
        if (producto != null && producto.disponible) {
          // Calcular precio con descuento
          final precioOriginal = producto.precioOriginal ?? producto.precio;
          final precioConDescuento = precioOriginal * (1 - descuento / 100);

          // Crear copia del producto con descuento aplicado
          final productoConDescuento = producto.copyWith(
            precioOriginal: precioOriginal,
            precioDescuento: precioConDescuento,
            porcentajeDescuento: descuento,
          );

          productos.add(productoConDescuento);
        }
      }
      return productos;
    } catch (e) {
      return [];
    }
  }

  Widget _buildProductCardWithDiscount(ProductoModelo producto) {
    return ProductCardWithDiscount(
      producto: producto,
      onTap: () => _showProductDetailsFromModelDialog(producto),
    );
  }

  // Nuevo widget para mostrar promociones directas (creadas manualmente)
  Widget _buildPromocionDirectaCard(Map<String, dynamic> promocion) {
    return _PromocionDirectaCard(promocion: promocion);
  }

  // Placeholder methods - will be replaced with real implementations
  Widget _buildTopSellingProductsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('productos')
          .where('disponible', isEqualTo: true)
          .orderBy('totalVendidos', descending: true)
          .limit(8)
          .snapshots(),
      builder: (context, snapshot) {
        final width = MediaQuery.of(context).size.width;
        final isMobile = width < 600;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Productos Recomendados',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Mostrar loading
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              // Mostrar error o vacío
              else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No hay productos para recomendar',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vuelve pronto para descubrir nuestros productos más populares',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              // Mostrar productos
              else
                Builder(
                  builder: (context) {
                    final productos = snapshot.data!.docs
                        .map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          data['id'] = doc.id;
                          return ProductoModelo.fromJson(data);
                        })
                        .toList();

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: isMobile ? 200 : 300,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: isMobile ? 375 : 425,
                      ),
                      itemCount: productos.length,
                      itemBuilder: (context, index) {
                        return _buildProductCardFromModel(productos[index]);
                      },
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductCardFromModel(ProductoModelo producto) {
    return RecommendedProductCard(
      producto: producto,
      onTap: () => _showProductDetailsFromModelDialog(producto),
    );
  }

  void _showProductDetailsFromModelDialog(ProductoModelo producto) {
    showAppMessage(
      context,
      'Mostrando detalles de ${producto.nombre}',
      type: MessageType.info,
    );

    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? screenSize.width * 0.9 : 650,
            maxHeight: screenSize.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con botón de cerrar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            producto.categoria,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Contenido del modal
              Flexible(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Imagen del producto
                          if (producto.imagenUrl != null && producto.imagenUrl!.isNotEmpty)
                            Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: isMobile ? 180 : 220,
                                  maxWidth: isMobile ? double.infinity : 400,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    producto.imagenUrl!,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: isMobile ? 150 : 180,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Icon(Icons.cake, size: isMobile ? 60 : 70, color: Colors.white),
                                        ),
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: isMobile ? 150 : 180,
                                        alignment: Alignment.center,
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 12),

                          // Título
                          Text(
                            producto.nombre,
                            style: TextStyle(
                              fontSize: isMobile ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 8),

                          // Descripción
                          if (producto.descripcion.isNotEmpty)
                            Text(
                              producto.descripcion,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),

                          const SizedBox(height: 12),

                          // Stock disponible
                          if (producto.stock > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.inventory, size: 16, color: Colors.green.shade700),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Stock disponible: ${producto.stock}',
                                    style: TextStyle(
                                      color: Colors.green.shade900,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 12),

                          // Precio
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Precio',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'S/. ${producto.precio.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: isMobile ? 26 : 28,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Botón de agregar al carrito
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: producto.disponible && producto.stock > 0
                                  ? () {
                                      final authProvider = AuthProvider.instance;
                                      final bool isAuthenticated = authProvider.authState == AuthState.authenticated;

                                      if (!isAuthenticated) {
                                        // Mostrar mensaje, cerrar modal y redirigir a login
                                        showAppMessage(
                                          context,
                                          'Debes iniciar sesión para realizar compras',
                                          type: MessageType.warning,
                                        );
                                        Navigator.of(context).pop();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const LoginVista(),
                                          ),
                                        );
                                        return;
                                      }

                                      // Verificar si el usuario es empleado
                                      if (authProvider.currentUser?.rol == 'empleado') {
                                        showAppMessage(
                                          context,
                                          'Los empleados no pueden realizar compras',
                                          type: MessageType.warning,
                                        );
                                        return;
                                      }

                                      // Cerrar modal y mostrar mensaje de éxito
                                      Navigator.of(context).pop();
                                      showAppMessage(
                                        context,
                                        '${producto.nombre} - Compra exitosa',
                                        type: MessageType.success,
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              icon: const Icon(Icons.shopping_cart, size: 22),
                              label: const Text(
                                'Comprar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedStatsSection(String userRole) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estadísticas y Reportes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              _buildStatsActions(),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatsFilters(),
          const SizedBox(height: 16),

          // Primero: Visualización de Datos (Gráficas)
          SalesCharts(
            dateFilter: _currentDateFilter,
            categoryFilter: _currentCategoryFilter,
          ),

          const SizedBox(height: 24),

          // Después: Estadísticas (Tarjetas)
          _buildStatsSection(),
        ],
      ),
    );
  }

  Widget _buildStatsActions() {
    return Row(
      children: [
        IconButton(
          onPressed: _showFilterDialog,
          icon: const Icon(Icons.filter_alt),
          tooltip: 'Filtrar',
        ),
        IconButton(
          onPressed: _showDownloadDialog,
          icon: const Icon(Icons.download),
          tooltip: 'Descargar',
        ),
        IconButton(
          onPressed: _refreshStats,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar',
        ),
      ],
    );
  }

  Widget _buildStatsFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros Activos',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                label: 'Últimos 30 días',
                isSelected: _currentDateFilter == '30_days',
                onTap: () => _updateDateFilter('30_days'),
              ),
              _buildFilterChip(
                label: 'Este mes',
                isSelected: _currentDateFilter == 'this_month',
                onTap: () => _updateDateFilter('this_month'),
              ),
              _buildFilterChip(
                label: 'Año actual',
                isSelected: _currentDateFilter == 'this_year',
                onTap: () => _updateDateFilter('this_year'),
              ),
              _buildFilterChip(
                label: 'Todas las categorías',
                isSelected: _currentCategoryFilter == 'all',
                onTap: () => _updateCategoryFilter('all'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filtros de Estadísticas'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rango de Fechas'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  initialValue: 'last_30_days',
                  items: const [
                    DropdownMenuItem(
                      value: 'last_7_days',
                      child: Text('Últimos 7 días'),
                    ),
                    DropdownMenuItem(
                      value: 'last_30_days',
                      child: Text('Últimos 30 días'),
                    ),
                    DropdownMenuItem(
                      value: 'this_month',
                      child: Text('Este mes'),
                    ),
                    DropdownMenuItem(
                      value: 'last_month',
                      child: Text('Mes anterior'),
                    ),
                    DropdownMenuItem(
                      value: 'this_year',
                      child: Text('Este año'),
                    ),
                    DropdownMenuItem(
                      value: 'custom',
                      child: Text('Personalizado'),
                    ),
                  ],
                  onChanged: (value) {},
                ),
                const SizedBox(height: 16),
                const Text('Categoría de Productos'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  initialValue: 'all',
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('Todas las categorías'),
                    ),
                    DropdownMenuItem(value: 'tortas', child: Text('Tortas')),
                    DropdownMenuItem(
                      value: 'cupcakes',
                      child: Text('Cupcakes'),
                    ),
                    DropdownMenuItem(value: 'postres', child: Text('Postres')),
                    DropdownMenuItem(
                      value: 'brownies',
                      child: Text('Brownies'),
                    ),
                    DropdownMenuItem(
                      value: 'macarons',
                      child: Text('Macarons'),
                    ),
                  ],
                  onChanged: (value) {},
                ),
                const SizedBox(height: 16),
                const Text('Estado de Pedidos'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  initialValue: 'all',
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('Todos los estados'),
                    ),
                    DropdownMenuItem(
                      value: 'pendiente',
                      child: Text('Pendientes'),
                    ),
                    DropdownMenuItem(
                      value: 'confirmado',
                      child: Text('Confirmados'),
                    ),
                    DropdownMenuItem(
                      value: 'preparando',
                      child: Text('En preparación'),
                    ),
                    DropdownMenuItem(value: 'listo', child: Text('Listos')),
                    DropdownMenuItem(
                      value: 'entregado',
                      child: Text('Entregados'),
                    ),
                    DropdownMenuItem(
                      value: 'cancelado',
                      child: Text('Cancelados'),
                    ),
                  ],
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                showAppMessage(
                  context,
                  'Aplicando filtros...',
                  type: MessageType.info,
                );
                _applyFilters();
                showAppMessage(
                  context,
                  'Filtros aplicados exitosamente',
                  type: MessageType.success,
                );
              },
              child: const Text('Aplicar Filtros'),
            ),
          ],
        );
      },
    );
  }

  void _showDownloadDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Descargar Estadísticas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Selecciona el formato de descarga:'),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('Excel (.xlsx)'),
                subtitle: const Text('Ideal para análisis detallado'),
                onTap: () {
                  Navigator.pop(context);
                  showAppMessage(
                    context,
                    'Preparando descarga de estadísticas en Excel...',
                    type: MessageType.info,
                  );
                  _downloadStats('excel');
                },
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('CSV (.csv)'),
                subtitle: const Text('Compatible con cualquier software'),
                onTap: () {
                  Navigator.pop(context);
                  showAppMessage(
                    context,
                    'Preparando descarga de estadísticas en CSV...',
                    type: MessageType.info,
                  );
                  _downloadStats('csv');
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('PDF (.pdf)'),
                subtitle: const Text('Reporte completo para presentación'),
                onTap: () {
                  Navigator.pop(context);
                  showAppMessage(
                    context,
                    'Preparando descarga de reporte en PDF...',
                    type: MessageType.info,
                  );
                  _downloadStats('pdf');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _applyFilters() {
    // Simular aplicación de filtros
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(child: Text('Filtros aplicados correctamente')),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100,
          left: 20,
          right: 20,
        ),
      ),
    );
    // Aquí iría la lógica real para filtrar los datos
  }

  void _refreshStats() {
    // Forzar actualización del widget con setState
    setState(() {
      // Esto provocará que se reconstruya el widget y se vuelvan a cargar los datos
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(child: Text('Estadísticas actualizadas')),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100,
          left: 20,
          right: 20,
        ),
      ),
    );
  }

  void _downloadStats(String format) async {
    try {
      // Mostrar indicador de carga
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Generando reporte ${format.toUpperCase()}...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Generar reporte según el formato seleccionado
      if (format.toLowerCase() == 'pdf') {
        // Generar PDF con gráficos visuales
        final reporteService = ReportePdfService();
        final resultado = await reporteService.generarReportePdf();

        if (!mounted) return;
        Navigator.pop(context); // Cerrar loading

        // Descargar archivo
        final bytes = resultado['bytes'] as Uint8List;
        final nombreArchivo = resultado['nombreArchivo'] as String;

        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', nombreArchivo)
          ..click();
        html.Url.revokeObjectUrl(url);

        if (!mounted) return;
        showAppMessage(
          context,
          'Reporte PDF descargado: $nombreArchivo',
          type: MessageType.success,
        );
      } else if (format.toLowerCase() == 'excel') {
        // Generar Excel con múltiples hojas
        final excelService = ReporteExcelService();
        await excelService.generarReporteCompleto();

        if (!mounted) return;
        Navigator.pop(context); // Cerrar loading

        if (!mounted) return;
        showAppMessage(
          context,
          'Reporte Excel descargado exitosamente',
          type: MessageType.success,
        );
      } else if (format.toLowerCase() == 'csv') {
        // Generar CSV simple
        await _generarReporteCSV();

        if (!mounted) return;
        Navigator.pop(context); // Cerrar loading

        if (!mounted) return;
        showAppMessage(
          context,
          'Reporte CSV descargado exitosamente',
          type: MessageType.success,
        );
      } else {
        if (!mounted) return;
        Navigator.pop(context);
        showAppMessage(
          context,
          'Formato no soportado: $format',
          type: MessageType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Intentar cerrar el dialog si está abierto
      try {
        Navigator.of(context).pop();
      } catch (_) {}

      showAppMessage(
        context,
        'Error al generar el reporte: $e',
        type: MessageType.error,
      );
    }
  }

  /// Generar reporte en formato CSV
  Future<void> _generarReporteCSV() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Obtener datos de pedidos
      final pedidosSnapshot = await firestore.collection('pedidos').get();

      // Crear contenido CSV
      final csvContent = StringBuffer();
      csvContent.writeln('Número,Cliente,Total (S/.),Estado,Método Pago,Fecha');

      for (var doc in pedidosSnapshot.docs) {
        final data = doc.data();
        final numero = data['numero'] ?? '';
        final clienteNombre = data['clienteNombre'] ?? 'N/A';
        final total = (data['total'] ?? 0).toStringAsFixed(2);
        final estado = data['estado'] ?? '';
        final metodoPago = data['metodoPago'] ?? '';
        final fecha = data['fecha'] != null
            ? DateFormat('dd/MM/yyyy').format((data['fecha'] as Timestamp).toDate())
            : 'N/A';

        csvContent.writeln('$numero,$clienteNombre,$total,$estado,$metodoPago,$fecha');
      }

      // Generar nombre de archivo
      final fechaActual = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final nombreArchivo = 'Reporte_Pedidos_$fechaActual.csv';

      // Descargar archivo
      final bytes = utf8.encode(csvContent.toString());
      final blob = html.Blob([Uint8List.fromList(bytes)], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', nombreArchivo)
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      debugPrint('Error al generar CSV: $e');
      rethrow;
    }
  }

  void _updateDateFilter(String filter) {
    setState(() {
      _currentDateFilter = filter;
    });
  }

  void _updateCategoryFilter(String filter) {
    setState(() {
      _currentCategoryFilter = filter;
    });
  }
}

/// Widget con estado para las promociones directas con contador de cantidad
class _PromocionDirectaCard extends StatefulWidget {
  final Map<String, dynamic> promocion;

  const _PromocionDirectaCard({required this.promocion});

  @override
  State<_PromocionDirectaCard> createState() => _PromocionDirectaCardState();
}

class _PromocionDirectaCardState extends State<_PromocionDirectaCard> {
  int _cantidad = 1;

  @override
  Widget build(BuildContext context) {
    final titulo = widget.promocion['titulo'] as String? ?? 'Promoción';
    final descripcion = widget.promocion['descripcion'] as String? ?? '';
    final imagenUrl = widget.promocion['imagenUrl'] as String?;
    final precioOriginal = widget.promocion['precioOriginal'] as double?;
    final precioDescuento = widget.promocion['precioDescuento'] as double?;
    final descuento = widget.promocion['descuento'] as double? ?? 0.0;

    final tienePrecios = precioOriginal != null && precioDescuento != null;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Mostrar diálogo con detalles de la promoción
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenHeight = MediaQuery.of(context).size.height;
                  final maxDialogHeight = screenHeight * 0.85;
                  final availableImageHeight = maxDialogHeight - 350; // Espacio para contenido y botones

                  return Container(
                    constraints: BoxConstraints(
                      maxWidth: 500,
                      maxHeight: maxDialogHeight,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Imagen de la promoción
                        if (imagenUrl != null && imagenUrl.isNotEmpty)
                          Container(
                            constraints: BoxConstraints(
                              maxHeight: availableImageHeight > 150 ? availableImageHeight : 150,
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: Image.network(
                                imagenUrl,
                                width: double.infinity,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.image_not_supported, size: 50),
                                  );
                                },
                              ),
                            ),
                          ),

                    // Contenido
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Título
                          Text(
                            titulo,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Descripción
                          if (descripcion.isNotEmpty) ...[
                            Text(
                              descripcion,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Precios
                          if (tienePrecios) ...[
                            const Divider(),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Precio Original',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'S/. ${precioOriginal.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '-${descuento.toInt()}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'S/. ${precioDescuento.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Botones de acción
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Cerrar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final authProvider = AuthProvider.instance;
                                final bool isAuthenticated = authProvider.authState == AuthState.authenticated;

                                if (!isAuthenticated) {
                                  // Mostrar mensaje, cerrar diálogo y redirigir a login
                                  showAppMessage(
                                    context,
                                    'Debes iniciar sesión para realizar compras',
                                    type: MessageType.warning,
                                  );
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginVista(),
                                    ),
                                  );
                                  return;
                                }

                                // Verificar si el usuario es empleado
                                if (authProvider.currentUser?.rol == 'empleado') {
                                  showAppMessage(
                                    context,
                                    'Los empleados no pueden realizar compras',
                                    type: MessageType.warning,
                                  );
                                  return;
                                }

                                // Cerrar diálogo y mostrar mensaje de éxito
                                Navigator.pop(context);
                                showAppMessage(
                                  context,
                                  '$titulo - Compra exitosa',
                                  type: MessageType.success,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.shopping_cart),
                              label: const Text('Comprar'),
                            ),
                          ),
                        ],
                      ),
                    ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen con badge de descuento
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: imagenUrl != null && imagenUrl.isNotEmpty
                        ? Image.network(
                            imagenUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.local_offer,
                                  size: 60,
                                  color: Theme.of(context).primaryColor,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.local_offer,
                              size: 60,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                  ),

                  // Badge de descuento
                  if (descuento > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '-${descuento.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Información de la promoción
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Precios
                  if (tienePrecios) ...[
                    // Precio original tachado
                    Text(
                      'S/. ${precioOriginal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Precio con descuento
                    Text(
                      'S/. ${precioDescuento.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ] else if (descuento > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '¡${descuento.toInt()}% OFF!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Contador de cantidad y botón de compra
                  Row(
                    children: [
                      // Contador de cantidad
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Botón decrementar
                            InkWell(
                              onTap: _cantidad <= 1
                                  ? null
                                  : () {
                                      setState(() {
                                        _cantidad--;
                                      });
                                    },
                              child: Container(
                                padding: EdgeInsets.all(isMobile ? 3 : 4),
                                child: Icon(
                                  Icons.remove,
                                  size: isMobile ? 12 : 14,
                                  color: _cantidad <= 1
                                      ? Colors.grey.shade400
                                      : Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            // Cantidad
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 4 : 6,
                              ),
                              child: Text(
                                '$_cantidad',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 11 : 12,
                                ),
                              ),
                            ),
                            // Botón incrementar
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _cantidad++;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(isMobile ? 3 : 4),
                                child: Icon(
                                  Icons.add,
                                  size: isMobile ? 12 : 14,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Botón de compra
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final authProvider = AuthProvider.instance;
                            final bool isAuthenticated = authProvider.authState == AuthState.authenticated;

                            if (!isAuthenticated) {
                              // Mostrar mensaje y redirigir a login
                              showAppMessage(
                                context,
                                'Debes iniciar sesión para realizar compras',
                                type: MessageType.warning,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginVista(),
                                ),
                              );
                              return;
                            }

                            // Verificar si el usuario es empleado
                            if (authProvider.currentUser?.rol == 'empleado') {
                              showAppMessage(
                                context,
                                'Los empleados no pueden realizar compras',
                                type: MessageType.warning,
                              );
                              return;
                            }

                            // Mostrar mensaje de éxito con cantidad
                            showAppMessage(
                              context,
                              '$titulo x$_cantidad - Compra exitosa',
                              type: MessageType.success,
                            );

                            // Resetear cantidad
                            setState(() {
                              _cantidad = 1;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 6 : 8,
                              horizontal: isMobile ? 6 : 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          icon: Icon(Icons.shopping_cart, size: isMobile ? 14 : 16),
                          label: Text(
                            'Comprar',
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
