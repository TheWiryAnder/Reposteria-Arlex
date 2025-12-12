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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Imagen del producto
            SizedBox(
              height: isMobile ? 110 : 180,
              child: ClipRRect(
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
            ),

            // Información del producto
            Padding(
              padding: EdgeInsets.all(isMobile ? 4 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nombre del producto
                  Text(
                    producto.nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 12 : 16,
                    ),
                    maxLines: isMobile ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isMobile ? 2 : 8),

                  // Descripción corta
                  if (producto.descripcion.isNotEmpty)
                    Text(
                      producto.descripcion,
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: isMobile ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  SizedBox(height: isMobile ? 2 : 8),

                  // Precio
                  Text(
                    'S/. ${producto.precio.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 14 : 20,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),

                  SizedBox(height: isMobile ? 3 : 8),

                  // Indicador de disponibilidad
                  if (sinStock)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 6 : 8,
                        vertical: isMobile ? 2 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cancel, size: isMobile ? 10 : 16, color: Colors.red.shade900),
                          SizedBox(width: isMobile ? 3 : 4),
                          Text(
                            'Sin stock',
                            style: TextStyle(
                              fontSize: isMobile ? 9 : 12,
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 6 : 8,
                        vertical: isMobile ? 2 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: isMobile ? 10 : 16, color: Colors.green.shade700),
                          SizedBox(width: isMobile ? 3 : 4),
                          Text(
                            'Disponible',
                            style: TextStyle(
                              fontSize: isMobile ? 9 : 12,
                              color: Colors.green.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: isMobile ? 4 : 12),

                  // Contador de cantidad y botón de compra
                  Row(
                    children: [
                      // Contador de cantidad
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                  padding: EdgeInsets.all(isMobile ? 3 : 6),
                                  child: Icon(
                                    Icons.remove,
                                    size: isMobile ? 12 : 16,
                                    color: sinStock || _cantidad <= 1
                                        ? Colors.grey.shade400
                                        : Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              // Cantidad
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 4 : 8,
                                ),
                                child: Text(
                                  '$_cantidad',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 11 : 14,
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
                                  padding: EdgeInsets.all(isMobile ? 3 : 6),
                                  child: Icon(
                                    Icons.add,
                                    size: isMobile ? 12 : 16,
                                    color: sinStock || _cantidad >= producto.stock
                                        ? Colors.grey.shade400
                                        : Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: isMobile ? 4 : 6),
                      // Botón de compra
                      Expanded(
                        flex: 3,
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
                              vertical: isMobile ? 5 : 8,
                              horizontal: isMobile ? 4 : 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          icon: Icon(Icons.shopping_cart, size: isMobile ? 12 : 18),
                          label: Text(
                            'Comprar',
                            style: TextStyle(
                              fontSize: isMobile ? 10 : 14,
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
