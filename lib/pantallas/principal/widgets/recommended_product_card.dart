import 'package:flutter/material.dart';
import '../../../modelos/producto_modelo.dart';
import '../../../providers/auth_provider_simple.dart';
import '../../../providers/carrito_provider.dart';
import '../../../compartidos/widgets/message_helpers.dart';
import '../../auth/login_vista.dart';

/// Widget con estado para mostrar tarjetas de productos recomendados
/// Incluye contador de cantidad para agregar múltiples unidades al carrito
class RecommendedProductCard extends StatefulWidget {
  final ProductoModelo producto;
  final VoidCallback? onTap;

  const RecommendedProductCard({
    super.key,
    required this.producto,
    this.onTap,
  });

  @override
  State<RecommendedProductCard> createState() => _RecommendedProductCardState();
}

class _RecommendedProductCardState extends State<RecommendedProductCard> {
  int _cantidad = 1;

  @override
  Widget build(BuildContext context) {
    final producto = widget.producto;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen con proporción fija
            AspectRatio(
              aspectRatio: 1.2,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: producto.imagenUrl != null
                    ? Image.network(
                        producto.imagenUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            child: Icon(
                              Icons.cake,
                              size: 50,
                              color: Theme.of(context).primaryColor,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Icon(
                          Icons.cake,
                          size: 50,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
              ),
            ),
            // Contenido que se adapta
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre del producto
                    Text(
                      producto.nombre,
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isMobile ? 3 : 4),

                    // Descripción
                    if (producto.descripcion.isNotEmpty)
                      Text(
                        producto.descripcion,
                        style: TextStyle(
                          fontSize: isMobile ? 10 : 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const Spacer(),

                    // Precio
                    Text(
                      'S/. ${producto.precio.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    SizedBox(height: isMobile ? 4 : 6),

                    // Indicador de stock
                    if (sinStock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Sin stock',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (producto.stock <= 5)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Solo ${producto.stock}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 12, color: Colors.green.shade700),
                            const SizedBox(width: 2),
                            Text(
                              'Disponible',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: isMobile ? 6 : 8),

                    // Contador de cantidad y botón de compra
                    Row(
                      children: [
                        // Contador de cantidad
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(6),
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
                                  padding: EdgeInsets.all(isMobile ? 2 : 3),
                                  child: Icon(
                                    Icons.remove,
                                    size: isMobile ? 10 : 12,
                                    color: sinStock || _cantidad <= 1
                                        ? Colors.grey.shade400
                                        : Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              // Cantidad
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 3 : 4,
                                ),
                                child: Text(
                                  '$_cantidad',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 10 : 11,
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
                                  padding: EdgeInsets.all(isMobile ? 2 : 3),
                                  child: Icon(
                                    Icons.add,
                                    size: isMobile ? 10 : 12,
                                    color: sinStock || _cantidad >= producto.stock
                                        ? Colors.grey.shade400
                                        : Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
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

                                    // Agregar producto al carrito múltiples veces según cantidad
                                    for (int i = 0; i < _cantidad; i++) {
                                      carritoProvider.agregarProducto(producto);
                                    }

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
                                vertical: isMobile ? 4 : 6,
                                horizontal: isMobile ? 4 : 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              elevation: 2,
                            ),
                            icon: Icon(Icons.shopping_cart, size: isMobile ? 12 : 14),
                            label: Text(
                              'Comprar',
                              style: TextStyle(
                                fontSize: isMobile ? 9 : 10,
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
            ),
          ],
        ),
      ),
    );
  }
}
