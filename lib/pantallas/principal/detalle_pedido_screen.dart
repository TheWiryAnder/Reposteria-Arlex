import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetallePedidoScreen extends StatelessWidget {
  final String pedidoId;
  final Map<String, dynamic> pedido;

  const DetallePedidoScreen({
    super.key,
    required this.pedidoId,
    required this.pedido,
  });

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'en_proceso':
        return Colors.blue;
      case 'listo':
        return Colors.green;
      case 'completado':
        return Colors.teal;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoTexto(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_proceso':
        return 'En Proceso';
      case 'listo':
        return 'Listo para Recoger';
      case 'completado':
        return 'Completado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return estado;
    }
  }

  String _getEstadoDescripcion(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Tu pedido está en la cola de espera. Pronto comenzaremos a prepararlo.';
      case 'en_proceso':
        return 'Estamos preparando tu pedido con mucho cuidado.';
      case 'listo':
        return '¡Tu pedido está listo! Puedes recogerlo cuando gustes.';
      case 'completado':
        return 'Pedido entregado exitosamente. ¡Gracias por tu compra!';
      case 'cancelado':
        return 'Este pedido fue cancelado.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = pedido['estado'] as String? ?? 'pendiente';
    final numeroPedido = pedido['numeroPedido'] as String? ?? '';
    final items = pedido['items'] as List<dynamic>? ?? [];
    final total = (pedido['total'] as num?)?.toDouble() ?? 0.0;
    final subtotal = (pedido['subtotal'] as num?)?.toDouble() ?? 0.0;
    final costoEnvio = (pedido['costoEnvio'] as num?)?.toDouble() ?? 0.0;
    final metodoEntrega = pedido['metodoEntrega'] as String? ?? '';
    final metodoPago = pedido['metodoPago'] as String? ?? '';
    final direccionEntrega = pedido['direccionEntrega'] as String? ?? '';
    final notasCliente = pedido['notasCliente'] as String? ?? '';
    final fechaPedido = pedido['fechaPedido'] as Timestamp?;
    final tiempoEstimado = pedido['tiempoEstimadoCompletado'] as Timestamp?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Pedido'),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header con estado
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _getEstadoColor(estado),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        numeroPedido,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getEstadoTexto(estado),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getEstadoDescripcion(estado),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      if (tiempoEstimado != null && estado != 'completado' && estado != 'cancelado') ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule, color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Estimado: ${_formatearFecha(tiempoEstimado.toDate())}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Timeline de estado
                if (estado != 'cancelado')
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildTimeline(estado),
                  ),

                // Productos
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Productos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...items.map((item) => _buildProductoItem(item)),
                    ],
                  ),
                ),

                // Información de entrega
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información de Entrega',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.local_shipping,
                            'Método',
                            metodoEntrega == 'domicilio' ? 'Entrega a Domicilio' : 'Recoger en Tienda',
                          ),
                          if (metodoEntrega == 'domicilio' && direccionEntrega.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow(Icons.location_on, 'Dirección', direccionEntrega),
                          ],
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.payment,
                            'Pago',
                            _getNombreMetodoPago(metodoPago),
                          ),
                          if (notasCliente.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow(Icons.note, 'Notas', notasCliente),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Resumen de totales
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildTotalRow('Subtotal', subtotal),
                          if (costoEnvio > 0) ...[
                            const SizedBox(height: 8),
                            _buildTotalRow('Envío', costoEnvio),
                          ],
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'S/. ${total.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Fecha del pedido
                if (fechaPedido != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Pedido realizado el ${_formatearFechaCompleta(fechaPedido.toDate())}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(String estadoActual) {
    final estados = ['pendiente', 'en_proceso', 'listo', 'completado'];
    final estadoIndex = estados.indexOf(estadoActual);

    return Row(
      children: List.generate(estados.length, (index) {
        final isCompleted = index <= estadoIndex;
        final isLast = index == estados.length - 1;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted ? _getEstadoColor(estadoActual) : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : Icons.circle,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getEstadoTexto(estados[index]),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: isCompleted ? _getEstadoColor(estadoActual) : Colors.grey,
                        fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  height: 2,
                  width: 20,
                  color: index < estadoIndex ? _getEstadoColor(estadoActual) : Colors.grey[300],
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProductoItem(Map<String, dynamic> item) {
    final nombre = item['productoNombre'] as String? ?? '';
    final cantidad = item['cantidad'] as int? ?? 0;
    final precio = (item['precioUnitario'] as num?)?.toDouble() ?? 0.0;
    final subtotal = (item['subtotal'] as num?)?.toDouble() ?? 0.0;
    final imagenUrl = item['productoImagen'] as String? ?? item['imagenUrl'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del producto
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imagenUrl.isNotEmpty
                  ? Image.network(
                      imagenUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.cake, color: Colors.grey, size: 30);
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                          ),
                        );
                      },
                    )
                  : const Icon(Icons.cake, color: Colors.grey, size: 30),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$cantidad x S/. ${precio.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            'S/. ${subtotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, double monto) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          'S/. ${monto.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getNombreMetodoPago(String metodo) {
    switch (metodo) {
      case 'efectivo':
        return 'Efectivo';
      case 'transferencia':
        return 'Transferencia Bancaria';
      case 'tarjeta':
        return 'Tarjeta';
      default:
        return metodo;
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  String _formatearFechaCompleta(DateTime fecha) {
    final meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year} a las ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }
}
