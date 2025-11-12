import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../servicios/actividades_service.dart';

class ActividadesScreen extends StatefulWidget {
  const ActividadesScreen({super.key});

  @override
  State<ActividadesScreen> createState() => _ActividadesScreenState();
}

class _ActividadesScreenState extends State<ActividadesScreen> {
  final ActividadesService _actividadesService = ActividadesService();
  String _filtroTipo = 'todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actividad del Sistema'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filtroTipo = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'todos',
                child: Text('Todas las actividades'),
              ),
              const PopupMenuItem(
                value: 'pedido',
                child: Text('Pedidos'),
              ),
              const PopupMenuItem(
                value: 'registro',
                child: Text('Registros'),
              ),
              const PopupMenuItem(
                value: 'credenciales',
                child: Text('Cambios de credenciales'),
              ),
              const PopupMenuItem(
                value: 'notificacion',
                child: Text('Notificaciones'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _filtroTipo == 'todos'
            ? _actividadesService.obtenerTodasLasActividades()
            : _actividadesService.obtenerActividadesPorTipo(_filtroTipo),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Tratar errores (como colección no existente o permisos) como sin actividades
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 24),
                  const Text(
                    'No hay actividades aún',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Las actividades del sistema aparecerán aquí',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          final actividades = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: actividades.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final actividad = actividades[index].data() as Map<String, dynamic>;
              return _buildActividadItem(actividad);
            },
          );
        },
      ),
    );
  }

  Widget _buildActividadItem(Map<String, dynamic> actividad) {
    final tipo = actividad['tipo'] ?? '';
    final descripcion = actividad['descripcion'] ?? '';
    final usuarioNombre = actividad['usuarioNombre'] ?? 'Usuario desconocido';
    final fecha = actividad['fecha'] as Timestamp?;

    final iconData = _getIconForTipo(tipo);
    final color = _getColorForTipo(tipo);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(iconData, color: color, size: 24),
      ),
      title: Text(
        descripcion,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            usuarioNombre,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          if (fecha != null) ...[
            const SizedBox(height: 2),
            Text(
              _formatearFecha(fecha),
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _getTipoLabel(tipo),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  IconData _getIconForTipo(String tipo) {
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

  Color _getColorForTipo(String tipo) {
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

  String _getTipoLabel(String tipo) {
    switch (tipo) {
      case 'pedido':
        return 'Pedido';
      case 'registro':
        return 'Registro';
      case 'credenciales':
        return 'Credenciales';
      case 'notificacion':
        return 'Notificación';
      default:
        return 'Otro';
    }
  }

  String _formatearFecha(Timestamp timestamp) {
    final fecha = timestamp.toDate();
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inMinutes < 1) {
      return 'Hace un momento';
    } else if (diferencia.inHours < 1) {
      return 'Hace ${diferencia.inMinutes} min';
    } else if (diferencia.inDays < 1) {
      return 'Hace ${diferencia.inHours} h';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays} d';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
    }
  }
}
