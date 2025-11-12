import 'package:flutter/material.dart';
import 'package:reposteria_arlex/features/informacion_negocio/vistas/editar_informacion_vista.dart';
import '../admin/configuracion_sistema_vista.dart';
import '../../providers/auth_provider_simple.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.instance;
    final usuarioId = authProvider.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrativo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              Navigator.of(context).pushReplacementNamed('/');
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildMenuCard(
              context,
              'Configuración del Sistema',
              'Gestiona módulos y características',
              Icons.settings,
              Colors.blue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConfiguracionSistemaVista(
                      usuarioId: usuarioId,
                    ),
                  ),
                );
              },
            ),
            _buildMenuCard(
              context,
              'Información del Negocio',
              'Edita datos, horarios y contacto',
              Icons.business,
              Colors.purple,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditarInformacionVista(),
                  ),
                );
              },
            ),
            _buildMenuCard(
              context,
              'Gestión de Productos',
              'Administra el catálogo',
              Icons.inventory,
              Colors.orange,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Próximamente disponible')),
                );
              },
            ),
            _buildMenuCard(
              context,
              'Pedidos',
              'Visualiza y gestiona pedidos',
              Icons.receipt_long,
              Colors.green,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Próximamente disponible')),
                );
              },
            ),
            _buildMenuCard(
              context,
              'Clientes',
              'Gestiona usuarios registrados',
              Icons.people,
              Colors.teal,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Próximamente disponible')),
                );
              },
            ),
            _buildMenuCard(
              context,
              'Reportes',
              'Estadísticas y análisis',
              Icons.bar_chart,
              Colors.indigo,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Próximamente disponible')),
                );
              },
            ),
            _buildMenuCard(
              context,
              'Promociones',
              'Crear y gestionar ofertas',
              Icons.local_offer,
              Colors.red,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Próximamente disponible')),
                );
              },
            ),
            _buildMenuCard(
              context,
              'Categorías',
              'Organiza tu catálogo',
              Icons.category,
              Colors.amber,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Próximamente disponible')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String titulo,
    String descripcion,
    IconData icono,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icono,
                  size: 40,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                descripcion,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
