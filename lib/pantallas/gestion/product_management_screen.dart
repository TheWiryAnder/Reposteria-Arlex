import 'package:flutter/material.dart';
import 'add_edit_product_screen.dart'; // TODO: Create this file

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final List<Map<String, dynamic>> _products = [
    {
      'id': '1',
      'name': 'Pastel de Chocolate',
      'description': 'Delicioso pastel de chocolate con cobertura de ganache',
      'price': 15.00,
      'quantity': 25,
      'enabled': true,
    },
    {
      'id': '2',
      'name': 'Galletas de Vainilla',
      'description': 'Galletas suaves con esencia de vainilla',
      'price': 8.50,
      'quantity': 50,
      'enabled': true,
    },
    {
      'id': '3',
      'name': 'Cupcakes de Fresa',
      'description': 'Cupcakes decorados con crema de fresa',
      'price': 6.50,
      'quantity': 30,
      'enabled': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Productos')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return _buildProductCard(product);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewProduct,
        icon: const Icon(Icons.add),
        label: const Text('Agregar Producto'),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.cake,
            color: Theme.of(context).primaryColor,
            size: 32,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                product['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (!product['enabled'])
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Inhabilitado',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(product['description']),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Precio: S/. ${product['price'].toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                Text(
                  'Stock: ${product['quantity']}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editProduct(product),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Modificar'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _toggleProductStatus(product),
                  icon: Icon(
                    product['enabled'] ? Icons.block : Icons.check_circle,
                    size: 16,
                  ),
                  label: Text(product['enabled'] ? 'Inhabilitar' : 'Habilitar'),
                  style: TextButton.styleFrom(
                    foregroundColor: product['enabled']
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addNewProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(
          onSave: (product) {
            setState(() {
              _products.add(product);
            });
          },
        ),
      ),
    );
  }

  void _editProduct(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(
          product: product,
          onSave: (updatedProduct) {
            setState(() {
              final index = _products.indexWhere(
                (p) => p['id'] == updatedProduct['id'],
              );
              if (index != -1) {
                _products[index] = updatedProduct;
              }
            });
          },
        ),
      ),
    );
  }

  void _toggleProductStatus(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${product['enabled'] ? 'Inhabilitar' : 'Habilitar'} Producto',
        ),
        content: Text(
          '¿Estás seguro de ${product['enabled'] ? 'inhabilitar' : 'habilitar'} el producto "${product['name']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                product['enabled'] = !product['enabled'];
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Producto ${product['enabled'] ? 'habilitado' : 'inhabilitado'} exitosamente',
                  ),
                ),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
