import 'package:flutter/material.dart';
import 'new_order_screen.dart';
import '../../compartidos/widgets/order_detail_screen.dart';
import '../../compartidos/widgets/edit_order_screen.dart';

class EmployeeOrdersScreen extends StatefulWidget {
  const EmployeeOrdersScreen({super.key});

  @override
  State<EmployeeOrdersScreen> createState() => _EmployeeOrdersScreenState();
}

class _EmployeeOrdersScreenState extends State<EmployeeOrdersScreen> {
  String _selectedFilter = 'Todos';

  final List<Map<String, dynamic>> _orders = [
    {
      'id': '001',
      'number': 'Pedido #001',
      'customer': 'Juan Pérez',
      'date': '15 Sep 2025',
      'status': 'Completado',
      'amount': '\$45.00',
      'statusColor': Colors.green,
    },
    {
      'id': '002',
      'number': 'Pedido #002',
      'customer': 'María García',
      'date': '22 Sep 2025',
      'status': 'En proceso',
      'amount': '\$32.50',
      'statusColor': Colors.orange,
    },
    {
      'id': '003',
      'number': 'Pedido #003',
      'customer': 'Carlos López',
      'date': '28 Sep 2025',
      'status': 'Pendiente',
      'amount': '\$28.00',
      'statusColor': Colors.blue,
    },
    {
      'id': '004',
      'number': 'Pedido #004',
      'customer': 'Ana Martínez',
      'date': '30 Sep 2025',
      'status': 'Pendiente',
      'amount': '\$55.00',
      'statusColor': Colors.blue,
    },
  ];

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedFilter == 'Todos') {
      return _orders;
    }
    return _orders
        .where((order) => order['status'] == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todos'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pendiente'),
                  const SizedBox(width: 8),
                  _buildFilterChip('En proceso'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Completado'),
                ],
              ),
            ),
          ),
          // Lista de pedidos
          Expanded(
            child: _filteredOrders.isEmpty
                ? const Center(child: Text('No hay pedidos con este estado'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = _filteredOrders[index];
                      return _buildOrderCard(order);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewOrderScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Pedido'),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(
                orderId: order['id'],
                orderNumber: order['number'],
                date: order['date'],
                status: order['status'],
                amount: order['amount'],
                statusColor: order['statusColor'],
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order['number'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: order['statusColor'].withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order['status'],
                      style: TextStyle(
                        color: order['statusColor'],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    order['customer'],
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order['date'],
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Spacer(),
                  Text(
                    order['amount'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      _showEditOrderDialog(order);
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      _showChangeStatusDialog(order);
                    },
                    icon: const Icon(Icons.update, size: 16),
                    label: const Text('Cambiar Estado'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditOrderDialog(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditOrderScreen(order: order)),
    );
  }

  void _showChangeStatusDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Pendiente'),
              leading: Radio<String>(
                value: 'Pendiente',
                groupValue: order['status'],
                onChanged: (value) {
                  Navigator.pop(context);
                  _updateOrderStatus(order, value!);
                },
              ),
            ),
            ListTile(
              title: const Text('En proceso'),
              leading: Radio<String>(
                value: 'En proceso',
                groupValue: order['status'],
                onChanged: (value) {
                  Navigator.pop(context);
                  _updateOrderStatus(order, value!);
                },
              ),
            ),
            ListTile(
              title: const Text('Completado'),
              leading: Radio<String>(
                value: 'Completado',
                groupValue: order['status'],
                onChanged: (value) {
                  Navigator.pop(context);
                  _updateOrderStatus(order, value!);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _updateOrderStatus(Map<String, dynamic> order, String newStatus) {
    setState(() {
      order['status'] = newStatus;
      order['statusColor'] = _getStatusColor(newStatus);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Estado actualizado a: $newStatus')));
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completado':
        return Colors.green;
      case 'En proceso':
        return Colors.orange;
      case 'Pendiente':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
