import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart'; // Comentado: no usado en modo simulación
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../providers/carrito_provider.dart';
import '../../providers/auth_provider_simple.dart' as app_auth;
import '../../servicios/pedidos_service.dart';
import '../../compartidos/widgets/message_helpers.dart';
import '../../utils/debug_auth.dart';
import '../../modelos/carrito_modelo.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _notasController = TextEditingController();

  String _metodoPago = 'efectivo';
  String _metodoEntrega = 'domicilio';
  bool _isProcessing = false;

  // Comprobante de pago
  Uint8List? _comprobanteBytes;
  String? _comprobanteNombre;

  // Costo de envío a domicilio
  static const double _costoEnvio = 5.0;

  @override
  void initState() {
    super.initState();
    _autocompletarDatosUsuario();
  }

  void _autocompletarDatosUsuario() {
    final authProvider = app_auth.AuthProvider.instance;
    final usuario = authProvider.currentUser;

    if (usuario != null) {
      // Autocompletar teléfono si el usuario lo tiene registrado
      if (usuario.telefono != null && usuario.telefono!.isNotEmpty) {
        _telefonoController.text = usuario.telefono!;
      }

      // Autocompletar dirección si el usuario la tiene registrada
      if (usuario.direccion != null && usuario.direccion!.isNotEmpty) {
        _direccionController.text = usuario.direccion!;
      }
    }
  }

  @override
  void dispose() {
    _direccionController.dispose();
    _telefonoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final carritoProvider = CarritoProvider.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalizar Pedido'),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Resumen del pedido
                _buildOrderSummary(carritoProvider),
                const SizedBox(height: 16),

                // Formulario de información de entrega
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Información de Entrega',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Método de entrega
                        _buildDeliveryMethod(),
                        const SizedBox(height: 16),

                        // Dirección (solo si es domicilio)
                        if (_metodoEntrega == 'domicilio') ...[
                          TextFormField(
                            controller: _direccionController,
                            decoration: const InputDecoration(
                              labelText: 'Dirección de Entrega',
                              prefixIcon: Icon(Icons.location_on),
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                            validator: (value) {
                              if (_metodoEntrega == 'domicilio' &&
                                  (value == null || value.isEmpty)) {
                                return 'La dirección es obligatoria';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Teléfono
                        TextFormField(
                          controller: _telefonoController,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono de Contacto',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'El teléfono es obligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Notas adicionales
                        TextFormField(
                          controller: _notasController,
                          decoration: const InputDecoration(
                            labelText: 'Notas Adicionales (Opcional)',
                            prefixIcon: Icon(Icons.note),
                            border: OutlineInputBorder(),
                            hintText: 'Ej: Sin azúcar, decoración especial...',
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),

                        // Método de pago
                        const Text(
                          'Método de Pago',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPaymentMethod(),
                        const SizedBox(height: 24),

                        // Botón Confirmar Pedido
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isProcessing ? null : () => _confirmarPedido(carritoProvider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isProcessing
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Confirmar Pedido',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(CarritoProvider carritoProvider) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen del Pedido',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Tabla de productos
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                // Encabezado de la tabla
                if (!isMobile)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: const [
                        SizedBox(width: 50, child: Text('Cant.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        SizedBox(width: 60),
                        Expanded(flex: 2, child: Text('Producto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Expanded(flex: 3, child: Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        SizedBox(width: 80, child: Text('Descuento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                        SizedBox(width: 90, child: Text('P. Unitario', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                        SizedBox(width: 90, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                      ],
                    ),
                  ),

                // Items del carrito
                ...carritoProvider.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isLast = index == carritoProvider.items.length - 1;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: !isLast ? Border(bottom: BorderSide(color: Colors.grey.shade200)) : null,
                    ),
                    child: isMobile
                        ? _buildMobileItemRow(item)
                        : _buildDesktopItemRow(item),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Subtotal, envío y total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                // Subtotal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtotal:',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'S/. ${carritoProvider.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                // Costo de envío (solo si es domicilio)
                if (_metodoEntrega == 'domicilio') ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Envío a domicilio:',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'S/. ${_costoEnvio.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],

                const Divider(height: 24),

                // Total final
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'S/. ${(_metodoEntrega == 'domicilio' ? carritoProvider.total + _costoEnvio : carritoProvider.total).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
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

  Widget _buildDesktopItemRow(ItemCarrito item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Cantidad
        SizedBox(
          width: 50,
          child: Text(
            '${item.cantidad}x',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),

        // Imagen del producto
        SizedBox(
          width: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.producto.imagenUrl != null && item.producto.imagenUrl!.isNotEmpty
                ? Image.network(
                    item.producto.imagenUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.cake, size: 24),
                      );
                    },
                  )
                : Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.cake, size: 24),
                  ),
          ),
        ),

        // Nombre del producto
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              item.producto.nombre,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // Descripción
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              item.producto.descripcion,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // Descuento
        SizedBox(
          width: 80,
          child: item.tieneDescuento
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    '-${item.porcentajeDescuento!.toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : const Text(
                  '-',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
        ),

        // Precio unitario
        SizedBox(
          width: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (item.tieneDescuento)
                Text(
                  'S/. ${item.producto.precio.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              Text(
                'S/. ${item.precioUnitario.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: item.tieneDescuento ? Colors.red.shade700 : Colors.black87,
                ),
              ),
            ],
          ),
        ),

        // Precio total
        SizedBox(
          width: 90,
          child: Text(
            'S/. ${item.subtotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileItemRow(ItemCarrito item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.producto.imagenUrl != null && item.producto.imagenUrl!.isNotEmpty
                  ? Image.network(
                      item.producto.imagenUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.cake, size: 30),
                        );
                      },
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.cake, size: 30),
                    ),
            ),
            const SizedBox(width: 12),

            // Información del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre
                  Text(
                    item.producto.nombre,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Descripción
                  Text(
                    item.producto.descripcion,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Cantidad y descuento
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Cant: ${item.cantidad}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (item.tieneDescuento) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            '-${item.porcentajeDescuento!.toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Precios
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Precio unitario:',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                if (item.tieneDescuento)
                  Text(
                    'S/. ${item.producto.precio.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                Text(
                  'S/. ${item.precioUnitario.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: item.tieneDescuento ? Colors.red.shade700 : Colors.black87,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  'S/. ${item.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeliveryMethod() {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('Entrega a Domicilio'),
          subtitle: const Text('Recibe tu pedido en casa'),
          value: 'domicilio',
          groupValue: _metodoEntrega,
          onChanged: (value) {
            setState(() {
              _metodoEntrega = value!;
            });
          },
          secondary: const Icon(Icons.delivery_dining),
        ),
        RadioListTile<String>(
          title: const Text('Recoger en Tienda'),
          subtitle: const Text('Ahorra en envío'),
          value: 'tienda',
          groupValue: _metodoEntrega,
          onChanged: (value) {
            setState(() {
              _metodoEntrega = value!;
            });
          },
          secondary: const Icon(Icons.store),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod() {
    return Column(
      children: [
        // Efectivo
        RadioListTile<String>(
          title: const Text('Efectivo'),
          subtitle: const Text('Pagar al recibir'),
          value: 'efectivo',
          groupValue: _metodoPago,
          onChanged: (value) {
            setState(() {
              _metodoPago = value!;
            });
          },
          secondary: const Icon(Icons.money, color: Colors.green),
        ),

        // Yape
        RadioListTile<String>(
          title: const Text('Yape'),
          subtitle: const Text('Escanea el QR para pagar'),
          value: 'yape',
          groupValue: _metodoPago,
          onChanged: (value) {
            setState(() {
              _metodoPago = value!;
            });
          },
          secondary: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.qr_code, color: Colors.purple.shade700),
          ),
        ),

        // Mostrar QR de Yape si está seleccionado
        if (_metodoPago == 'yape') _buildQRSection('yape'),

        // Plin
        RadioListTile<String>(
          title: const Text('Plin'),
          subtitle: const Text('Escanea el QR para pagar'),
          value: 'plin',
          groupValue: _metodoPago,
          onChanged: (value) {
            setState(() {
              _metodoPago = value!;
            });
          },
          secondary: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.qr_code, color: Colors.blue.shade700),
          ),
        ),

        // Mostrar QR de Plin si está seleccionado
        if (_metodoPago == 'plin') _buildQRSection('plin'),

        // Sección para adjuntar comprobante (solo para Yape y Plin)
        if (_metodoPago == 'yape' || _metodoPago == 'plin')
          _buildComprobanteSection(),
      ],
    );
  }

  Widget _buildQRSection(String metodoPago) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('configuracion')
          .doc('metodosPago')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'El código QR de $metodoPago no está configurado. Por favor, contacta con el administrador.',
                      style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final qrUrl = data?['${metodoPago}QR'] as String?;

        if (qrUrl == null || qrUrl.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'El código QR de $metodoPago no está configurado. Por favor, contacta con el administrador.',
                      style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: metodoPago == 'yape' ? Colors.purple.shade200 : Colors.blue.shade200,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: metodoPago == 'yape'
                        ? Colors.purple.shade50
                        : Colors.blue.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        color: metodoPago == 'yape'
                            ? Colors.purple.shade700
                            : Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Escanea el código QR de ${metodoPago.toUpperCase()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: metodoPago == 'yape'
                              ? Colors.purple.shade900
                              : Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),

                // QR Image
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      qrUrl,
                      width: 250,
                      height: 250,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return SizedBox(
                          width: 250,
                          height: 250,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade600),
                              const SizedBox(height: 8),
                              Text(
                                'Error al cargar QR',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Instrucciones
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
                  child: Text(
                    'Una vez realizada la transferencia, confirma tu pedido',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComprobanteSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.upload_file, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Adjuntar Comprobante de Pago',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Por favor, adjunta una captura de pantalla del comprobante de pago para verificar tu transferencia.',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),

            // Vista previa de la imagen o botón para seleccionar
            if (_comprobanteBytes != null) ...[
              // Mostrar vista previa de la imagen
              Center(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green.shade300, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.memory(
                          _comprobanteBytes!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          _comprobanteNombre ?? 'Comprobante adjuntado',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Botón para cambiar imagen
                    OutlinedButton.icon(
                      onPressed: _seleccionarComprobante,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Cambiar imagen'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Botón para seleccionar imagen
              Center(
                child: ElevatedButton.icon(
                  onPressed: _seleccionarComprobante,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Seleccionar Comprobante'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '* Requerido para completar el pago',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _seleccionarComprobante() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      final Uint8List imageBytes = await image.readAsBytes();

      setState(() {
        _comprobanteBytes = imageBytes;
        _comprobanteNombre = image.name;
      });

      if (!mounted) return;

      showAppMessage(
        context,
        'Comprobante adjuntado correctamente',
        type: MessageType.success,
      );
    } catch (e) {
      if (!mounted) return;
      showAppMessage(
        context,
        'Error al seleccionar imagen: $e',
        type: MessageType.error,
      );
    }
  }

  Future<String?> _subirComprobante() async {
    if (_comprobanteBytes == null) return null;

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return null;

      // Crear nombre único para el archivo
      final String fileName = 'comprobante_${firebaseUser.uid}_${DateTime.now().millisecondsSinceEpoch}.png';

      // ═══════════════════════════════════════════════════════════════════
      // MODO SIMULACIÓN: No se sube a Firebase Storage debido a limitaciones del plan
      // ═══════════════════════════════════════════════════════════════════

      // Simular un pequeño delay de subida
      await Future.delayed(const Duration(milliseconds: 500));

      // Generar URL simulada
      final String simulatedUrl = 'simulado://comprobantes_pago/$fileName';

      if (!mounted) return null;

      return simulatedUrl;

      // ═══════════════════════════════════════════════════════════════════
      // CÓDIGO ORIGINAL (comentado para cuando Firebase Storage esté habilitado)
      // ═══════════════════════════════════════════════════════════════════
      /*
      // Referencia a Firebase Storage
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('comprobantes_pago')
          .child(fileName);

      // Subir archivo
      final UploadTask uploadTask = storageRef.putData(
        _comprobanteBytes!,
        SettableMetadata(contentType: 'image/png'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
      */
    } catch (e) {
      if (!mounted) return null;
      showAppMessage(
        context,
        'Error al registrar comprobante: $e',
        type: MessageType.error,
      );
      return null;
    }
  }

  Future<void> _confirmarPedido(CarritoProvider carritoProvider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar comprobante para Yape y Plin
    if ((_metodoPago == 'yape' || _metodoPago == 'plin') && _comprobanteBytes == null) {
      showAppMessage(
        context,
        'Por favor adjunta el comprobante de pago antes de confirmar',
        type: MessageType.warning,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    String? comprobanteUrl;

    try {
      // Subir comprobante a Firebase Storage si existe
      if (_comprobanteBytes != null) {
        comprobanteUrl = await _subirComprobante();

        // Si falla la subida del comprobante, detener el proceso
        if (comprobanteUrl == null) {
          setState(() {
            _isProcessing = false;
          });
          return;
        }
      }
      // Obtener usuario actual
      final authProvider = app_auth.AuthProvider.instance;
      final usuario = authProvider.currentUser;

      if (usuario == null) {
        if (!mounted) return;
        showAppMessage(
          context,
          'Debes iniciar sesión para realizar un pedido',
          type: MessageType.error,
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // IMPORTANTE: Usar el UID de Firebase Auth directamente para evitar errores de permisos
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        if (!mounted) return;
        showAppMessage(
          context,
          'Sesión expirada. Por favor inicia sesión nuevamente.',
          type: MessageType.error,
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Debug: Verificar estado de autenticación completo
      await DebugAuth.imprimirDiagnostico();

      print('DEBUG CHECKOUT - Usuario ID (AuthProvider): ${usuario.id}');
      print('DEBUG CHECKOUT - Firebase Auth UID: ${firebaseUser.uid}');
      print('DEBUG CHECKOUT - Usuario Email: ${usuario.email}');
      print('DEBUG CHECKOUT - Usuario Nombre: ${usuario.nombre}');

      // Usar el UID de Firebase Auth (que es el que verifica Firestore en las reglas)
      final clienteIdReal = firebaseUser.uid;

      // Crear pedido usando el servicio
      final pedidosService = PedidosService();
      final resultado = await pedidosService.crearPedido(
        clienteId: clienteIdReal,  // ← Usar el UID de Firebase Auth
        clienteNombre: usuario.nombre,
        clienteEmail: usuario.email,
        clienteTelefono: _telefonoController.text,
        carrito: carritoProvider.carrito,
        metodoEntrega: _metodoEntrega,
        metodoPago: _metodoPago,
        direccionEntrega: _metodoEntrega == 'domicilio' ? _direccionController.text : null,
        notasCliente: _notasController.text,
        comprobanteUrl: comprobanteUrl, // URL del comprobante subido
        costoEnvio: _metodoEntrega == 'domicilio' ? _costoEnvio : 0.0,
      );

      if (!mounted) return;

      if (resultado['success']) {
        // Guardar el total ANTES de limpiar el carrito (incluye costo de envío si aplica)
        final totalPedido = _metodoEntrega == 'domicilio'
            ? carritoProvider.total + _costoEnvio
            : carritoProvider.total;

        // Limpiar carrito
        carritoProvider.limpiarCarrito();

        // Verificar que el widget aún esté montado antes de mostrar el diálogo
        if (!mounted) return;

        // Mostrar confirmación
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green[600],
            ),
            title: const Text('¡Pedido Confirmado!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tu pedido ha sido recibido exitosamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Número de Pedido',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        resultado['numeroPedido'] ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Total: S/. ${totalPedido.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Cerrar diálogo
                  Navigator.of(context).pop();

                  // Volver a inicio
                  Navigator.of(context).popUntil((route) => route.isFirst);

                  showAppMessage(
                    context,
                    'Gracias por tu pedido',
                    type: MessageType.success,
                  );
                },
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      } else {
        showAppMessage(
          context,
          resultado['message'] ?? 'Error al crear el pedido',
          type: MessageType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showAppMessage(
        context,
        'Error al procesar el pedido: $e',
        type: MessageType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
