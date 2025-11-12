import 'package:flutter/material.dart';
import '../componentes/login/login_cabecera.dart';
import '../componentes/login/login_formulario.dart';
import '../controladores/auth_controlador.dart';
import '../../../providers/auth_provider.dart';

class LoginVista extends StatefulWidget {
  const LoginVista({super.key});

  @override
  State<LoginVista> createState() => _LoginVistaState();
}

class _LoginVistaState extends State<LoginVista> with TickerProviderStateMixin {
  late TabController _tabController;
  late AuthControlador _authController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _authController = AuthControlador(AuthProvider.instance);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Cabecera de la aplicación
              const LoginCabecera(),

              // Contenedor principal del formulario
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Pestañas de Login y Registro
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: Theme.of(context).primaryColor,
                        labelColor: Theme.of(context).primaryColor,
                        unselectedLabelColor: Colors.grey[600],
                        indicatorWeight: 3,
                        tabs: const [
                          Tab(
                            text: 'Iniciar Sesión',
                            icon: Icon(Icons.login),
                          ),
                          Tab(
                            text: 'Registrarse',
                            icon: Icon(Icons.person_add),
                          ),
                        ],
                      ),
                    ),

                    // Contenido de las pestañas
                    SizedBox(
                      height: 500, // Altura fija para evitar overflow
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Formulario de Login
                          LoginFormulario(
                            controller: _authController,
                            isRegisterMode: false,
                            onSuccess: () => _handleAuthSuccess(),
                          ),

                          // Formulario de Registro
                          LoginFormulario(
                            controller: _authController,
                            isRegisterMode: true,
                            onSuccess: () => _handleAuthSuccess(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Espacio inferior
              const SizedBox(height: 20),

              // Enlaces adicionales
              _buildFooterLinks(context),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterLinks(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () => _showForgotPasswordDialog(),
          child: Text(
            '¿Olvidaste tu contraseña?',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => _showTermsDialog(),
              child: const Text(
                'Términos y Condiciones',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
            const Text(' | ', style: TextStyle(color: Colors.grey)),
            TextButton(
              onPressed: () => _showPrivacyDialog(),
              child: const Text(
                'Política de Privacidad',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleAuthSuccess() {
    // Navegar a la pantalla principal según el rol del usuario
    final authProvider = AuthProvider.instance;
    final redirectRoute = authProvider.getRedirectRoute();

    Navigator.of(context).pushReplacementNamed(redirectRoute);
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Recuperar Contraseña'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ingresa tu email para recibir instrucciones de recuperación.',
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (emailController.text.isNotEmpty) {
                  final success = await _authController.requestPasswordReset(
                    emailController.text,
                  );

                  if (mounted) {
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? 'Se enviaron las instrucciones a tu email'
                            : 'Error al enviar las instrucciones'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Términos y Condiciones'),
          content: const SingleChildScrollView(
            child: Text(
              'Aquí van los términos y condiciones completos de la aplicación. '
              'Este es un texto de ejemplo que debería ser reemplazado por '
              'los términos reales de Repostería Arlex.\n\n'
              '1. Uso de la aplicación\n'
              '2. Política de pedidos\n'
              '3. Métodos de pago\n'
              '4. Política de entrega\n'
              '5. Cancelaciones y devoluciones\n\n'
              'Para más información, contacta con nosotros.',
            ),
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

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Política de Privacidad'),
          content: const SingleChildScrollView(
            child: Text(
              'Política de Privacidad de Repostería Arlex\n\n'
              'Recopilamos y procesamos tu información personal para:\n\n'
              '" Procesar tus pedidos\n'
              '" Mejorar nuestros servicios\n'
              '" Comunicarnos contigo\n'
              '" Cumplir con obligaciones legales\n\n'
              'Tus datos están protegidos y no los compartimos con terceros '
              'sin tu consentimiento, excepto cuando sea requerido por ley.\n\n'
              'Para más información sobre cómo manejamos tus datos, '
              'contacta con nosotros.',
            ),
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
}