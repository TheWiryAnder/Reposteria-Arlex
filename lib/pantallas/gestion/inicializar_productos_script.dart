import 'package:flutter/material.dart';
import '../../servicios/productos_service.dart';

/// Script administrativo para inicializar el campo totalVendidos en todos los productos
class InicializarProductosScript extends StatefulWidget {
  const InicializarProductosScript({super.key});

  @override
  State<InicializarProductosScript> createState() => _InicializarProductosScriptState();
}

class _InicializarProductosScriptState extends State<InicializarProductosScript> {
  final ProductosService _productosService = ProductosService();
  bool _procesando = false;
  String _mensaje = '';
  Map<String, dynamic>? _resultado;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicializar Productos'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.inventory_2, size: 64, color: Colors.orange),
                const SizedBox(height: 24),
                const Text(
                  'Inicializar Campo totalVendidos',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Este script agregará el campo "totalVendidos" con valor 0 a todos los productos que no lo tengan.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                if (_procesando)
                  Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text(
                        'Procesando productos...',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  )
                else if (_mensaje.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _mensaje.contains('Error')
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _mensaje.contains('Error')
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _mensaje,
                          style: TextStyle(
                            color: _mensaje.contains('Error')
                                ? Colors.red.shade900
                                : Colors.green.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_resultado != null) ...[
                          const SizedBox(height: 12),
                          if (_resultado!['totalProductos'] != null)
                            Text('Total de productos: ${_resultado!['totalProductos']}'),
                          if (_resultado!['productosActualizados'] != null)
                            Text('Productos actualizados: ${_resultado!['productosActualizados']}'),
                          if (_resultado!['productosYaExistian'] != null)
                            Text('Productos que ya tenían el campo: ${_resultado!['productosYaExistian']}'),
                        ],
                      ],
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _inicializarProductos,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Ejecutar Script'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),

                if (_mensaje.isNotEmpty && !_procesando) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _mensaje = '';
                        _resultado = null;
                      });
                    },
                    child: const Text('Reiniciar'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _inicializarProductos() async {
    setState(() {
      _procesando = true;
      _mensaje = '';
      _resultado = null;
    });

    try {
      // Ejecutar script usando el servicio
      final resultado = await _productosService.inicializarTotalVendidos();

      setState(() {
        _resultado = resultado;
        if (resultado['success']) {
          _mensaje = '✅ ${resultado['message']}';
        } else {
          _mensaje = '❌ ${resultado['message']}';
        }
        _procesando = false;
      });

    } catch (e) {
      setState(() {
        _mensaje = '❌ Error al ejecutar el script:\n$e';
        _procesando = false;
      });
    }
  }
}
