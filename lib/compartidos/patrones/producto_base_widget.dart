import 'package:flutter/material.dart';
// import '../../modelos/producto_modelo.dart'; // TODO: Create ProductoModelo when needed
import '../ui/buttons/app_button.dart';
import '../ui/buttons/button_base.dart';
import 'base_widget.dart';

// Placeholder for ProductoModelo until it's created
class ProductoModelo {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String categoria;
  final List<String> imagenes;
  final bool activo;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final double? descuento;
  final int stock;
  final double rating;

  ProductoModelo({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.categoria,
    required this.imagenes,
    required this.activo,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.descuento,
    this.stock = 0,
    this.rating = 0.0,
  });
}

abstract class ProductoBaseWidget extends BaseWidget<ProductoModelo> {
  const ProductoBaseWidget({
    super.key,
    super.data,
    super.onTap,
    super.margin,
    super.padding,
    super.isSelected,
    super.isEnabled,
  });

  Widget buildPrecio(BuildContext context) {
    if (data == null) return const SizedBox.shrink();

    return Text(
      'S/. ${data!.precio.toStringAsFixed(0)}',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget buildDescuento(BuildContext context) {
    if (data == null || data!.descuento == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '-${data!.descuento}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget buildEstadoStock(BuildContext context) {
    if (data == null) return const SizedBox.shrink();

    Color color;
    String texto;
    IconData icono;

    if (data!.stock == 0) {
      color = Colors.red;
      texto = 'Agotado';
      icono = Icons.remove_circle;
    } else if (data!.stock <= 5) {
      color = Colors.orange;
      texto = 'Últimas unidades';
      icono = Icons.warning;
    } else {
      color = Colors.green;
      texto = 'Disponible';
      icono = Icons.check_circle;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          texto,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget buildCategoria(BuildContext context) {
    if (data == null || data!.categoria.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        data!.categoria,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget buildImagen(BuildContext context, {double? width, double? height}) {
    if (data == null || data!.imagenes.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.image_not_supported,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 48,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        data!.imagenes.first,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.broken_image,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 48,
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }

  Widget buildRating(BuildContext context) {
    if (data == null || data!.rating == 0) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          color: Colors.amber,
          size: 16,
        ),
        const SizedBox(width: 2),
        Text(
          data!.rating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class ProductoCardCliente extends ProductoBaseWidget {
  final VoidCallback? onAgregarCarrito;
  final VoidCallback? onVerDetalles;

  const ProductoCardCliente({
    super.key,
    super.data,
    super.onTap,
    super.margin,
    super.padding,
    this.onAgregarCarrito,
    this.onVerDetalles,
  });

  @override
  Widget buildContent(BuildContext context) {
    if (data == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagen con descuento
        Stack(
          children: [
            buildImagen(context, height: 150),
            if (data!.descuento != null && data!.descuento! > 0)
              Positioned(
                top: 8,
                right: 8,
                child: buildDescuento(context),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Categoría
        buildCategoria(context),

        const SizedBox(height: 8),

        // Nombre
        Text(
          data!.nombre,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        // Descripción
        Text(
          data!.descripcion,
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 8),

        // Rating y stock
        Row(
          children: [
            buildRating(context),
            const Spacer(),
            buildEstadoStock(context),
          ],
        ),

        const SizedBox(height: 12),

        // Precio y botones
        Row(
          children: [
            Expanded(child: buildPrecio(context)),
            AppIconButton(
              icon: const Icon(Icons.visibility),
              onPressed: onVerDetalles,
              size: ButtonSize.small,
            ),
            const SizedBox(width: 8),
            AppIconButton(
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: data!.stock > 0 ? onAgregarCarrito : null,
              size: ButtonSize.small,
              variant: ButtonVariant.primary,
            ),
          ],
        ),
      ],
    );
  }
}

class ProductoCardAdmin extends ProductoBaseWidget {
  final VoidCallback? onEditar;
  final VoidCallback? onEliminar;
  final VoidCallback? onCambiarEstado;

  const ProductoCardAdmin({
    super.key,
    super.data,
    super.onTap,
    super.margin,
    super.padding,
    this.onEditar,
    this.onEliminar,
    this.onCambiarEstado,
  });

  @override
  Widget buildContent(BuildContext context) {
    if (data == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con estado y acciones
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: data!.activo ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                data!.activo ? 'Activo' : 'Inactivo',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'editar',
                  child: Row(
                    children: [
                      const Icon(Icons.edit),
                      const SizedBox(width: 8),
                      const Text('Editar'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'estado',
                  child: Row(
                    children: [
                      Icon(data!.activo ? Icons.visibility_off : Icons.visibility),
                      const SizedBox(width: 8),
                      Text(data!.activo ? 'Desactivar' : 'Activar'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'eliminar',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'editar':
                    onEditar?.call();
                    break;
                  case 'estado':
                    onCambiarEstado?.call();
                    break;
                  case 'eliminar':
                    onEliminar?.call();
                    break;
                }
              },
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Imagen
        buildImagen(context, height: 120),

        const SizedBox(height: 12),

        // Nombre y categoría
        Text(
          data!.nombre,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        buildCategoria(context),

        const SizedBox(height: 8),

        // Precio y stock
        Row(
          children: [
            Expanded(child: buildPrecio(context)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Stock: ${data!.stock}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                buildEstadoStock(context),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class ProductoListTile extends BaseListTile<ProductoModelo> {
  final VoidCallback? onAgregarCarrito;
  final VoidCallback? onEditar;

  const ProductoListTile({
    super.key,
    required super.data,
    super.onTap,
    super.onLongPress,
    super.trailing,
    super.isSelected,
    super.isEnabled,
    super.contentPadding,
    this.onAgregarCarrito,
    this.onEditar,
  });

  @override
  Widget buildTitle(BuildContext context) {
    return Text(
      data.nombre,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w500,
      ),
    );
  }

  @override
  Widget buildSubtitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          data.descripcion,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'S/. ${data.precio.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: data.stock > 0 ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Stock: ${data.stock}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return super.build(context).copyWith(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: data.imagenes.isNotEmpty
            ? Image.network(
                data.imagenes.first,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image),
                  );
                },
              )
            : Container(
                width: 60,
                height: 60,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.image_not_supported),
              ),
      ),
      trailing: trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onAgregarCarrito != null)
                IconButton(
                  icon: const Icon(Icons.add_shopping_cart),
                  onPressed: data.stock > 0 ? onAgregarCarrito : null,
                ),
              if (onEditar != null)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: onEditar,
                ),
            ],
          ),
    );
  }
}

extension WidgetExtension on Widget {
  Widget copyWith({
    Widget? leading,
    Widget? trailing,
  }) {
    if (this is ListTile) {
      final listTile = this as ListTile;
      return ListTile(
        leading: leading ?? listTile.leading,
        title: listTile.title,
        subtitle: listTile.subtitle,
        trailing: trailing ?? listTile.trailing,
        onTap: listTile.onTap,
        onLongPress: listTile.onLongPress,
        selected: listTile.selected,
        enabled: listTile.enabled,
        contentPadding: listTile.contentPadding,
        shape: listTile.shape,
      );
    }
    return this;
  }
}