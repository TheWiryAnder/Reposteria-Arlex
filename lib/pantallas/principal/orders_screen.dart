import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text('Mis Pedidos', style: TextStyle(fontSize: 24)),
          Text('Próximamente disponible'),
        ],
      ),
    );
  }
}
