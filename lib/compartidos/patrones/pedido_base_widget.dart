import 'package:flutter/material.dart';
// import '../../modelos/pedido_modelo.dart'; // TODO: Create PedidoModelo when needed
import '../ui/buttons/app_button.dart';
import '../ui/buttons/button_base.dart';
import 'base_widget.dart';

// Placeholder for PedidoModelo until it's created
class PedidoModelo {
  final String id;
  final String numero;
  final String nombreCliente;
  final double total;
  final DateTime fechaCreacion;
  final DateTime? fechaEntrega;
  final EstadoPedido estado;
  final MetodoPago metodoPago;
  final List<ItemPedido> items;

  PedidoModelo({
    required this.id,
    required this.numero,
    required this.nombreCliente,
    required this.total,
    required this.fechaCreacion,
    this.fechaEntrega,
    required this.estado,
    required this.metodoPago,
    required this.items,
  });
}

class ItemPedido {
  final String nombreProducto;
  final int cantidad;
  final double precio;

  ItemPedido({
    required this.nombreProducto,
    required this.cantidad,
    required this.precio,
  });
}

enum EstadoPedido {
  pendiente,
  confirmado,
  preparando,
  listo,
  entregado,
  cancelado,
}

enum MetodoPago {
  efectivo,
  transferencia,
  tarjeta,
}

abstract class PedidoBaseWidget extends BaseWidget<PedidoModelo> {
  const PedidoBaseWidget({
    super.key,
    super.data,
    super.onTap,
    super.margin,
    super.padding,
    super.isSelected,
    super.isEnabled,
  });

  Widget buildEstadoPedido(BuildContext context) {
    if (data == null) return const SizedBox.shrink();

    Color color;
    IconData icono;
    String texto;

    switch (data!.estado) {
      case EstadoPedido.pendiente:
        color = Colors.orange;
        icono = Icons.schedule;
        texto = 'Pendiente';
        break;
      case EstadoPedido.confirmado:
        color = Colors.blue;
        icono = Icons.check_circle;
        texto = 'Confirmado';
        break;
      case EstadoPedido.preparando:
        color = Colors.purple;
        icono = Icons.restaurant;
        texto = 'Preparando';
        break;
      case EstadoPedido.listo:
        color = Colors.green;
        icono = Icons.done_all;
        texto = 'Listo';
        break;
      case EstadoPedido.entregado:
        color = Colors.teal;
        icono = Icons.delivery_dining;
        texto = 'Entregado';
        break;
      case EstadoPedido.cancelado:
        color = Colors.red;
        icono = Icons.cancel;
        texto = 'Cancelado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTotal(BuildContext context) {
    if (data == null) return const SizedBox.shrink();

    return Text(
      'S/. ${data!.total.toStringAsFixed(0)}',
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget buildFecha(BuildContext context) {
    if (data == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha del pedido',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        Text(
          _formatearFecha(data!.fechaCreacion),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget buildFechaEntrega(BuildContext context) {
    if (data == null || data!.fechaEntrega == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha de entrega',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        Text(
          _formatearFecha(data!.fechaEntrega!),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget buildMetodoPago(BuildContext context) {
    if (data == null) return const SizedBox.shrink();

    IconData icono;
    Color color;

    switch (data!.metodoPago) {
      case MetodoPago.efectivo:
        icono = Icons.payments;
        color = Colors.green;
        break;
      case MetodoPago.transferencia:
        icono = Icons.account_balance;
        color = Colors.blue;
        break;
      case MetodoPago.tarjeta:
        icono = Icons.credit_card;
        color = Colors.purple;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          data!.metodoPago.name.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget buildCantidadItems(BuildContext context) {
    if (data == null) return const SizedBox.shrink();

    final totalItems = data!.items.fold<int>(
      0,
      (sum, item) => sum + item.cantidad,
    );

    return Text(
      '$totalItems ${totalItems == 1 ? 'item' : 'items'}',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }

  Widget buildResumenItems(BuildContext context, {int maxItems = 3}) {
    if (data == null || data!.items.isEmpty) return const SizedBox.shrink();

    final itemsToShow = data!.items.take(maxItems).toList();
    final remainingItems = data!.items.length - maxItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...itemsToShow.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Text(
                '${item.cantidad}x',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.nombreProducto,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'S/. ${(item.precio * item.cantidad).toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )),
        if (remainingItems > 0)
          Text(
            '+ $remainingItems más...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }
}

class PedidoCardCliente extends PedidoBaseWidget {
  final VoidCallback? onVerDetalles;
  final VoidCallback? onCancelar;
  final VoidCallback? onReordenar;

  const PedidoCardCliente({
    super.key,
    super.data,
    super.onTap,
    super.margin,
    super.padding,
    this.onVerDetalles,
    this.onCancelar,
    this.onReordenar,
  });

  @override
  Widget buildContent(BuildContext context) {
    if (data == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con número de pedido y estado
        Row(
          children: [
            Text(
              'Pedido #${data!.numero}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            buildEstadoPedido(context),
          ],
        ),

        const SizedBox(height: 12),

        // Fecha y método de pago
        Row(
          children: [
            Expanded(child: buildFecha(context)),
            buildMetodoPago(context),
          ],
        ),

        const SizedBox(height: 12),

        // Resumen de items
        buildResumenItems(context),

        const SizedBox(height: 12),

        // Total y cantidad de items
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildCantidadItems(context),
                  buildTotal(context),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Botones de acción
        Row(
          children: [
            Expanded(
              child: AppOutlineButton(
                text: 'Ver detalles',
                onPressed: onVerDetalles,
                size: ButtonSize.small,
              ),
            ),
            const SizedBox(width: 8),
            if (data!.estado == EstadoPedido.pendiente && onCancelar != null) ...[
              AppButton(
                text: 'Cancelar',
                onPressed: onCancelar,
                variant: ButtonVariant.danger,
                size: ButtonSize.small,
              ),
            ] else if (data!.estado == EstadoPedido.entregado && onReordenar != null) ...[
              AppButton(
                text: 'Reordenar',
                onPressed: onReordenar,
                size: ButtonSize.small,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class PedidoCardAdmin extends PedidoBaseWidget {
  final VoidCallback? onVerDetalles;
  final VoidCallback? onCambiarEstado;
  final VoidCallback? onContactarCliente;

  const PedidoCardAdmin({
    super.key,
    super.data,
    super.onTap,
    super.margin,
    super.padding,
    this.onVerDetalles,
    this.onCambiarEstado,
    this.onContactarCliente,
  });

  @override
  Widget buildContent(BuildContext context) {
    if (data == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido #${data!.numero}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    data!.nombreCliente,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            buildEstadoPedido(context),
          ],
        ),

        const SizedBox(height: 12),

        // Información de fechas
        Row(
          children: [
            Expanded(child: buildFecha(context)),
            if (data!.fechaEntrega != null)
              Expanded(child: buildFechaEntrega(context)),
          ],
        ),

        const SizedBox(height: 12),

        // Resumen de items
        buildResumenItems(context, maxItems: 2),

        const SizedBox(height: 12),

        // Total, método de pago y cantidad
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildCantidadItems(context),
                  buildTotal(context),
                ],
              ),
            ),
            buildMetodoPago(context),
          ],
        ),

        const SizedBox(height: 16),

        // Botones de acción
        Row(
          children: [
            Expanded(
              child: AppOutlineButton(
                text: 'Ver detalles',
                onPressed: onVerDetalles,
                size: ButtonSize.small,
              ),
            ),
            const SizedBox(width: 8),
            if (onCambiarEstado != null)
              AppButton(
                text: 'Cambiar estado',
                onPressed: onCambiarEstado,
                size: ButtonSize.small,
              ),
            const SizedBox(width: 8),
            if (onContactarCliente != null)
              AppIconButton(
                icon: const Icon(Icons.phone),
                onPressed: onContactarCliente,
                size: ButtonSize.small,
                variant: ButtonVariant.secondary,
              ),
          ],
        ),
      ],
    );
  }
}

class PedidoListTile extends BaseListTile<PedidoModelo> {
  final VoidCallback? onCambiarEstado;
  final VoidCallback? onContactar;

  const PedidoListTile({
    super.key,
    required super.data,
    super.onTap,
    super.onLongPress,
    super.trailing,
    super.isSelected,
    super.isEnabled,
    super.contentPadding,
    this.onCambiarEstado,
    this.onContactar,
  });

  @override
  Widget buildTitle(BuildContext context) {
    return Row(
      children: [
        Text(
          'Pedido #${data.numero}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        _buildEstado(context),
      ],
    );
  }

  @override
  Widget buildSubtitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(data.nombreCliente),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              'S/. ${data.total.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              _formatearFecha(data.fechaCreacion),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEstado(BuildContext context) {
    Color color;
    String texto;

    switch (data.estado) {
      case EstadoPedido.pendiente:
        color = Colors.orange;
        texto = 'Pendiente';
        break;
      case EstadoPedido.confirmado:
        color = Colors.blue;
        texto = 'Confirmado';
        break;
      case EstadoPedido.preparando:
        color = Colors.purple;
        texto = 'Preparando';
        break;
      case EstadoPedido.listo:
        color = Colors.green;
        texto = 'Listo';
        break;
      case EstadoPedido.entregado:
        color = Colors.teal;
        texto = 'Entregado';
        break;
      case EstadoPedido.cancelado:
        color = Colors.red;
        texto = 'Cancelado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }
}