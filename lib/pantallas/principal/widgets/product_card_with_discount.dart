import 'package:flutter/material.dart';
import '../../../modelos/producto_modelo.dart';
import '../../../providers/auth_provider_simple.dart';
import '../../../providers/carrito_provider.dart';
import '../../../compartidos/widgets/message_helpers.dart';
import '../../auth/login_vista.dart';

/// Widget con estado para mostrar tarjetas de productos en promoción
/// Incluye contador de cantidad para agregar múltiples unidades al carrito
class ProductCardWithDiscount extends StatefulWidget {
  final ProductoModelo producto;
  final VoidCallback? onTap;

  const ProductCardWithDiscount({
    super.key,
    required this.producto,
    this.onTap,
  });

  @override
  State<ProductCardWithDiscount> createState() => _ProductCardWithDiscountState();
}

class _ProductCardWithDiscountState extends State<ProductCardWithDiscount> {
  int _cantidad = 1;

  @override
  Widget build(BuildContext context) {
    final producto = widget.producto;
    final tieneDescuento = producto.porcentajeDescuento != null &&
                           producto.porcentajeDescuento! > 0;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final sinStock = producto.stock <= 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen con badge de descuento
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: producto.imagenUrl != null && producto.imagenUrl!.isNotEmpty
                        ? Image.network(
                            producto.imagenUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.cake,
                                  size: 60,
                                  color: Theme.of(context).primaryColor,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.cake,
                              size: 60,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                  ),

                  // Badge de descuento
                  if (tieneDescuento)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '-${producto.porcentajeDescuento!.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Información del producto
            Padding(
              padding: EdgeInsets.all(isMobile ? 8 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    producto.nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 13 : 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isMobile ? 6 : 8),

                  // Precios
                  if (tieneDescuento) ...[
                    // Precio original tachado
                    Text(
                      'S/. ${producto.precioOriginal!.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        color: Colors.grey.shade600,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Precio con descuento
                    Text(
                      'S/. ${producto.precioDescuento!.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 16 : 18,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ] else
                    Text(
                      'S/. ${producto.precio.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 16 : 18,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),

                  SizedBox(height: isMobile ? 8 : 12),

                  // Contador de cantidad y botón de compra
                  Row(
                    children: [
                      // Contador de cantidad
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Botón decrementar
                            InkWell(
                              onTap: sinStock || _cantidad <= 1
                                  ? null
                                  : () {
                                      setState(() {
                                        _cantidad--;
                                      });
                                    },
                              child: Container(
                                padding: EdgeInsets.all(isMobile ? 3 : 4),
                                child: Icon(
                                  Icons.remove,
                                  size: isMobile ? 12 : 14,
                                  color: sinStock || _cantidad <= 1
                                      ? Colors.grey.shade400
                                      : Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            // Cantidad
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 4 : 6,
                              ),
                              child: Text(
                                '$_cantidad',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 11 : 12,
                                ),
                              ),
                            ),
                            // Botón incrementar
                            InkWell(
                              onTap: sinStock || _cantidad >= producto.stock
                                  ? null
                                  : () {
                                      setState(() {
                                        _cantidad++;
                                      });
                                    },
                              child: Container(
                                padding: EdgeInsets.all(isMobile ? 3 : 4),
                                child: Icon(
                                  Icons.add,
                                  size: isMobile ? 12 : 14,
                                  color: sinStock || _cantidad >= producto.stock
                                      ? Colors.grey.shade400
                                      : Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Botón de compra
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: sinStock
                              ? null
                              : () {
                                  final authProvider = AuthProvider.instance;
                                  final carritoProvider = CarritoProvider.instance;
                                  final bool isAuthenticated = authProvider.authState == AuthState.authenticated;

                                  if (!isAuthenticated) {
                                    showAppMessage(
                                      context,
                                      'Debes iniciar sesión para realizar compras',
                                      type: MessageType.warning,
                                    );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const LoginVista(),
                                      ),
                                    );
                                    return;
                                  }

                                  if (authProvider.currentUser?.rol == 'empleado') {
                                    showAppMessage(
                                      context,
                                      'Los empleados no pueden realizar compras',
                                      type: MessageType.warning,
                                    );
                                    return;
                                  }

                                  // Agregar producto al carrito con precio con descuento si aplica
                                  carritoProvider.agregarProducto(
                                    producto,
                                    cantidad: _cantidad,
                                    precioConDescuento: tieneDescuento ? producto.precioDescuento : null,
                                    porcentajeDescuento: tieneDescuento ? producto.porcentajeDescuento : null,
                                  );

                                  showAppMessage(
                                    context,
                                    '${producto.nombre} x$_cantidad - Agregado al carrito',
                                    type: MessageType.success,
                                  );

                                  // Resetear cantidad
                                  setState(() {
                                    _cantidad = 1;
                                  });
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 6 : 8,
                              horizontal: isMobile ? 6 : 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          icon: Icon(Icons.shopping_cart, size: isMobile ? 14 : 16),
                          label: Text(
                            'Comprar',
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
