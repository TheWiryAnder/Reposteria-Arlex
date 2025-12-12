import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../servicios/boleta_pdf_service.dart';

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
                      _buildProductosTabla(items),
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

                // Botón de descarga de boleta
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _descargarBoleta(context),
                      icon: const Icon(Icons.download),
                      label: const Text(
                        'Descargar Boleta',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Future<void> _descargarBoleta(BuildContext context) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final numeroPedido = pedido['numeroPedido'] as String? ?? '';
      final estado = pedido['estado'] as String? ?? 'pendiente';
      final items = pedido['items'] as List<dynamic>? ?? [];
      final total = (pedido['total'] as num?)?.toDouble() ?? 0.0;
      final subtotal = (pedido['subtotal'] as num?)?.toDouble() ?? 0.0;
      final costoEnvio = (pedido['costoEnvio'] as num?)?.toDouble() ?? 0.0;
      final metodoEntrega = pedido['metodoEntrega'] as String? ?? '';
      final metodoPago = pedido['metodoPago'] as String? ?? '';
      final direccionEntrega = pedido['direccionEntrega'] as String? ?? '';
      final notasCliente = pedido['notasCliente'] as String? ?? '';
      final fechaPedido = pedido['fechaPedido'] as Timestamp?;

      final fecha = fechaPedido != null
          ? _formatearFechaCompleta(fechaPedido.toDate())
          : 'Fecha no disponible';

      // Convertir items a formato Map<String, dynamic>
      final itemsList = items.map((item) => item as Map<String, dynamic>).toList();

      await BoletaPdfService.generarYDescargarBoleta(
        numeroPedido: numeroPedido,
        fecha: fecha,
        estado: estado,
        items: itemsList,
        subtotal: subtotal,
        costoEnvio: costoEnvio,
        total: total,
        metodoEntrega: metodoEntrega,
        metodoPago: metodoPago,
        direccionEntrega: direccionEntrega.isNotEmpty ? direccionEntrega : null,
        notasCliente: notasCliente.isNotEmpty ? notasCliente : null,
      );

      // Cerrar el indicador de carga
      if (context.mounted) {
        Navigator.of(context).pop();

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Boleta descargada exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Cerrar el indicador de carga si está abierto
      if (context.mounted) {
        Navigator.of(context).pop();

        // Mostrar mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar la boleta: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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

  Widget _buildProductosTabla(List<dynamic> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 600;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              // Encabezado de la tabla
              if (!isMobile)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 50, child: Text('Cant.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  SizedBox(width: 60),
                  Expanded(flex: 2, child: Text('Producto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 3, child: Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  SizedBox(width: 80, child: Text('Descuento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                  SizedBox(width: 90, child: Text('P. Unitario', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                  SizedBox(width: 90, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                ],
              ),
            ),

              // Items del pedido
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isLast = index == items.length - 1;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: !isLast ? Border(bottom: BorderSide(color: Colors.grey.shade200)) : null,
                  ),
                  child: isMobile
                      ? _buildMobileItemRow(item)
                      : _buildDesktopItemRow(item),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopItemRow(Map<String, dynamic> item) {
    final nombre = item['productoNombre'] as String? ?? '';
    final cantidad = item['cantidad'] as int? ?? 0;
    final precio = (item['precioUnitario'] as num?)?.toDouble() ?? 0.0;
    final subtotal = (item['subtotal'] as num?)?.toDouble() ?? 0.0;
    final imagenUrl = item['productoImagen'] as String? ?? item['imagenUrl'] as String? ?? '';
    final descripcion = item['productoDescripcion'] as String? ?? item['descripcion'] as String? ?? '';
    final descuento = (item['descuento'] as num?)?.toDouble() ?? 0.0;
    final tieneDescuento = descuento > 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Cantidad
        SizedBox(
          width: 50,
          child: Text(
            '${cantidad}x',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),

        // Imagen del producto
        SizedBox(
          width: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imagenUrl.isNotEmpty
                ? Image.network(
                    imagenUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.cake, size: 24),
                      );
                    },
                  )
                : Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.cake, size: 24),
                  ),
          ),
        ),

        // Nombre del producto
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              nombre,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // Descripción
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              descripcion,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // Descuento
        SizedBox(
          width: 80,
          child: tieneDescuento
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    '-${descuento.toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : const Text(
                  '-',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
        ),

        // Precio unitario
        SizedBox(
          width: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (tieneDescuento)
                Text(
                  'S/. ${(precio / (1 - descuento / 100)).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 10,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey,
                  ),
                ),
              Text(
                'S/. ${precio.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),

        // Total
        SizedBox(
          width: 90,
          child: Text(
            'S/. ${subtotal.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileItemRow(Map<String, dynamic> item) {
    final nombre = item['productoNombre'] as String? ?? '';
    final cantidad = item['cantidad'] as int? ?? 0;
    final precio = (item['precioUnitario'] as num?)?.toDouble() ?? 0.0;
    final subtotal = (item['subtotal'] as num?)?.toDouble() ?? 0.0;
    final imagenUrl = item['productoImagen'] as String? ?? item['imagenUrl'] as String? ?? '';
    final descripcion = item['productoDescripcion'] as String? ?? item['descripcion'] as String? ?? '';
    final descuento = (item['descuento'] as num?)?.toDouble() ?? 0.0;
    final tieneDescuento = descuento > 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagen
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imagenUrl.isNotEmpty
              ? Image.network(
                  imagenUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.cake, size: 30),
                    );
                  },
                )
              : Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.cake, size: 30),
                ),
        ),
        const SizedBox(width: 12),

        // Info del producto
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (descripcion.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  descripcion,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '$cantidad x S/. ${precio.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (tieneDescuento) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        '-${descuento.toInt()}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Total
        Text(
          'S/. ${subtotal.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
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
