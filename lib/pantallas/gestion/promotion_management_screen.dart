import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Modelo de Promoción
class PromocionModelo {
  final String id;
  final String titulo;
  final String descripcion;
  final String? imagenUrl;
  final double descuento;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final bool activa;
  final List<String> productosAplicables;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  PromocionModelo({
    required this.id,
    required this.titulo,
    required this.descripcion,
    this.imagenUrl,
    required this.descuento,
    required this.fechaInicio,
    required this.fechaFin,
    this.activa = true,
    this.productosAplicables = const [],
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  factory PromocionModelo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PromocionModelo(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      descripcion: data['descripcion'] ?? '',
      imagenUrl: data['imagenUrl'],
      descuento: (data['descuento'] ?? 0).toDouble(),
      fechaInicio: (data['fechaInicio'] as Timestamp).toDate(),
      fechaFin: (data['fechaFin'] as Timestamp).toDate(),
      activa: data['activa'] ?? true,
      productosAplicables: List<String>.from(data['productosAplicables'] ?? []),
      fechaCreacion: data['fechaCreacion'] != null ? (data['fechaCreacion'] as Timestamp).toDate() : null,
      fechaActualizacion: data['fechaActualizacion'] != null ? (data['fechaActualizacion'] as Timestamp).toDate() : null,
    );
  }

  bool get esVigente {
    final now = DateTime.now();
    return activa && now.isAfter(fechaInicio) && now.isBefore(fechaFin);
  }
}

class PromotionManagementScreen extends StatefulWidget {
  const PromotionManagementScreen({super.key});

  @override
  State<PromotionManagementScreen> createState() => _PromotionManagementScreenState();
}

class _PromotionManagementScreenState extends State<PromotionManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _imagenUrlController = TextEditingController();
  final _descuentoController = TextEditingController();
  final _precioOriginalController = TextEditingController();
  final _precioConDescuentoController = TextEditingController();

  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now().add(const Duration(days: 7));
  bool _activa = true;
  List<String> _productosSeleccionados = [];
  List<Map<String, dynamic>> _todosLosProductos = [];
  double? _porcentajeCalculado;

  // Nuevas variables para el modo de promoción
  String _modoPromocion = 'nueva'; // 'nueva' o 'producto'
  String? _productoSeleccionadoId;

  Future<void> _cargarProductos() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('productos')
          .where('disponible', isEqualTo: true)
          .get();

      setState(() {
        _todosLosProductos = snapshot.docs
            .map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'nombre': data['nombre'] as String? ?? 'Sin nombre',
                'descripcion': data['descripcion'] as String? ?? '',
                'precio': (data['precio'] as num?)?.toDouble() ?? 0.0,
                'precioOriginal': (data['precioOriginal'] as num?)?.toDouble(),
                'precioDescuento': (data['precioDescuento'] as num?)?.toDouble(),
                'porcentajeDescuento': (data['porcentajeDescuento'] as num?)?.toDouble(),
                'imagenUrl': data['imagenUrl'] as String?,
                'categoria': data['categoria'] as String? ?? 'Sin categoría',
              };
            })
            .toList();
      });
    } catch (e) {
      // Error al cargar productos
    }
  }

  // Método para cargar datos del producto seleccionado en el formulario
  void _cargarDatosProducto(String productoId) {
    final producto = _todosLosProductos.firstWhere(
      (p) => p['id'] == productoId,
      orElse: () => {},
    );

    if (producto.isNotEmpty) {
      setState(() {
        _tituloController.text = 'Promoción: ${producto['nombre']}';
        _descripcionController.text = producto['descripcion'] ?? '';
        _imagenUrlController.text = producto['imagenUrl'] ?? '';

        // Si el producto ya tiene precios con descuento, usarlos
        if (producto['precioOriginal'] != null && producto['precioDescuento'] != null) {
          _precioOriginalController.text = producto['precioOriginal'].toString();
          _precioConDescuentoController.text = producto['precioDescuento'].toString();
          // El descuento se calculará automáticamente por el listener
        } else {
          // Si no tiene descuento, usar el precio normal como original
          _precioOriginalController.text = producto['precio'].toString();
          _precioConDescuentoController.clear();
        }
      });
    }
  }

  void _calcularDescuento() {
    final precioOriginal = double.tryParse(_precioOriginalController.text);
    final precioConDescuento = double.tryParse(_precioConDescuentoController.text);

    if (precioOriginal != null && precioConDescuento != null && precioOriginal > 0) {
      final descuento = ((precioOriginal - precioConDescuento) / precioOriginal) * 100;
      setState(() {
        _porcentajeCalculado = descuento > 0 ? descuento : null;
        if (_porcentajeCalculado != null) {
          _descuentoController.text = _porcentajeCalculado!.toStringAsFixed(0);
        }
      });
    } else {
      setState(() {
        _porcentajeCalculado = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Agregar listeners para calcular descuento automáticamente
    _precioOriginalController.addListener(_calcularDescuento);
    _precioConDescuentoController.addListener(_calcularDescuento);
    // Desactivar promociones vencidas al cargar la pantalla
    _desactivarPromocionesVencidas();
  }

  /// Método para desactivar automáticamente promociones que hayan pasado su fecha fin
  Future<void> _desactivarPromocionesVencidas() async {
    try {
      final ahora = DateTime.now();
      final ahoraSinHora = DateTime(ahora.year, ahora.month, ahora.day);

      // Obtener todas las promociones activas
      final snapshot = await FirebaseFirestore.instance
          .collection('promociones')
          .where('activa', isEqualTo: true)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final fechaFin = (data['fechaFin'] as Timestamp?)?.toDate();

        if (fechaFin != null) {
          final finSinHora = DateTime(fechaFin.year, fechaFin.month, fechaFin.day, 23, 59, 59);

          // Si la fecha actual es posterior a la fecha fin, desactivar
          if (ahoraSinHora.isAfter(finSinHora)) {
            await FirebaseFirestore.instance
                .collection('promociones')
                .doc(doc.id)
                .update({
              'activa': false,
              'fechaActualizacion': FieldValue.serverTimestamp(),
            });

            print('✅ Promoción "${data['titulo']}" desactivada automáticamente (venció el ${DateFormat('dd/MM/yyyy').format(fechaFin)})');
          }
        }
      }
    } catch (e) {
      print('Error al desactivar promociones vencidas: $e');
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _imagenUrlController.dispose();
    _descuentoController.dispose();
    _precioOriginalController.removeListener(_calcularDescuento);
    _precioOriginalController.dispose();
    _precioConDescuentoController.removeListener(_calcularDescuento);
    _precioConDescuentoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Promociones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            iconSize: 32,
            onPressed: () => _mostrarDialogoPromocion(),
            tooltip: 'Nueva Promoción',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('promociones')
                .orderBy('fechaCreacion', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                // Si hay error de permisos o la colección no existe, mostrar pantalla vacía
                final errorMessage = snapshot.error.toString();
                final isPermissionError = errorMessage.contains('permission-denied');

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPermissionError ? Icons.lock_outline : Icons.local_offer_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isPermissionError
                            ? 'Sin permisos para acceder a promociones'
                            : 'No hay promociones registradas',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!isPermissionError)
                        ElevatedButton.icon(
                          onPressed: () => _mostrarDialogoPromocion(),
                          icon: const Icon(Icons.add),
                          label: const Text('Crear Primera Promoción'),
                        ),
                      if (isPermissionError)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Verifica que estés autenticado como administrador y que las reglas de Firebase permitan el acceso.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_offer_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay promociones registradas',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _mostrarDialogoPromocion(),
                        icon: const Icon(Icons.add),
                        label: const Text('Crear Primera Promoción'),
                      ),
                    ],
                  ),
                );
              }

              final promociones = snapshot.data!.docs
                  .map((doc) => PromocionModelo.fromFirestore(doc))
                  .toList();

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: promociones.length,
                itemBuilder: (context, index) {
                  final promocion = promociones[index];
                  return _buildPromocionCard(promocion);
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoPromocion(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Promoción'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildPromocionCard(PromocionModelo promocion) {
    final isVigente = promocion.esVigente;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: promocion.imagenUrl != null && promocion.imagenUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  promocion.imagenUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.local_offer, color: Colors.purple),
                    );
                  },
                ),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_offer, color: Colors.purple),
              ),
        title: Text(
          promocion.titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(promocion.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  label: Text('${promocion.descuento.toInt()}% OFF'),
                  backgroundColor: Colors.green,
                  labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Chip(
                  label: Text(isVigente ? 'Vigente' : 'Inactiva'),
                  backgroundColor: isVigente ? Colors.green : Colors.grey,
                  labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Válida: ${DateFormat('dd/MM/yyyy').format(promocion.fechaInicio)} - ${DateFormat('dd/MM/yyyy').format(promocion.fechaFin)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _mostrarDialogoPromocion(promocion: promocion),
              tooltip: 'Editar',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmarEliminacion(promocion),
              tooltip: 'Eliminar',
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  void _mostrarDialogoPromocion({PromocionModelo? promocion}) async {
    // Cargar productos disponibles
    await _cargarProductos();

    // Resetear modo y datos
    _modoPromocion = 'nueva';
    _productoSeleccionadoId = null;

    // Resetear o cargar datos
    if (promocion != null) {
      _tituloController.text = promocion.titulo;
      _descripcionController.text = promocion.descripcion;
      _imagenUrlController.text = promocion.imagenUrl ?? '';
      _descuentoController.text = promocion.descuento.toString();
      _fechaInicio = promocion.fechaInicio;
      _fechaFin = promocion.fechaFin;
      _activa = promocion.activa;
      _productosSeleccionados = List<String>.from(promocion.productosAplicables);
      _precioOriginalController.clear();
      _precioConDescuentoController.clear();
    } else {
      _tituloController.clear();
      _descripcionController.clear();
      _imagenUrlController.clear();
      _descuentoController.clear();
      _precioOriginalController.clear();
      _precioConDescuentoController.clear();
      _fechaInicio = DateTime.now();
      _fechaFin = DateTime.now().add(const Duration(days: 7));
      _activa = true;
      _productosSeleccionados = [];
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(promocion == null ? 'Nueva Promoción' : 'Editar Promoción'),
            content: SizedBox(
              width: 600,
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selector de modo (solo para nuevas promociones)
                      if (promocion == null) ...[
                        Text(
                          'Tipo de Promoción',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    _modoPromocion = 'nueva';
                                    _productoSeleccionadoId = null;
                                    _tituloController.clear();
                                    _descripcionController.clear();
                                    _imagenUrlController.clear();
                                    _precioOriginalController.clear();
                                    _precioConDescuentoController.clear();
                                    _descuentoController.clear();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _modoPromocion == 'nueva'
                                        ? Colors.orange.shade100
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _modoPromocion == 'nueva'
                                          ? Colors.orange
                                          : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.add_circle_outline,
                                        size: 40,
                                        color: _modoPromocion == 'nueva'
                                            ? Colors.orange
                                            : Colors.grey,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Crear Nueva',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _modoPromocion == 'nueva'
                                              ? Colors.orange
                                              : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Ingresar todos los datos',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    _modoPromocion = 'producto';
                                    _productoSeleccionadoId = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _modoPromocion == 'producto'
                                        ? Colors.blue.shade100
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _modoPromocion == 'producto'
                                          ? Colors.blue
                                          : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.shopping_bag,
                                        size: 40,
                                        color: _modoPromocion == 'producto'
                                            ? Colors.blue
                                            : Colors.grey,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Producto Existente',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _modoPromocion == 'producto'
                                              ? Colors.blue
                                              : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Datos auto-completados',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),
                      ],

                      // Selector de producto (solo si modo = 'producto')
                      if (_modoPromocion == 'producto') ...[
                        Text(
                          'Seleccionar Producto',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Producto*',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.shopping_bag),
                          ),
                          items: _todosLosProductos.map((producto) {
                            return DropdownMenuItem<String>(
                              value: producto['id'] as String,
                              child: Text(producto['nombre'] as String),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                _productoSeleccionadoId = value;
                                _cargarDatosProducto(value);
                              });
                            }
                          },
                          validator: (value) =>
                              value == null ? 'Debes seleccionar un producto' : null,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Pre-visualización de imagen
                      if (_imagenUrlController.text.isNotEmpty) ...[
                        Text(
                          'Pre-visualización',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _imagenUrlController.text,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                        const SizedBox(height: 8),
                                        Text('Error al cargar imagen', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey.shade200,
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
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Campos del formulario
                      TextFormField(
                        controller: _tituloController,
                        decoration: const InputDecoration(
                          labelText: 'Título*',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                          helperText: 'Editable - Los cambios solo afectan la promoción',
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descripcionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción*',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                          helperText: 'Editable - Los cambios solo afectan la promoción',
                        ),
                        maxLines: 3,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _imagenUrlController,
                        decoration: const InputDecoration(
                          labelText: 'URL de Imagen',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.image),
                          helperText: 'Editable - Los cambios solo afectan la promoción',
                        ),
                        onChanged: (value) {
                          // Actualizar preview al cambiar URL
                          setDialogState(() {});
                        },
                      ),
                      const SizedBox(height: 16),

                      // Precios
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Precios y Descuento',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _precioOriginalController,
                              decoration: const InputDecoration(
                                labelText: 'Precio Original*',
                                border: OutlineInputBorder(),
                                prefixText: 'S/. ',
                                helperText: 'Editable',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Requerido';
                                if (double.tryParse(value!) == null) return 'Inválido';
                                return null;
                              },
                              onChanged: (value) => setDialogState(() {}),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _precioConDescuentoController,
                              decoration: const InputDecoration(
                                labelText: 'Precio con Descuento*',
                                border: OutlineInputBorder(),
                                prefixText: 'S/. ',
                                helperText: 'Editable',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Requerido';
                                final precio = double.tryParse(value!);
                                if (precio == null) return 'Inválido';
                                final original = double.tryParse(_precioOriginalController.text);
                                if (original != null && precio >= original) {
                                  return 'Debe ser menor al original';
                                }
                                return null;
                              },
                              onChanged: (value) => setDialogState(() {}),
                            ),
                          ),
                        ],
                      ),
                      if (_porcentajeCalculado != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_offer, color: Colors.green.shade900, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Descuento: ${_porcentajeCalculado!.toStringAsFixed(0)}% OFF',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade900,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Fechas
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Vigencia',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        title: const Text('Fecha de Inicio'),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(_fechaInicio)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final fecha = await showDatePicker(
                            context: context,
                            initialDate: _fechaInicio,
                            // Permitir fechas pasadas al editar promociones existentes
                            firstDate: promocion != null
                                ? DateTime(2020)
                                : DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 730)), // 2 años
                          );
                          if (fecha != null) {
                            setDialogState(() => _fechaInicio = fecha);
                          }
                        },
                      ),
                      ListTile(
                        title: const Text('Fecha de Fin'),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(_fechaFin)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final fecha = await showDatePicker(
                            context: context,
                            initialDate: _fechaFin,
                            // Permitir fechas pasadas al editar, pero después de fecha de inicio
                            firstDate: promocion != null
                                ? DateTime(2020)
                                : _fechaInicio,
                            lastDate: DateTime.now().add(const Duration(days: 730)), // 2 años
                          );
                          if (fecha != null) {
                            setDialogState(() => _fechaFin = fecha);
                          }
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Promoción Activa'),
                        value: _activa,
                        onChanged: (value) => setDialogState(() => _activa = value),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Guardar en productosAplicables solo si seleccionó un producto
                    if (_modoPromocion == 'producto' && _productoSeleccionadoId != null) {
                      _productosSeleccionados = [_productoSeleccionadoId!];
                    } else {
                      _productosSeleccionados = [];
                    }
                    _guardarPromocion(promocion);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _guardarPromocion(PromocionModelo? promocionExistente) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Calcular descuento si no está ya calculado
      final precioOriginal = double.tryParse(_precioOriginalController.text);
      final precioDescuento = double.tryParse(_precioConDescuentoController.text);
      double? descuentoPorcentaje = _porcentajeCalculado;

      // Si no hay porcentaje calculado pero hay precios, calcularlo
      if (descuentoPorcentaje == null && precioOriginal != null && precioDescuento != null && precioOriginal > 0) {
        descuentoPorcentaje = ((precioOriginal - precioDescuento) / precioOriginal) * 100;
      }

      // Si aún no hay descuento, intentar usar el del campo manual
      if (descuentoPorcentaje == null && _descuentoController.text.isNotEmpty) {
        descuentoPorcentaje = double.tryParse(_descuentoController.text);
      }

      final data = {
        'titulo': _tituloController.text,
        'descripcion': _descripcionController.text,
        'imagenUrl': _imagenUrlController.text.isEmpty ? null : _imagenUrlController.text,
        'descuento': descuentoPorcentaje ?? 0.0,
        'precioOriginal': precioOriginal,
        'precioDescuento': precioDescuento,
        'fechaInicio': Timestamp.fromDate(_fechaInicio),
        'fechaFin': Timestamp.fromDate(_fechaFin),
        'activa': _activa,
        'productosAplicables': _productosSeleccionados,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      };

      if (promocionExistente == null) {
        data['fechaCreacion'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('promociones').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('promociones')
            .doc(promocionExistente.id)
            .update(data);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(promocionExistente == null
                ? 'Promoción creada exitosamente'
                : 'Promoción actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmarEliminacion(PromocionModelo promocion) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de eliminar la promoción "${promocion.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await FirebaseFirestore.instance
            .collection('promociones')
            .doc(promocion.id)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Promoción eliminada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
