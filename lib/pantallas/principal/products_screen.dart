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
    return 2;                      // Móvil
  }

  /// Calcular aspect ratio según el ancho de pantalla
  double _getChildAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 0.62;  // Desktop grande - más compacto
    if (width >= 900) return 0.64;   // Desktop pequeño
    if (width >= 600) return 0.66;   // Tablet
    return 0.60;                     // Móvil - más compacto para eliminar espacios
  }

  /// Mostrar diagnóstico de Firebase
  Future<void> _mostrarDiagnostico() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final diagnostico = await _productosService.diagnosticarProductos();

    if (!mounted) return;
    Navigator.of(context).pop(); // Cerrar loading

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Diagnóstico de Firebase'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (diagnostico['success'] == true) ...[
                Text('Total productos en Firebase: ${diagnostico['totalProductos']}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Productos obtenidos: ${diagnostico['productosObtenidos']}'),
                const SizedBox(height: 8),
                Text('Categorías en colección: ${diagnostico['categoriasEnColeccion']}'),
                Text('Categorías activas: ${diagnostico['categoriasActivas']}'),
                const SizedBox(height: 12),
                const Text('Categorías encontradas:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                ...((diagnostico['categoriasEnProductos'] as List<dynamic>?) ?? []).map((cat) =>
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text('• $cat (${diagnostico['productosPorCategoria'][cat] ?? 0} productos)'),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Datos de categorías:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                ...((diagnostico['categoriasData'] as List<dynamic>?) ?? []).map((cat) =>
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text('• ${cat['nombre']} - ${cat['activa'] ? "Activa" : "Inactiva"} (Orden: ${cat['orden']})'),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Muestra de productos:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                ...((diagnostico['muestraProductos'] as List<dynamic>?) ?? []).map((p) =>
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text('• ${p['nombre']} - \$${p['precio']} (${p['categoria']})'),
                  ),
                ),
              ] else ...[
                const Text('Error al obtener diagnóstico:',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                Text(diagnostico['error'] ?? 'Error desconocido'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
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
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDiagnostico,
        tooltip: 'Diagnóstico Firebase',
        child: const Icon(Icons.bug_report),
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

    // Padding adaptativo según pantalla
    final double cardPadding = isMobile ? 8.0 : 12.0;
    final double iconSize = isMobile ? 40.0 : 48.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagen del producto
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: producto.imagenUrl != null && producto.imagenUrl!.isNotEmpty
                  ? SafeNetworkImage(
                      imageUrl: producto.imagenUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          child: Center(
                            child: Icon(
                              getIconForCategory(nombreCategoria),
                              color: Theme.of(context).primaryColor,
                              size: iconSize,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      child: Center(
                        child: Icon(
                          getIconForCategory(nombreCategoria),
                          color: Theme.of(context).primaryColor,
                          size: iconSize,
                        ),
                      ),
                    ),
            ),
          ),

          // Información del producto
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del producto
                  Text(
                    producto.nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 14 : 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isMobile ? 2 : 4),

                  // Descripción
                  Text(
                    producto.descripcion,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),

                  // Precio
                  Text(
                    'S/. ${producto.precio.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 16 : 18,
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
                                padding: EdgeInsets.all(isMobile ? 4 : 6),
                                child: Icon(
                                  Icons.remove,
                                  size: isMobile ? 14 : 16,
                                  color: sinStock || _cantidad <= 1
                                      ? Colors.grey.shade400
                                      : Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            // Cantidad
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 6 : 8,
                              ),
                              child: Text(
                                '$_cantidad',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 12 : 14,
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
                                padding: EdgeInsets.all(isMobile ? 4 : 6),
                                child: Icon(
                                  Icons.add,
                                  size: isMobile ? 14 : 16,
                                  color: sinStock || _cantidad >= producto.stock
                                      ? Colors.grey.shade400
                                      : Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Botón de compra
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: sinStock
                              ? null
                              : () {
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
                          icon: Icon(Icons.shopping_cart, size: isMobile ? 14 : 16),
                          label: Text(
                            'Comprar',
                            style: TextStyle(fontSize: isMobile ? 11 : 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 8 : 10,
                              horizontal: isMobile ? 8 : 12,
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

  /// Construir indicador de disponibilidad con colores
  Widget _buildStockIndicator(int stock, bool isMobile) {
    Color bgColor;
    Color textColor;
    Color iconColor;
    IconData? icon;
    String text;
    bool mostrarIcono = true;

    if (stock > 5) {
      // Disponible - Verde
      bgColor = Colors.green.shade100;
      textColor = Colors.green.shade900;
      iconColor = Colors.green.shade700;
      icon = Icons.check_circle;
      text = 'Disponible';
    } else if (stock > 0) {
      // Pocas unidades - Naranja (SIN ÍCONO)
      bgColor = Colors.orange.shade100;
      textColor = Colors.orange.shade900;
      iconColor = Colors.orange.shade700;
      text = 'Solo quedan $stock';
      mostrarIcono = false;
    } else {
      // Sin stock - Rojo
      bgColor = Colors.red.shade100;
      textColor = Colors.red.shade900;
      iconColor = Colors.red.shade700;
      icon = Icons.cancel;
      text = 'Sin stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mostrarIcono && icon != null) ...[
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}