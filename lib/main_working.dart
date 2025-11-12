import 'package:flutter/material.dart';

// Configuration constants
class AppConfig {
  static const String appName = 'Repostería Arlex';
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 100;
  static const int minUsernameLength = 2;
  static const int maxUsernameLength = 50;
  static const int maxEmailLength = 100;
}

// User model
class UsuarioModelo {
  final String id;
  final String email;
  final String nombre;
  final String? telefono;
  final String rol;
  final String estado;
  final DateTime fechaCreacion;
  final DateTime? fechaUltimoAcceso;

  UsuarioModelo({
    required this.id,
    required this.email,
    required this.nombre,
    this.telefono,
    required this.rol,
    required this.estado,
    required this.fechaCreacion,
    this.fechaUltimoAcceso,
  });

  String get iniciales {
    final parts = nombre.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';
  }

  String get rolDescripcion {
    switch (rol) {
      case 'admin':
        return 'Administrador';
      case 'empleado':
        return 'Empleado';
      case 'cliente':
        return 'Cliente';
      default:
        return 'Usuario';
    }
  }

  String get estadoDescripcion {
    switch (estado) {
      case 'activo':
        return 'Activo';
      case 'inactivo':
        return 'Inactivo';
      case 'suspendido':
        return 'Suspendido';
      default:
        return 'Desconocido';
    }
  }
}

// Authentication states
enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

// Auth Provider
class AuthProvider extends ChangeNotifier {
  static AuthProvider? _instance;
  static AuthProvider get instance => _instance ??= AuthProvider._();

  AuthProvider._();

  AuthState _authState = AuthState.initial;
  UsuarioModelo? _currentUser;
  String? _errorMessage;

  AuthState get authState => _authState;
  UsuarioModelo? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get needsVerification => false; // Mock implementation

  Future<void> initialize() async {
    _authState = AuthState.loading;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _authState = AuthState.unauthenticated;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _authState = AuthState.loading;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    // Mock users
    if (email == 'admin@reposteriaarlex.com' && password == 'admin123') {
      _currentUser = UsuarioModelo(
        id: '1',
        email: email,
        nombre: 'Administrador Arlex',
        rol: 'admin',
        estado: 'activo',
        fechaCreacion: DateTime.now(),
      );
      _authState = AuthState.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } else if (email == 'cliente@test.com' && password == '123456') {
      _currentUser = UsuarioModelo(
        id: '2',
        email: email,
        nombre: 'Cliente de Prueba',
        rol: 'cliente',
        estado: 'activo',
        fechaCreacion: DateTime.now(),
      );
      _authState = AuthState.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Credenciales incorrectas';
      _authState = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _authState = AuthState.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  bool hasPermission(String permission) {
    if (_currentUser == null) return false;
    if (_currentUser!.rol == 'admin') return true;
    return false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthProvider.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE91E63),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE91E63), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const AuthenticationWrapper(),
      routes: {
        '/login': (context) => const LoginVista(),
        '/home': (context) => const MainAppView(),
        '/admin/dashboard': (context) => const AdminDashboard(),
        '/client/dashboard': (context) => const ClientDashboard(),
      },
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthProvider.instance,
      builder: (context, child) {
        final authProvider = AuthProvider.instance;

        switch (authProvider.authState) {
          case AuthState.initial:
          case AuthState.loading:
            return const LoadingScreen();

          case AuthState.authenticated:
            if (authProvider.needsVerification) {
              return const EmailVerificationScreen();
            }
            return const MainAppView();

          case AuthState.unauthenticated:
          case AuthState.error:
            return const LoginVista();
        }
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cake,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 20),
              Text(
                AppConfig.appName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                'Cargando...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar Email'),
        actions: [
          TextButton(
            onPressed: () => authProvider.logout(),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mark_email_unread,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 20),
            const Text(
              'Verifica tu email',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Hemos enviado un enlace de verificación a:\\n${authProvider.currentUser?.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email de verificación reenviado'),
                  ),
                );
              },
              child: const Text('Reenviar Email'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginVista extends StatefulWidget {
  const LoginVista({super.key});

  @override
  State<LoginVista> createState() => _LoginVistaState();
}

class _LoginVistaState extends State<LoginVista> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final success = await AuthProvider.instance.login(
      _emailController.text,
      _passwordController.text,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthProvider.instance.errorMessage ?? 'Error de login'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 60),
                const Icon(
                  Icons.cake,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                const Text(
                  AppConfig.appName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Iniciar Sesión'),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Usuarios de prueba:\\n'
                        'Admin: admin@reposteriaarlex.com / admin123\\n'
                        'Cliente: cliente@test.com / 123456',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainAppView extends StatefulWidget {
  const MainAppView({super.key});

  @override
  State<MainAppView> createState() => _MainAppViewState();
}

class _MainAppViewState extends State<MainAppView> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        actions: [
          IconButton(
            onPressed: () => _showProfileMenu(context),
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                authProvider.currentUser?.iniciales ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HomeScreen(),
          ProductsScreen(),
          OrdersScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cake),
            label: 'Productos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Pedidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    final authProvider = AuthProvider.instance;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    authProvider.currentUser?.iniciales ?? 'U',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(authProvider.currentUser?.nombre ?? 'Usuario'),
                subtitle: Text(authProvider.currentUser?.email ?? ''),
              ),
              const Divider(),
              if (authProvider.hasPermission('admin_access'))
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text('Panel Administrativo'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/dashboard');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configuración'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Cerrar Sesión'),
                onTap: () {
                  Navigator.pop(context);
                  authProvider.logout();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text('Pantalla de Inicio', style: TextStyle(fontSize: 24)),
          Text('Próximamente disponible'),
        ],
      ),
    );
  }
}

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cake, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text('Catálogo de Productos', style: TextStyle(fontSize: 24)),
          Text('Próximamente disponible'),
        ],
      ),
    );
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text('Mis Pedidos', style: TextStyle(fontSize: 24)),
          Text('Próximamente disponible'),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.instance;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              authProvider.currentUser?.iniciales ?? 'U',
              style: const TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            authProvider.currentUser?.nombre ?? 'Usuario',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            authProvider.currentUser?.email ?? '',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.badge),
              title: const Text('Rol'),
              subtitle: Text(authProvider.currentUser?.rolDescripcion ?? ''),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.verified),
              title: const Text('Estado'),
              subtitle: Text(authProvider.currentUser?.estadoDescripcion ?? ''),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => authProvider.logout(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrativo'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text('Panel Administrativo', style: TextStyle(fontSize: 24)),
            Text('Próximamente disponible'),
          ],
        ),
      ),
    );
  }
}

class ClientDashboard extends StatelessWidget {
  const ClientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Cuenta'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text('Dashboard del Cliente', style: TextStyle(fontSize: 24)),
            Text('Próximamente disponible'),
          ],
        ),
      ),
    );
  }
}