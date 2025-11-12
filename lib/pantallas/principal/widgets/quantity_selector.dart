import 'package:flutter/material.dart';

/// Widget para seleccionar la cantidad de un producto antes de comprarlo
class QuantitySelector extends StatefulWidget {
  final int initialQuantity;
  final int maxQuantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onAddToCart;
  final bool isEnabled;
  final String buttonText;

  const QuantitySelector({
    super.key,
    this.initialQuantity = 1,
    required this.maxQuantity,
    required this.onQuantityChanged,
    required this.onAddToCart,
    this.isEnabled = true,
    this.buttonText = 'Comprar',
  });

  @override
  State<QuantitySelector> createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
  }

  void _increment() {
    if (_quantity < widget.maxQuantity) {
      setState(() {
        _quantity++;
      });
      widget.onQuantityChanged(_quantity);
    }
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
      widget.onQuantityChanged(_quantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Selector de cantidad
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
                onTap: widget.isEnabled && _quantity > 1 ? _decrement : null,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Icon(
                    Icons.remove,
                    size: 16,
                    color: widget.isEnabled && _quantity > 1
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                ),
              ),
              // Cantidad
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.symmetric(
                    vertical: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Botón incrementar
              InkWell(
                onTap: widget.isEnabled && _quantity < widget.maxQuantity
                    ? _increment
                    : null,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Icon(
                    Icons.add,
                    size: 16,
                    color: widget.isEnabled && _quantity < widget.maxQuantity
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Botón comprar
        Expanded(
          child: ElevatedButton.icon(
            onPressed: widget.isEnabled ? widget.onAddToCart : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.shopping_cart, size: 18),
            label: Text(
              widget.buttonText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
