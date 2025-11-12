import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider_simple.dart';
import '../../providers/carrito_provider.dart';
import '../../configuracion/app_config.dart';
import '../../compartidos/widgets/message_helpers.dart';
import '../../servicios/notificaciones_service.dart';
import '../auth/login_vista.dart';
import '../auth/registro_vista.dart';
import 'home_screen.dart';
import 'products_screen.dart';
import 'profile_screen.dart';
import 'cart_screen.dart';
import 'employee_orders_screen.dart';
import 'notificaciones_screen.dart';
import 'historial_pedidos_screen.dart';
import 'conocenos_screen.dart';

class MainAppView extends StatefulWidget {
  const MainAppView({super.key});

  @override
  State<MainAppView> createState() => _MainAppViewState();
}

class _MainAppViewState extends State<MainAppView> {
  int _currentIndex = 0;

  void _navigateToSection(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToHome() {
    setState(() {
      _currentIndex = 0;
    });
    // Hacer scroll al inicio de la página
    Future.delayed(const Duration(milliseconds: 50), () {
      // Buscar el ScrollController del HomeScreen y hacer scroll al top
      final homeScreenState = HomeScreen.homeScreenKey.currentState;
      if (homeScreenState != null) {
        homeScreenState.scrollToTop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthProvider.instance,
      builder: (context, child) {
        final authProvider = AuthProvider.instance;
        final bool isAuthenticated =
            authProvider.authState == AuthState.authenticated;
        final bool isEmployee = authProvider.currentUser?.rol == 'empleado';
        final bool isAdmin = authProvider.currentUser?.rol == 'admin';

        // Crear lista de vistas dinámicamente
        List<Widget> screens = [
          HomeScreen(key: HomeScreen.homeScreenKey),
          const ProductsScreen(),
        ];

        // Si está autenticado y NO es admin, agregar Carrito/Pedidos
        if (isAuthenticated && !isAdmin) {
          screens.add(
            isEmployee ? const EmployeeOrdersScreen() : const CartScreen(),
          );
        }

        // Siempre agregar ProfileScreen
        screens.add(const ProfileScreen());

        return Scaffold(
          appBar: AppBar(
            centerTitle: false,
            titleSpacing: 16,
            title: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('informacion_negocio')
                  .doc('config')
                  .snapshots(),
              builder: (context, snapshot) {
                String nombre = AppConfig.appName;
                String? logoUrl;

                if (snapshot.hasData && snapshot.data?.data() != null) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;

                  // Intentar obtener el nombre de la estructura anidada primero (nuevo formato)
                  if (data.containsKey('galeria') && data['galeria'] is Map) {
                    final galeria = data['galeria'] as Map<String, dynamic>;
                    nombre = galeria['nombre'] ?? data['nombre'] ?? AppConfig.appName;
                    logoUrl = galeria['logo'];
                  } else {
                    // Fallback a estructura plana (formato antiguo)
                    nombre = data['nombre'] ?? AppConfig.appName;
                    logoUrl = data['logo'];
                  }
                }

                return Row(
                  children: [
                    // Logo y nombre (izquierda)
                    InkWell(
                      onTap: _navigateToHome,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (logoUrl != null && logoUrl.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    logoUrl,
                                    height: 40,
                                    width: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.store, size: 32, color: Colors.white);
                                    },
                                  ),
                                ),
                              ),
                            Text(nombre, style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),

                    // Spacer para centrar los módulos
                    const Spacer(),

                    // Módulos centrados - Productos y Conócenos
                    _buildNavItem('Productos', 1),
                    const SizedBox(width: 24),
                    if (!isAdmin)
                      _buildConocenosButton(),

                    // Spacer para mantener centrado
                    const Spacer(),
                  ],
                );
              },
            ),
            actions: [
              if (isAuthenticated) ...[
                // Carrito icon (solo clientes)
                if (!isEmployee && !isAdmin)
                  _buildCartIcon(),
                const SizedBox(width: 8),

                // Notificaciones dropdown
                _buildNotificationDropdown(authProvider),
                const SizedBox(width: 8),

                // Perfil dropdown
                _buildProfileDropdown(authProvider),
                const SizedBox(width: 16),
              ] else ...[
                // Botones para usuarios no autenticados
                OutlinedButton(
                  onPressed: () => _navigateToLogin(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 1.5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Iniciar Sesión'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _navigateToRegister(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 1.5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Registrarse'),
                ),
                const SizedBox(width: 16),
              ],
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
        );
      },
    );
  }

  Widget _buildConocenosButton() {
    return TextButton(
      onPressed: () {
        // Navegar a la pantalla de Conócenos
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ConocenosScreen(),
          ),
        );
      },
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        'Conócenos',
        style: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildNavItem(String label, int index) {
    final isActive = _currentIndex == index;

    return TextButton(
      onPressed: () => _navigateToSection(index),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: isActive ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildCartIcon() {
    return ListenableBuilder(
      listenable: CarritoProvider.instance,
      builder: (context, _) {
        final cantidadItems = CarritoProvider.instance.cantidadTotal;
        return IconButton(
          onPressed: () => _navigateToSection(_getCartIndex()),
          icon: Badge(
            isLabelVisible: cantidadItems > 0,
            label: Text('$cantidadItems'),
            child: const Icon(Icons.shopping_cart, color: Colors.white),
          ),
        );
      },
    );
  }

  int _getCartIndex() {
    final authProvider = AuthProvider.instance;
    final bool isAdmin = authProvider.currentUser?.rol == 'admin';
    // Si no es admin, el carrito está en índice 2 (después de Home y Productos)
    return isAdmin ? 0 : 2;
  }

  Widget _buildNotificationDropdown(AuthProvider authProvider) {
    final userId = authProvider.currentUser?.id;

    if (userId == null) {
      return const SizedBox.shrink();
    }

    final notificacionesService = NotificacionesService();

    return StreamBuilder<int>(
      stream: notificacionesService.obtenerCantidadNoLeidas(userId),
      builder: (context, countSnapshot) {
        final cantidadNoLeidas = countSnapshot.data ?? 0;

        return PopupMenuButton<String>(
          icon: Badge(
            isLabelVisible: cantidadNoLeidas > 0,
            label: Text('$cantidadNoLeidas'),
            child: const Icon(Icons.notifications, color: Colors.white),
          ),
          offset: const Offset(0, 50),
          onSelected: (value) {
            if (value == 'ver_todas') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificacionesScreen(),
                ),
              );
            } else if (value.startsWith('notif_')) {
              // Marcar como leída al hacer clic
              final notifId = value.substring(6);
              notificacionesService.marcarComoLeida(notifId);
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              // Header
              PopupMenuItem<String>(
                enabled: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notificaciones',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (cantidadNoLeidas > 0)
                      TextButton(
                        onPressed: () {
                          notificacionesService.marcarTodasComoLeidas(userId);
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Marcar todas',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              // Lista de notificaciones
              ..._buildNotificationItems(userId, notificacionesService),
              const PopupMenuDivider(),
              // Ver todas
              PopupMenuItem<String>(
                value: 'ver_todas',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.list, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Ver todas',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ];
          },
        );
      },
    );
  }

  List<PopupMenuEntry<String>> _buildNotificationItems(
    String userId,
    NotificacionesService notificacionesService,
  ) {
    List<PopupMenuEntry<String>> items = [];

    items.add(
      PopupMenuItem<String>(
        enabled: false,
        padding: EdgeInsets.zero,
        child: SizedBox(
          width: 420,
          height: 450,
          child: StreamBuilder<QuerySnapshot>(
            stream: notificacionesService.obtenerNotificacionesUsuario(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No tienes notificaciones',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final notificaciones = snapshot.data!.docs.take(5).toList();

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: notificaciones.map((notif) {
                    final data = notif.data() as Map<String, dynamic>;
                    final titulo = data['titulo'] ?? 'Sin título';
                    final mensaje = data['mensaje'] ?? '';
                    final leida = data['leida'] ?? false;
                    final tipo = data['tipo'] ?? 'admin';
                    final fecha = data['fecha'] as Timestamp?;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (!leida) {
                            notificacionesService.marcarComoLeida(notif.id);
                          }
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: leida ? Colors.white : Colors.blue.shade50,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Ícono con fondo circular
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _getNotificationColor(tipo).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getNotificationIcon(tipo),
                                  size: 24,
                                  color: _getNotificationColor(tipo),
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Contenido
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            titulo,
                                            style: TextStyle(
                                              fontWeight: leida
                                                  ? FontWeight.w500
                                                  : FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (fecha != null) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatearFecha(fecha),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      mensaje,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                        height: 1.4,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Indicador de no leída
                              if (!leida)
                                Container(
                                  width: 10,
                                  height: 10,
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: _getNotificationColor(tipo),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ),
    );

    return items;
  }

  IconData _getNotificationIcon(String tipo) {
    switch (tipo) {
      case 'pedido':
        return Icons.shopping_bag;
      case 'promocion':
        return Icons.local_offer;
      default:
        return Icons.notifications_active;
    }
  }

  Color _getNotificationColor(String tipo) {
    switch (tipo) {
      case 'pedido':
        return Colors.green;
      case 'promocion':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String _formatearFecha(Timestamp timestamp) {
    final fecha = timestamp.toDate();
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inMinutes < 1) {
      return 'Ahora';
    } else if (diferencia.inHours < 1) {
      return 'Hace ${diferencia.inMinutes} min';
    } else if (diferencia.inDays < 1) {
      return 'Hace ${diferencia.inHours} h';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays} d';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }

  Widget _buildProfileDropdown(AuthProvider authProvider) {
    return PopupMenuButton<String>(
      icon: CircleAvatar(
        backgroundColor: Colors.white,
        child: Text(
          authProvider.currentUser?.iniciales ?? 'U',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      offset: const Offset(0, 50),
      onSelected: (value) {
        switch (value) {
          case 'informacion':
            _navigateToSection(_getProfileIndex());
            break;
          case 'mis_pedidos':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HistorialPedidosScreen(),
              ),
            );
            break;
          case 'cerrar_sesion':
            _handleLogout();
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'informacion',
          child: Row(
            children: const [
              Icon(Icons.person),
              SizedBox(width: 12),
              Text('Información'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'mis_pedidos',
          child: Row(
            children: const [
              Icon(Icons.shopping_bag),
              SizedBox(width: 12),
              Text('Mis Pedidos'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'cerrar_sesion',
          child: Row(
            children: const [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 12),
              Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  int _getProfileIndex() {
    final authProvider = AuthProvider.instance;
    final bool isAdmin = authProvider.currentUser?.rol == 'admin';
    // El perfil siempre es el último índice
    if (isAdmin) {
      return 2; // Home, Productos, Perfil
    } else {
      return 3; // Home, Productos, Carrito/Pedidos, Perfil
    }
  }

  void _handleLogout() async {
    final authProvider = AuthProvider.instance;

    showAppMessage(
      context,
      'Cerrando sesión...',
      type: MessageType.info,
    );

    authProvider.logout();

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      showAppMessage(
        context,
        'Sesión cerrada exitosamente',
        type: MessageType.success,
      );

      // Redirigir a home
      _navigateToHome();
    }
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginVista(),
      ),
    );
  }

  void _navigateToRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegistroVista(),
      ),
    );
  }
}
