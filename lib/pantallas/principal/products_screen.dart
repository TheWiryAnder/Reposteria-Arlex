import 'package:flutter/material.dart';
import '../../providers/auth_provider_simple.dart';
import '../../providers/carrito_provider.dart';
import '../../modelos/producto_modelo.dart';
import '../../servicios/productos_service.dart';
import '../../compartidos/widgets/message_helpers.dart';
import '../../compartidos/widgets/safe_network_image.dart';
import '../auth/login_vista.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductosService _productosService = ProductosService();
  String? _selectedCategory;

  /// Calcular número de columnas según el ancho de pantalla
  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 4;  // Desktop grande
    if (width >= 900) return 3;   // Desktop pequeño / Tablet horizontal
    if (width >= 600) return 2;   // Tablet vertical
    if (width >= 400) return 2;   // Móvil grande
    return 1;                      // Móvil muy pequeño
  }

  /// Calcular aspect ratio según el ancho de pantalla
  /// Valores MÁS BAJOS = tarjetas más altas (más espacio vertical)
  double _getChildAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 0.65;  // Desktop grande
    if (width >= 900) return 0.68;   // Desktop pequeño
    if (width >= 600) return 0.65;   // Tablet
    return 0.58;                     // Móvil - más alto para que controles queden dentro
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<ProductoModelo>>(
        stream: _productosService.streamProductos(soloDisponibles: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar productos: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          var todosLosProductos = snapshot.data ?? [];

          if (todosLosProductos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No hay productos disponibles',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Los administradores pueden agregar productos desde la sección de gestión',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Obtener categorías únicas de los productos y convertir IDs a nombres
          final categorias = todosLosProductos
              .map((p) => ProductosService.convertirIdANombre(p.categoria))
              .toSet() // Aplicar Set después de convertir a nombres para evitar duplicados
              .toList()..sort();

          // Seleccionar la primera categoría si no hay ninguna seleccionada
          if (_selectedCategory == null && categorias.isNotEmpty) {
            _selectedCategory = categorias.first;
          }

          // Filtrar productos por categoría seleccionada
          final productosFiltrados = _selectedCategory == null
              ? todosLosProductos
              : todosLosProductos.where((p) =>
                  ProductosService.convertirIdANombre(p.categoria) == _selectedCategory
                ).toList();

          return Column(
            children: [
              // Filtros de categorías
              if (categorias.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  color: Colors.grey[100],
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categorias.map((categoria) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildCategoryChip(categoria),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              // Lista de productos
              Expanded(
                child: productosFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay productos disponibles en esta categoría',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final width = MediaQuery.of(context).size.width;
                          final isMobile = width < 600;
                          final gridPadding = isMobile ? 12.0 : 16.0;
                          final spacing = isMobile ? 12.0 : 16.0;

                          return GridView.builder(
                            padding: EdgeInsets.all(gridPadding),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _getCrossAxisCount(context),
                              childAspectRatio: _getChildAspectRatio(context),
                              crossAxisSpacing: spacing,
                              mainAxisSpacing: spacing,
                            ),
                            itemCount: productosFiltrados.length,
                            itemBuilder: (context, index) {
                              final producto = productosFiltrados[index];
                              return _buildProductCard(producto);
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final bool isSelected = _selectedCategory == category;
    return FilterChip(
      label: Text(category),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = category;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildProductCard(ProductoModelo producto) {
    return _ProductCard(producto: producto);
  }
}

// Widget separado para la tarjeta de producto con estado para manejar la cantidad
class _ProductCard extends StatefulWidget {
  final ProductoModelo producto;

  const _ProductCard({required this.producto});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  int _cantidad = 1;

  void _agregarAlCarrito(
    BuildContext context,
    ProductoModelo producto,
    AuthProvider authProvider,
    CarritoProvider carritoProvider,
  ) {
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
  }

  @override
  Widget build(BuildContext context) {
    final producto = widget.producto;
    final carritoProvider = CarritoProvider.instance;
    final authProvider = AuthProvider.instance;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    // Convertir ID de categoría a nombre para determinar el icono
    final nombreCategoria = ProductosService.convertirIdANombre(producto.categoria);

    // Determinar icono según categoría
    IconData getIconForCategory(String categoria) {
      switch (categoria) {
        case 'Tortas':
          return Icons.cake;
        case 'Galletas':
          return Icons.cookie;
        case 'Postres':
          return Icons.emoji_food_beverage;
        case 'Pasteles':
          return Icons.cake_outlined;
        case 'Bocaditos':
          return Icons.breakfast_dining;
        case 'Gaseosas':
          return Icons.local_drink;
        default:
          return Icons.cake;
      }
    }

    final bool sinStock = producto.stock <= 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del producto con proporción fija (igual que home)
          AspectRatio(
            aspectRatio: 1.2,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: producto.imagenUrl != null && producto.imagenUrl!.isNotEmpty
                  ? SafeNetworkImage(
                      imageUrl: producto.imagenUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                          child: Icon(
                            getIconForCategory(nombreCategoria),
                            color: Theme.of(context).primaryColor,
                            size: 50,
                          ),
                        );
                      },
                    )
                  : Container(
                      width: double.infinity,
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      child: Icon(
                        getIconForCategory(nombreCategoria),
                        color: Theme.of(context).primaryColor,
                        size: 50,
                      ),
                    ),
            ),
          ),

          // Información del producto (se adapta al espacio restante)
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
                  _buildStockIndicator(producto.stock, isMobile),
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
                              : () => _agregarAlCarrito(context, producto, authProvider, carritoProvider),
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
    );
  }

  /// Construir indicador de disponibilidad con colores (igual que home page)
  Widget _buildStockIndicator(int stock, bool isMobile) {
    final bool sinStock = stock <= 0;

    // Sin stock
    if (sinStock) {
      return Container(
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
      );
    }

    // Pocas unidades
    if (stock <= 5) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Solo $stock',
          style: TextStyle(
            fontSize: 10,
            color: Colors.orange.shade900,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Disponible
    return Container(
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
    );
  }
}