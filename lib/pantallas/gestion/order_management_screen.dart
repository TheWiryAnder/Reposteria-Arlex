import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../servicios/notificaciones_service.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Pedidos'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('pedidos')
                .orderBy('fechaPedido', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay pedidos registrados',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              // Agrupar pedidos por cliente
              final pedidos = snapshot.data!.docs;
              final Map<String, List<DocumentSnapshot>> pedidosPorCliente = {};

              for (var pedido in pedidos) {
                final data = pedido.data() as Map<String, dynamic>;
                final clienteNombre = data['clienteNombre'] ?? 'Cliente Desconocido';

                if (!pedidosPorCliente.containsKey(clienteNombre)) {
                  pedidosPorCliente[clienteNombre] = [];
                }
                pedidosPorCliente[clienteNombre]!.add(pedido);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pedidosPorCliente.length,
                itemBuilder: (context, index) {
                  final clienteNombre = pedidosPorCliente.keys.elementAt(index);
                  final pedidosCliente = pedidosPorCliente[clienteNombre]!;

                  return _buildClienteCard(clienteNombre, pedidosCliente);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildClienteCard(String clienteNombre, List<DocumentSnapshot> pedidos) {
    final totalPedidos = pedidos.length;
    double totalGastado = 0;

    for (var pedido in pedidos) {
      final data = pedido.data() as Map<String, dynamic>;
      totalGastado += (data['total'] ?? 0).toDouble();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _verPedidosCliente(clienteNombre, pedidos),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.orange,
                radius: 30,
                child: Text(
                  clienteNombre.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clienteNombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalPedidos ${totalPedidos == 1 ? 'pedido' : 'pedidos'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total gastado: S/. ${totalGastado.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _verPedidosCliente(String clienteNombre, List<DocumentSnapshot> pedidos) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PedidosClienteScreen(
          clienteNombre: clienteNombre,
          pedidos: pedidos,
        ),
      ),
    );
  }
}

// Pantalla para mostrar todos los pedidos de un cliente
class PedidosClienteScreen extends StatefulWidget {
  final String clienteNombre;
  final List<DocumentSnapshot> pedidos;

  const PedidosClienteScreen({
    super.key,
    required this.clienteNombre,
    required this.pedidos,
  });

  @override
  State<PedidosClienteScreen> createState() => _PedidosClienteScreenState();
}

class _PedidosClienteScreenState extends State<PedidosClienteScreen> {
  final Map<String, String> _estadosActuales = {};

  @override
  void initState() {
    super.initState();
    // Inicializar estados actuales
    for (var pedido in widget.pedidos) {
      final data = pedido.data() as Map<String, dynamic>;
      _estadosActuales[pedido.id] = data['estado'] ?? 'pendiente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedidos de ${widget.clienteNombre}'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.pedidos.length,
            itemBuilder: (context, index) {
              final pedido = widget.pedidos[index];
              final data = pedido.data() as Map<String, dynamic>;

              return _buildPedidoCard(context, pedido.id, data);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPedidoCard(BuildContext context, String pedidoId, Map<String, dynamic> data) {
    final numeroPedido = data['numeroPedido'] ?? pedidoId;
    final total = (data['total'] ?? 0).toDouble();
    final estado = _estadosActuales[pedidoId] ?? data['estado'] ?? 'pendiente';
    final fechaPedido = (data['fechaPedido'] as Timestamp?)?.toDate();
    final items = data['items'] as List<dynamic>? ?? [];
    final metodoEntrega = data['metodoEntrega'] ?? 'N/A';

    Color estadoColor;
    String estadoTexto;
    switch (estado.toLowerCase()) {
      case 'pendiente':
        estadoColor = Colors.orange;
        estadoTexto = 'PENDIENTE';
        break;
      case 'en_proceso':
        estadoColor = Colors.blue;
        estadoTexto = 'EN PROCESO';
        break;
      case 'listo':
        estadoColor = Colors.purple;
        estadoTexto = 'LISTO';
        break;
      case 'completado':
        estadoColor = Colors.green;
        estadoTexto = 'COMPLETADO';
        break;
      case 'cancelado':
        estadoColor = Colors.red;
        estadoTexto = 'CANCELADO';
        break;
      default:
        estadoColor = Colors.grey;
        estadoTexto = estado.toUpperCase();
    }

    // Verificar si el pedido puede cambiar de estado
    final puedeModificar = estado != 'cancelado' && estado != 'completado';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila superior: Número de pedido y badge de estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido #$numeroPedido',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (fechaPedido != null)
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(fechaPedido),
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: estadoColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    estadoTexto,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Información básica del pedido
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total: S/. ${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${items.length} ${items.length == 1 ? 'producto' : 'productos'} • $metodoEntrega',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Botón para ver detalle
                IconButton(
                  icon: const Icon(Icons.visibility_outlined),
                  tooltip: 'Ver detalle completo',
                  onPressed: () => _verDetallePedido(context, pedidoId, data),
                ),
              ],
            ),

            // Controles de cambio de estado rápido
            if (puedeModificar) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.swap_horiz, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text(
                    'Cambiar estado:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _buildEstadoBotones(pedidoId, estado, data),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEstadoBotones(String pedidoId, String estadoActual, Map<String, dynamic> data) {
    final estados = [
      {'valor': 'pendiente', 'texto': 'Pendiente', 'icono': Icons.schedule, 'color': Colors.orange},
      {'valor': 'en_proceso', 'texto': 'En Proceso', 'icono': Icons.pending_actions, 'color': Colors.blue},
      {'valor': 'listo', 'texto': 'Listo', 'icono': Icons.check_circle_outline, 'color': Colors.purple},
      {'valor': 'completado', 'texto': 'Completado', 'icono': Icons.done_all, 'color': Colors.green},
      {'valor': 'cancelado', 'texto': 'Cancelar', 'icono': Icons.cancel, 'color': Colors.red},
    ];

    return estados.map((estado) {
      final esEstadoActual = estadoActual == estado['valor'];
      final color = estado['color'] as Color;

      return ActionChip(
        avatar: Icon(
          estado['icono'] as IconData,
          size: 16,
          color: esEstadoActual ? Colors.white : color,
        ),
        label: Text(
          estado['texto'] as String,
          style: TextStyle(
            fontSize: 11,
            fontWeight: esEstadoActual ? FontWeight.bold : FontWeight.normal,
            color: esEstadoActual ? Colors.white : color,
          ),
        ),
        backgroundColor: esEstadoActual ? color : color.withValues(alpha: 0.1),
        side: BorderSide(
          color: esEstadoActual ? color : color.withValues(alpha: 0.3),
          width: esEstadoActual ? 2 : 1,
        ),
        onPressed: esEstadoActual
            ? null
            : () => _cambiarEstadoRapido(pedidoId, estado['valor'] as String, data),
      );
    }).toList();
  }

  Future<void> _cambiarEstadoRapido(String pedidoId, String nuevoEstado, Map<String, dynamic> data) async {
    // Confirmar si es cancelación
    if (nuevoEstado == 'cancelado') {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancelar Pedido'),
          content: const Text('¿Estás seguro de que deseas cancelar este pedido?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sí, Cancelar'),
            ),
          ],
        ),
      );

      if (confirmar != true) return;
    }

    try {
      final estadoAnterior = _estadosActuales[pedidoId] ?? data['estado'] ?? 'pendiente';

      // Actualizar en Firestore
      await FirebaseFirestore.instance
          .collection('pedidos')
          .doc(pedidoId)
          .update({
        'estado': nuevoEstado,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      // Actualizar estado local
      setState(() {
        _estadosActuales[pedidoId] = nuevoEstado;
      });

      // Enviar notificación al cliente
      final clienteId = data['clienteId'] as String?;
      final numeroPedido = data['numeroPedido'] ?? pedidoId;

      if (clienteId != null) {
        final notificacionesService = NotificacionesService();
        await notificacionesService.notificarCambioEstadoPedido(
          userId: clienteId,
          pedidoId: pedidoId,
          numeroPedido: numeroPedido.toString(),
          estadoAnterior: estadoAnterior,
          estadoNuevo: nuevoEstado,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado actualizado a ${_getEstadoTexto(nuevoEstado)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _getEstadoTexto(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_proceso':
        return 'En Proceso';
      case 'listo':
        return 'Listo';
      case 'completado':
        return 'Completado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return estado;
    }
  }

  void _verDetallePedido(BuildContext context, String pedidoId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetallePedidoScreen(
          pedidoId: pedidoId,
          pedidoData: data,
        ),
      ),
    );
  }
}

// Pantalla de detalle del pedido con opción de editar/cancelar
class DetallePedidoScreen extends StatefulWidget {
  final String pedidoId;
  final Map<String, dynamic> pedidoData;

  const DetallePedidoScreen({
    super.key,
    required this.pedidoId,
    required this.pedidoData,
  });

  @override
  State<DetallePedidoScreen> createState() => _DetallePedidoScreenState();
}

class _DetallePedidoScreenState extends State<DetallePedidoScreen> {
  late String _estadoActual;

  @override
  void initState() {
    super.initState();
    _estadoActual = widget.pedidoData['estado'] ?? 'pendiente';
  }

  @override
  Widget build(BuildContext context) {
    final numeroPedido = widget.pedidoData['numeroPedido'] ?? widget.pedidoId;
    final clienteNombre = widget.pedidoData['clienteNombre'] ?? 'Cliente';
    final clienteTelefono = widget.pedidoData['clienteTelefono'] ?? 'N/A';
    final clienteEmail = widget.pedidoData['clienteEmail'] ?? 'N/A';
    final direccion = widget.pedidoData['direccionEntrega'] ?? 'N/A';
    final metodoPago = widget.pedidoData['metodoPago'] ?? 'N/A';
    final metodoEntrega = widget.pedidoData['metodoEntrega'] ?? 'N/A';
    final items = widget.pedidoData['items'] as List<dynamic>? ?? [];
    final subtotal = (widget.pedidoData['subtotal'] ?? 0).toDouble();
    final costoEnvio = (widget.pedidoData['costoEnvio'] ?? 0).toDouble();
    final descuento = (widget.pedidoData['descuento'] ?? 0).toDouble();
    final total = (widget.pedidoData['total'] ?? 0).toDouble();
    final fechaPedido = (widget.pedidoData['fechaPedido'] as Timestamp?)?.toDate();

    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido #$numeroPedido'),
        backgroundColor: Colors.orange,
        actions: [
          if (_estadoActual != 'cancelado' && _estadoActual != 'entregado')
            IconButton(
              icon: const Icon(Icons.cancel),
              tooltip: 'Cancelar Pedido',
              onPressed: _cancelarPedido,
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Información del cliente
            _buildSeccion(
              'Información del Cliente',
              [
                _buildInfoRow('Nombre', clienteNombre),
                _buildInfoRow('Teléfono', clienteTelefono),
                _buildInfoRow('Email', clienteEmail),
                if (metodoEntrega == 'domicilio')
                  _buildInfoRow('Dirección', direccion),
              ],
            ),
            const SizedBox(height: 16),

            // Información del pedido
            _buildSeccion(
              'Información del Pedido',
              [
                if (fechaPedido != null)
                  _buildInfoRow(
                    'Fecha',
                    DateFormat('dd/MM/yyyy HH:mm').format(fechaPedido),
                  ),
                _buildInfoRow('Método de Pago', metodoPago.toUpperCase()),
                _buildInfoRow('Método de Entrega', metodoEntrega.toUpperCase()),
              ],
            ),
            const SizedBox(height: 16),

            // Estado del pedido
            _buildSeccion(
              'Estado del Pedido',
              [
                DropdownButtonFormField<String>(
                  value: _estadoActual,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Estado',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                    DropdownMenuItem(value: 'confirmado', child: Text('Confirmado')),
                    DropdownMenuItem(
                      value: 'en preparacion',
                      child: Text('En Preparación'),
                    ),
                    DropdownMenuItem(value: 'listo', child: Text('Listo')),
                    DropdownMenuItem(value: 'en camino', child: Text('En Camino')),
                    DropdownMenuItem(value: 'entregado', child: Text('Entregado')),
                    DropdownMenuItem(value: 'cancelado', child: Text('Cancelado')),
                  ],
                  onChanged: _estadoActual == 'cancelado' || _estadoActual == 'entregado'
                      ? null
                      : (value) {
                          if (value != null) {
                            _actualizarEstado(value);
                          }
                        },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Productos
            _buildSeccion(
              'Productos',
              items
                  .map((item) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(item['productoNombre'] ?? 'Producto'),
                          subtitle: Text(
                            'Cantidad: ${item['cantidad']} × S/. ${(item['precioUnitario'] ?? 0).toStringAsFixed(2)}',
                          ),
                          trailing: Text(
                            'S/. ${(item['subtotal'] ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Resumen de costos
            _buildSeccion(
              'Resumen',
              [
                _buildCostoRow('Subtotal', subtotal),
                if (costoEnvio > 0) _buildCostoRow('Costo de Envío', costoEnvio),
                if (descuento > 0) _buildCostoRow('Descuento', -descuento),
                const Divider(thickness: 2),
                _buildCostoRow('TOTAL', total, isBold: true),
              ],
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeccion(String titulo, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostoRow(String label, double valor, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 18 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            'S/. ${valor.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isBold ? 18 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _actualizarEstado(String nuevoEstado) async {
    try {
      final estadoAnterior = _estadoActual;

      await FirebaseFirestore.instance
          .collection('pedidos')
          .doc(widget.pedidoId)
          .update({
        'estado': nuevoEstado,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      setState(() {
        _estadoActual = nuevoEstado;
      });

      // Enviar notificación al cliente sobre el cambio de estado
      final clienteId = widget.pedidoData['clienteId'] as String?;
      final numeroPedido = widget.pedidoData['numeroPedido'] ?? widget.pedidoId;

      if (clienteId != null) {
        final notificacionesService = NotificacionesService();
        await notificacionesService.notificarCambioEstadoPedido(
          userId: clienteId,
          pedidoId: widget.pedidoId,
          numeroPedido: numeroPedido.toString(),
          estadoAnterior: estadoAnterior,
          estadoNuevo: nuevoEstado,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Estado actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelarPedido() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Pedido'),
        content: const Text('¿Estás seguro de que deseas cancelar este pedido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _actualizarEstado('cancelado');
    }
  }
}
