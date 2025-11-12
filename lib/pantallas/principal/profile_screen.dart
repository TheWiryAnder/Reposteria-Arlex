import 'package:flutter/material.dart';
import '../../providers/auth_provider_simple.dart';
import '../../compartidos/widgets/message_helpers.dart';
import '../../servicios/firebase_auth_service.dart';
import '../../servicios/actividades_service.dart';
import '../auth/login_vista.dart';
import '../auth/registro_vista.dart';
import 'historial_pedidos_screen.dart';
import 'main_app_view.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.instance;
    final bool isAuthenticated =
        authProvider.authState == AuthState.authenticated;

    // Si no está autenticado, mostrar pantalla de bienvenida
    if (!isAuthenticated) {
      return _buildGuestProfileView(context);
    }

    // Si está autenticado, mostrar el perfil normal
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(20),
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
              textAlign: TextAlign.center,
            ),
            Text(
              authProvider.currentUser?.email ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Sección de información personal
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Información Personal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editarInformacion(context),
                              tooltip: 'Editar información',
                            ),
                            IconButton(
                              icon: const Icon(Icons.lock_reset),
                              onPressed: () => _cambiarContrasena(context),
                              tooltip: 'Cambiar contraseña',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildInfoRow(Icons.person, 'Nombre', authProvider.currentUser?.nombre ?? 'N/A'),
                    _buildInfoRow(Icons.email, 'Email', authProvider.currentUser?.email ?? 'N/A'),
                    _buildInfoRow(Icons.phone, 'Teléfono', authProvider.currentUser?.telefono ?? 'No registrado'),
                    _buildInfoRow(Icons.location_on, 'Dirección', authProvider.currentUser?.direccion ?? 'No registrada'),
                    _buildInfoRow(Icons.badge, 'Rol', authProvider.currentUser?.rolDescripcion ?? 'N/A'),
                    _buildInfoRow(Icons.verified, 'Estado', authProvider.currentUser?.estadoDescripcion ?? 'N/A'),
                  ],
                ),
              ),
            ),
        if (authProvider.currentUser?.rol == 'cliente')
          Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Mis Pedidos'),
              subtitle: const Text('Ver historial de pedidos'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistorialPedidosScreen(),
                  ),
                );
              },
            ),
          ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  showAppMessage(
                    context,
                    'Cerrando sesión...',
                    type: MessageType.info,
                  );

                  authProvider.logout();

                  // Esperar un momento para que se vea el mensaje
                  await Future.delayed(const Duration(milliseconds: 500));

                  if (context.mounted) {
                    showAppMessage(
                      context,
                      'Sesión cerrada exitosamente',
                      type: MessageType.success,
                    );

                    // Redirigir a la vista inicial (MainAppView se reconstruirá sin auth)
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const MainAppView()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar Sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editarInformacion(BuildContext context) {
    final authProvider = AuthProvider.instance;
    final nombreController = TextEditingController(text: authProvider.currentUser?.nombre ?? '');
    final telefonoController = TextEditingController(text: authProvider.currentUser?.telefono ?? '');
    final direccionController = TextEditingController(text: authProvider.currentUser?.direccion ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Información Personal'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                    hintText: 'Ej: Juan Pérez',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu nombre';
                    }
                    if (value.length < 3) {
                      return 'El nombre debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                    hintText: 'Ej: 987654321',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu teléfono';
                    }
                    if (value.length < 9) {
                      return 'El teléfono debe tener al menos 9 dígitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: direccionController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                    hintText: 'Ej: Av. Principal 123, Lima',
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu dirección';
                    }
                    if (value.length < 10) {
                      return 'La dirección debe tener al menos 10 caracteres';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              nombreController.dispose();
              telefonoController.dispose();
              direccionController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final nuevoNombre = nombreController.text.trim();
                final nuevoTelefono = telefonoController.text.trim();
                final nuevaDireccion = direccionController.text.trim();

                // Mostrar indicador de carga
                showAppMessage(
                  context,
                  'Actualizando información...',
                  type: MessageType.info,
                );

                try {
                  final firebaseAuth = FirebaseAuthService();
                  final result = await firebaseAuth.actualizarPerfil(
                    userId: authProvider.currentUser!.id,
                    nombre: nuevoNombre,
                    telefono: nuevoTelefono,
                    direccion: nuevaDireccion,
                  );

                  nombreController.dispose();
                  telefonoController.dispose();
                  direccionController.dispose();
                  if (context.mounted) Navigator.pop(context);

                  if (result['success'] == true) {
                    // Actualizar el usuario en el AuthProvider
                    authProvider.actualizarUsuarioActual(UsuarioModelo(
                      id: authProvider.currentUser!.id,
                      email: authProvider.currentUser!.email,
                      nombre: nuevoNombre,
                      telefono: nuevoTelefono,
                      direccion: nuevaDireccion,
                      rol: authProvider.currentUser!.rol,
                      estado: authProvider.currentUser!.estado,
                    ));

                    // Forzar reconstrucción del widget
                    if (mounted) setState(() {});

                    if (context.mounted) {
                      showAppMessage(
                        context,
                        'Información actualizada exitosamente',
                        type: MessageType.success,
                      );
                    }
                  } else {
                    if (context.mounted) {
                      showAppMessage(
                        context,
                        result['message'] ?? 'Error al actualizar información',
                        type: MessageType.error,
                      );
                    }
                  }
                } catch (e) {
                  nombreController.dispose();
                  telefonoController.dispose();
                  direccionController.dispose();
                  if (context.mounted) {
                    Navigator.pop(context);
                    showAppMessage(
                      context,
                      'Error al actualizar información: $e',
                      type: MessageType.error,
                    );
                  }
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _cambiarContrasena(BuildContext context) {
    final passwordActualController = TextEditingController();
    final passwordNuevaController = TextEditingController();
    final passwordConfirmarController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureActual = true;
    bool obscureNueva = true;
    bool obscureConfirmar = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cambiar Contraseña'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: passwordActualController,
                    obscureText: obscureActual,
                    decoration: InputDecoration(
                      labelText: 'Contraseña Actual',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureActual ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscureActual = !obscureActual;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu contraseña actual';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordNuevaController,
                    obscureText: obscureNueva,
                    decoration: InputDecoration(
                      labelText: 'Nueva Contraseña',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNueva ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscureNueva = !obscureNueva;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa la nueva contraseña';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordConfirmarController,
                    obscureText: obscureConfirmar,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Nueva Contraseña',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirmar ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscureConfirmar = !obscureConfirmar;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirma la nueva contraseña';
                      }
                      if (value != passwordNuevaController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'La contraseña debe tener al menos 6 caracteres',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                passwordActualController.dispose();
                passwordNuevaController.dispose();
                passwordConfirmarController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final passwordActual = passwordActualController.text;
                  final passwordNueva = passwordNuevaController.text;

                  // Mostrar indicador de carga
                  showAppMessage(
                    context,
                    'Cambiando contraseña...',
                    type: MessageType.info,
                  );

                  try {
                    final firebaseAuth = FirebaseAuthService();
                    final result = await firebaseAuth.cambiarPassword(
                      passwordActual: passwordActual,
                      passwordNueva: passwordNueva,
                    );

                    passwordActualController.dispose();
                    passwordNuevaController.dispose();
                    passwordConfirmarController.dispose();

                    if (context.mounted) Navigator.pop(context);

                    if (result['success'] == true) {
                      // Registrar actividad
                      final authProvider = AuthProvider.instance;
                      final actividadesService = ActividadesService();
                      await actividadesService.registrarActividad(
                        tipo: 'credenciales',
                        descripcion: 'Cambió su contraseña',
                        usuarioId: authProvider.currentUser!.id,
                        usuarioNombre: authProvider.currentUser!.nombre,
                      );

                      if (context.mounted) {
                        showAppMessage(
                          context,
                          'Contraseña actualizada exitosamente',
                          type: MessageType.success,
                        );
                      }
                    } else {
                      if (context.mounted) {
                        showAppMessage(
                          context,
                          result['message'] ?? 'Error al cambiar contraseña',
                          type: MessageType.error,
                        );
                      }
                    }
                  } catch (e) {
                    passwordActualController.dispose();
                    passwordNuevaController.dispose();
                    passwordConfirmarController.dispose();

                    if (context.mounted) {
                      Navigator.pop(context);
                      showAppMessage(
                        context,
                        'Error al cambiar contraseña: $e',
                        type: MessageType.error,
                      );
                    }
                  }
                }
              },
              child: const Text('Cambiar Contraseña'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestProfileView(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle,
                size: 120,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              const Text(
                '¡Bienvenido a Repostería Arlex!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Inicia sesión o crea una cuenta para acceder a todas nuestras funcionalidades',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToLogin(context),
                  icon: const Icon(Icons.login),
                  label: const Text(
                    'Iniciar Sesión',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _navigateToRegister(context),
                  icon: const Icon(Icons.person_add),
                  label: const Text(
                    'Registrarse',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    side: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        '¿Por qué crear una cuenta?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildBenefitItem(
                        Icons.shopping_cart,
                        'Realizar pedidos online',
                      ),
                      _buildBenefitItem(
                        Icons.history,
                        'Ver tu historial de pedidos',
                      ),
                      _buildBenefitItem(
                        Icons.favorite,
                        'Guardar tus productos favoritos',
                      ),
                      _buildBenefitItem(
                        Icons.notifications,
                        'Recibir notificaciones',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginVista()),
    );
  }

  void _navigateToRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistroVista()),
    );
  }
}
