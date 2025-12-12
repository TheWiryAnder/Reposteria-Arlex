import 'package:flutter/material.dart';
import '../../modelos/producto_modelo.dart';
import '../../providers/auth_provider_simple.dart';
import '../../providers/carrito_provider.dart';
import '../../compartidos/widgets/message_helpers.dart';
import '../auth/login_vista.dart';

class DetalleProductoScreen extends StatefulWidget {
  final ProductoModelo producto;

  const DetalleProductoScreen({
    super.key,
    required this.producto,
  });

  @override
  State<DetalleProductoScreen> createState() => _DetalleProductoScreenState();
}

class _DetalleProductoScreenState extends State<DetalleProductoScreen> {
  int _cantidad = 1;

  @override
  Widget build(BuildContext context) {
    final producto = widget.producto;
    final tieneDescuento = producto.porcentajeDescuento != null &&
        producto.porcentajeDescuento! > 0;
    final sinStock = producto.stock <= 0;
    final authProvider = AuthProvider.instance;
    final carritoProvider = CarritoProvider.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(producto.nombre),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            AspectRatio(
              aspectRatio: 16 / 9,
              child: producto.imagenUrl != null && producto.imagenUrl!.isNotEmpty
                  ? Image.network(
                      producto.imagenUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.cake,
                            size: 100,
                            color: Theme.of(context).primaryColor,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.cake,
                        size: 100,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del producto
                  Text(
                    producto.nombre,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Precio
                  if (tieneDescuento) ...[
                    Row(
                      children: [
                        Text(
                          'S/. ${producto.precioOriginal!.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${producto.porcentajeDescuento!.toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'S/. ${producto.precioDescuento!.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ] else
                    Text(
                      'S/. ${producto.precio.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Indicador de stock
                  _buildStockIndicator(producto.stock),

                  const SizedBox(height: 24),

                  // Descripción
                  const Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    producto.descripcion.isNotEmpty
                        ? producto.descripcion
                        : 'Sin descripción disponible',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Controles de cantidad y botón de compra
                  if (!sinStock) ...[
                    const Text(
                      'Cantidad',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Control de cantidad
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: _cantidad <= 1
                                    ? null
                                    : () {
                                        setState(() {
                                          _cantidad--;
                                        });
                                      },
                                icon: const Icon(Icons.remove),
                                color: Theme.of(context).primaryColor,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  '$_cantidad',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _cantidad >= producto.stock
                                    ? null
                                    : () {
                                        setState(() {
                                          _cantidad++;
                                        });
                                      },
                                icon: const Icon(Icons.add),
                                color: Theme.of(context).primaryColor,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final bool isAuthenticated =
                                  authProvider.authState == AuthState.authenticated;

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

                              // Agregar producto al carrito
                              if (tieneDescuento) {
                                carritoProvider.agregarProducto(
                                  producto,
                                  cantidad: _cantidad,
                                  precioConDescuento: producto.precioDescuento,
                                  porcentajeDescuento: producto.porcentajeDescuento,
                                );
                              } else {
                                for (int i = 0; i < _cantidad; i++) {
                                  carritoProvider.agregarProducto(producto);
                                }
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
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.shopping_cart),
                            label: const Text(
                              'Agregar al Carrito',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockIndicator(int stock) {
    if (stock <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel, size: 20, color: Colors.red.shade900),
            const SizedBox(width: 8),
            Text(
              'Sin stock',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 20, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Text(
            'Disponible',
            style: TextStyle(
              fontSize: 16,
              color: Colors.green.shade900,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
