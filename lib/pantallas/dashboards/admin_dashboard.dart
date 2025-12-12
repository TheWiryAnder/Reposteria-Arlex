import 'package:flutter/material.dart';
import 'package:reposteria_arlex/features/informacion_negocio/vistas/editar_informacion_vista.dart';
import '../admin/configuracion_sistema_vista.dart';
import '../../providers/auth_provider_simple.dart';
import '../../servicios/reporte_excel_service.dart';
import '../../servicios/reporte_csv_service.dart';
import '../../servicios/reporte_pdf_service.dart';

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
              () => _mostrarModalReportes(context),
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

  /// Mostrar modal de Estadísticas y Reportes con opciones de descarga
  void _mostrarModalReportes(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título del modal
                Row(
                  children: [
                    Icon(
                      Icons.bar_chart,
                      size: 32,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Estadísticas y Reportes',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Descarga reportes completos con datos de productos, pedidos, usuarios y promociones',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Botón Descargar Excel
                _buildBotonDescarga(
                  context: context,
                  titulo: 'Descargar Excel',
                  descripcion: 'Archivo .xlsx con múltiples hojas y datos organizados',
                  icono: Icons.table_chart,
                  color: Colors.green,
                  onPressed: () => _descargarExcel(context),
                ),
                const SizedBox(height: 12),

                // Botón Descargar CSV
                _buildBotonDescarga(
                  context: context,
                  titulo: 'Descargar CSV',
                  descripcion: 'Archivo .csv compatible con Excel y otras aplicaciones',
                  icono: Icons.description,
                  color: Colors.blue,
                  onPressed: () => _descargarCsv(context),
                ),
                const SizedBox(height: 12),

                // Botón Descargar PDF
                _buildBotonDescarga(
                  context: context,
                  titulo: 'Descargar PDF',
                  descripcion: 'Reporte visual con gráficos y tablas formateadas',
                  icono: Icons.picture_as_pdf,
                  color: Colors.red,
                  onPressed: () => _descargarPdf(context),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Nota informativa
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Los reportes incluyen datos actualizados de todas las colecciones',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
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

  /// Widget para construir un botón de descarga
  Widget _buildBotonDescarga({
    required BuildContext context,
    required String titulo,
    required String descripcion,
    required IconData icono,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icono, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descripcion,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.download, color: color),
          ],
        ),
      ),
    );
  }

  /// Descargar reporte en formato Excel
  Future<void> _descargarExcel(BuildContext context) async {
    try {
      // Mostrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Generando reporte Excel...'),
            ],
          ),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );

      // Generar y descargar el reporte
      final service = ReporteExcelService();
      await service.generarReporteCompleto();

      // Mostrar mensaje de éxito
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Reporte Excel descargado exitosamente'),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Mostrar mensaje de error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error al generar Excel: $e')),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Descargar reporte en formato CSV
  Future<void> _descargarCsv(BuildContext context) async {
    try {
      // Mostrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Generando reporte CSV...'),
            ],
          ),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.blue,
        ),
      );

      // Generar y descargar el reporte
      final service = ReporteCsvService();
      await service.generarReporteCompleto();

      // Mostrar mensaje de éxito
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Reporte CSV descargado exitosamente'),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      // Mostrar mensaje de error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error al generar CSV: $e')),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Descargar reporte en formato PDF
  Future<void> _descargarPdf(BuildContext context) async {
    try {
      // Mostrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Generando reporte PDF...'),
            ],
          ),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );

      // Generar y descargar el reporte
      final service = ReportePdfService();
      await service.generarReporteCompleto();

      // Mostrar mensaje de éxito
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Reporte PDF descargado exitosamente'),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Mostrar mensaje de error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error al generar PDF: $e')),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
