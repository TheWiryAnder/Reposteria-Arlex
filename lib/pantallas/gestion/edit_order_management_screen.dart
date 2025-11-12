import 'package:flutter/material.dart';

class EditOrderManagementScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const EditOrderManagementScreen({super.key, required this.order});

  @override
  State<EditOrderManagementScreen> createState() =>
      _EditOrderManagementScreenState();
}

class _EditOrderManagementScreenState extends State<EditOrderManagementScreen> {
  late List<Map<String, dynamic>> _productos;
  final List<Map<String, dynamic>> _productosDisponibles = [
    {'nombre': 'Torta de Chocolate', 'precio': 25.00},
    {'nombre': 'Galletas Decoradas', 'precio': 10.25},
    {'nombre': 'Pastel de Tres Leches', 'precio': 35.00},
    {'nombre': 'Bocaditos', 'precio': 14.33},
    {'nombre': 'Torta de Bodas', 'precio': 120.00},
    {'nombre': 'Cupcakes', 'precio': 8.50},
    {'nombre': 'Brownies', 'precio': 12.00},
  ];

  @override
  void initState() {
    super.initState();
    _productos = List<Map<String, dynamic>>.from(
      widget.order['productos'].map((p) => Map<String, dynamic>.from(p)),
    );
  }

  double _calcularTotal() {
    double total = 0;
    for (var producto in _productos) {
      total += producto['cantidad'] * producto['precioUnitario'];
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Pedido #${widget.order['id']}'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Productos en el Pedido',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._productos.asMap().entries.map((entry) {
                          final index = entry.key;
                          final producto = entry.value;
                          return _buildProductRow(producto, index);
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Agregar Producto',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._productosDisponibles.map((producto) {
                          return ListTile(
                            title: Text(producto['nombre']),
                            subtitle: Text(
                              'S/. ${producto['precio'].toStringAsFixed(2)}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.add_circle,
                                color: Colors.green,
                              ),
                              onPressed: () => _agregarProducto(producto),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'S/. ${_calcularTotal().toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _guardarCambios,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Guardar Cambios'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> producto, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto['nombre'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'S/. ${producto['precioUnitario'].toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: Colors.red,
                  onPressed: () {
                    setState(() {
                      if (producto['cantidad'] > 1) {
                        producto['cantidad']--;
                      }
                    });
                  },
                ),
                Text(
                  '${producto['cantidad']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: Colors.green,
                  onPressed: () {
                    setState(() {
                      producto['cantidad']++;
                    });
                  },
                ),
              ],
            ),
            Text(
              'S/. ${(producto['cantidad'] * producto['precioUnitario']).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              color: Colors.red,
              onPressed: () {
                setState(() {
                  _productos.removeAt(index);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _agregarProducto(Map<String, dynamic> producto) {
    setState(() {
      final existingIndex = _productos.indexWhere(
        (p) => p['nombre'] == producto['nombre'],
      );

      if (existingIndex != -1) {
        _productos[existingIndex]['cantidad']++;
      } else {
        _productos.add({
          'nombre': producto['nombre'],
          'cantidad': 1,
          'precioUnitario': producto['precio'],
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${producto['nombre']} agregado'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _guardarCambios() {
    if (_productos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El pedido debe tener al menos un producto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    widget.order['productos'] = _productos;
    widget.order['total'] = _calcularTotal();

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pedido #${widget.order['id']} modificado exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
