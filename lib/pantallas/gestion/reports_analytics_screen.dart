import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportsAnalyticsScreen extends StatelessWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes y Analytics'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reportes')
            .orderBy('fechaGeneracion', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final errorMessage = snapshot.error.toString();
            final isPermissionError = errorMessage.contains('permission-denied');

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPermissionError ? Icons.lock_outline : Icons.error_outline,
                    size: 64,
                    color: isPermissionError ? Colors.orange : Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isPermissionError
                        ? 'Sin permisos para acceder a reportes'
                        : 'Error al cargar reportes',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      isPermissionError
                          ? 'Por favor, verifica que estés autenticado como administrador y que las reglas de Firebase permitan el acceso a la colección "reportes".'
                          : 'Ocurrió un error al cargar los reportes. Por favor, intenta de nuevo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reportes = snapshot.data?.docs ?? [];

          if (reportes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay reportes generados',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Los reportes descargados desde la sección de Estadísticas aparecerán aquí.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reportes.length,
            itemBuilder: (context, index) {
              final reporte = reportes[index];
              final data = reporte.data() as Map<String, dynamic>;
              return _buildReporteCard(context, reporte.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildReporteCard(
    BuildContext context,
    String reporteId,
    Map<String, dynamic> data,
  ) {
    final nombreArchivo = data['nombreArchivo'] ?? 'Reporte sin nombre';
    final tipo = data['tipo'] ?? 'excel';
    final tamanoBytes = data['tamañoBytes'] ?? 0;
    final usuarioNombre = data['usuarioNombre'] ?? 'Desconocido';
    final filtroFecha = data['filtroFecha'] ?? 'N/A';
    final filtroCategoria = data['filtroCategoria'] ?? 'all';

    final fechaGeneracion = data['fechaGeneracion'] as Timestamp?;
    final fechaFormateada = fechaGeneracion != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(fechaGeneracion.toDate())
        : 'Fecha desconocida';

    final tamanoFormateado = _formatBytes(tamanoBytes);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTipoColor(tipo),
          child: Icon(
            _getTipoIcon(tipo),
            color: Colors.white,
          ),
        ),
        title: Text(
          nombreArchivo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Generado por: $usuarioNombre'),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(fechaFormateada),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.folder, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Tamaño: $tamanoFormateado'),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [
                Chip(
                  label: Text(
                    _getNombreFiltroFecha(filtroFecha),
                    style: const TextStyle(fontSize: 11),
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Chip(
                  label: Text(
                    'Categoría: ${filtroCategoria == "all" ? "Todas" : filtroCategoria}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Descargar reporte',
              onPressed: () => _descargarReporte(context, data),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Ver detalles',
              onPressed: () => _mostrarDetallesReporte(context, data),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _descargarReporte(BuildContext context, Map<String, dynamic> data) async {
    final downloadUrl = data['downloadUrl'] as String?;
    final nombreArchivo = data['nombreArchivo'] ?? 'reporte';

    if (downloadUrl == null || downloadUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay URL de descarga disponible para este reporte'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Descargando: $nombreArchivo'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir el enlace de descarga'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Color _getTipoColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'excel':
        return Colors.green;
      case 'pdf':
        return Colors.red;
      case 'csv':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'excel':
        return Icons.table_chart;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'csv':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getNombreFiltroFecha(String filtro) {
    switch (filtro) {
      case '30_days':
        return 'Últimos 30 días';
      case 'this_month':
        return 'Este mes';
      case 'this_year':
        return 'Este año';
      default:
        return 'Todos';
    }
  }

  void _mostrarDetallesReporte(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles del Reporte'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetalleItem('Nombre del archivo', data['nombreArchivo'] ?? 'N/A'),
              const Divider(),
              _buildDetalleItem('Tipo', data['tipo']?.toString().toUpperCase() ?? 'N/A'),
              const Divider(),
              _buildDetalleItem('Tamaño', _formatBytes(data['tamañoBytes'] ?? 0)),
              const Divider(),
              _buildDetalleItem('Generado por', data['usuarioNombre'] ?? 'N/A'),
              const Divider(),
              _buildDetalleItem('Usuario ID', data['usuarioId'] ?? 'N/A'),
              const Divider(),
              _buildDetalleItem(
                'Fecha de generación',
                data['fechaGeneracion'] != null
                    ? DateFormat('dd/MM/yyyy HH:mm:ss')
                        .format((data['fechaGeneracion'] as Timestamp).toDate())
                    : 'N/A',
              ),
              const Divider(),
              _buildDetalleItem('Filtro de fecha', _getNombreFiltroFecha(data['filtroFecha'] ?? '')),
              const Divider(),
              _buildDetalleItem(
                'Filtro de categoría',
                data['filtroCategoria'] == 'all' ? 'Todas' : data['filtroCategoria'] ?? 'N/A',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
