import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../servicios/productos_service.dart';
import '../../servicios/categorias_service.dart';
import '../../servicios/storage_service.dart';
import '../../modelos/producto_modelo.dart';

/// Pantalla para agregar o editar productos en Firebase
class AddProductFirebaseScreen extends StatefulWidget {
  final ProductoModelo? producto;

  const AddProductFirebaseScreen({super.key, this.producto});

  @override
  State<AddProductFirebaseScreen> createState() =>
      _AddProductFirebaseScreenState();
}

class _AddProductFirebaseScreenState extends State<AddProductFirebaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductosService _productosService = ProductosService();
  final CategoriasService _categoriasService = CategoriasService();
  final StorageService _storageService = StorageService();

  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _precioController;
  late TextEditingController _precioOriginalController;
  late TextEditingController _precioDescuentoController;
  late TextEditingController _stockController;
  late TextEditingController _imagenUrlController;

  String _categoriaSeleccionada = 'cat_tortas';
  bool _disponible = true;
  double? _porcentajeDescuentoCalculado;
  bool _isLoading = false;
  List<Map<String, String>> _categorias = [];
  bool _categoriasLoaded = false;
  File? _imagenSeleccionada;
  bool _subiendoImagen = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.producto?.nombre ?? '');
    _descripcionController =
        TextEditingController(text: widget.producto?.descripcion ?? '');
    _precioController = TextEditingController(
        text: widget.producto?.precio.toString() ?? '');
    _precioOriginalController = TextEditingController(
        text: widget.producto?.precioOriginal?.toString() ?? '');
    _precioDescuentoController = TextEditingController(
        text: widget.producto?.precioDescuento?.toString() ?? '');
    _stockController =
        TextEditingController(text: widget.producto?.stock.toString() ?? '0');
    _imagenUrlController =
        TextEditingController(text: widget.producto?.imagenUrl ?? '');

    _porcentajeDescuentoCalculado = widget.producto?.porcentajeDescuento;

    // Agregar listeners para calcular descuento automáticamente
    _precioOriginalController.addListener(_calcularDescuento);
    _precioDescuentoController.addListener(_calcularDescuento);

    if (widget.producto != null) {
      _categoriaSeleccionada = widget.producto!.categoria;
      _disponible = widget.producto!.disponible;
    }

    _cargarCategorias();
  }

  /// Calcular descuento automáticamente
  void _calcularDescuento() {
    final precioOriginal = double.tryParse(_precioOriginalController.text);
    final precioDescuento = double.tryParse(_precioDescuentoController.text);

    if (precioOriginal != null && precioDescuento != null && precioOriginal > 0) {
      final descuento = ((precioOriginal - precioDescuento) / precioOriginal) * 100;
      setState(() {
        _porcentajeDescuentoCalculado = descuento > 0 ? descuento : null;
      });
    } else {
      setState(() {
        _porcentajeDescuentoCalculado = null;
      });
    }
  }

  Future<void> _cargarCategorias() async {
    try {
      final categoriasData = await _categoriasService.obtenerTodasLasCategorias();
      setState(() {
        _categorias = categoriasData
            .where((cat) => cat.activa) // Solo categorías activas
            .map((cat) => {
                  'id': cat.id,
                  'nombre': cat.nombre,
                })
            .toList();
        _categoriasLoaded = true;

        // Si no hay una categoría seleccionada y hay categorías, seleccionar la primera
        if (_categorias.isNotEmpty &&
            !_categorias.any((cat) => cat['id'] == _categoriaSeleccionada)) {
          _categoriaSeleccionada = _categorias.first['id']!;
        }
      });
    } catch (e) {
      // Si falla, usar categorías por defecto
      setState(() {
        _categorias = [
          {'id': 'cat_tortas', 'nombre': 'Tortas'},
          {'id': 'cat_galletas', 'nombre': 'Galletas'},
          {'id': 'cat_postres', 'nombre': 'Postres'},
          {'id': 'cat_pasteles', 'nombre': 'Pasteles'},
          {'id': 'cat_bocaditos', 'nombre': 'Bocaditos'},
        ];
        _categoriasLoaded = true;
      });
    }
  }

  /// Mostrar opciones para seleccionar imagen
  Future<void> _mostrarOpcionesImagen() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              // Encabezado informativo
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Recomendado: Usa imgbb.com para subir imágenes gratis',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Opción URL (RECOMENDADA - Primera opción)
              ListTile(
                leading: Icon(Icons.link, color: Colors.blue.shade700),
                title: const Text(
                  'Ingresar URL desde ImgBB',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Recomendado - Sube a imgbb.com primero'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'GRATIS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarDialogoUrl();
                },
              ),
              const Divider(),

              // Opciones alternativas
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de Galería'),
                subtitle: const Text('Requiere Firebase Storage (no disponible)'),
                enabled: false,
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarImagenGaleria();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar Foto'),
                subtitle: const Text('Requiere Firebase Storage (no disponible)'),
                enabled: false,
                onTap: () {
                  Navigator.pop(context);
                  _tomarFoto();
                },
              ),

              if (_imagenSeleccionada != null || _imagenUrlController.text.isNotEmpty) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Eliminar Imagen', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _eliminarImagen();
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Seleccionar imagen de galería
  Future<void> _seleccionarImagenGaleria() async {
    try {
      final imagen = await _storageService.seleccionarImagenGaleria();
      if (imagen != null) {
        setState(() {
          _imagenSeleccionada = imagen;
          _imagenUrlController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Tomar foto con cámara
  Future<void> _tomarFoto() async {
    try {
      final imagen = await _storageService.tomarFoto();
      if (imagen != null) {
        setState(() {
          _imagenSeleccionada = imagen;
          _imagenUrlController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al tomar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Mostrar diálogo para ingresar URL
  Future<void> _mostrarDialogoUrl() async {
    final controller = TextEditingController(text: _imagenUrlController.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.link, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('URL de Imagen'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instrucciones
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Cómo obtener la URL:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Ve a imgbb.com\n'
                      '2. Sube tu imagen\n'
                      '3. Copia el "Direct link"\n'
                      '4. Pégalo aquí abajo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Campo de texto
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'URL de la imagen',
                  hintText: 'https://i.ibb.co/...',
                  prefixIcon: Icon(Icons.image),
                  border: OutlineInputBorder(),
                  helperText: 'Debe empezar con https://',
                ),
                maxLines: 3,
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty && !url.startsWith('http')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('La URL debe empezar con https://'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              setState(() {
                _imagenUrlController.text = url;
                _imagenSeleccionada = null;
              });
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check),
            label: const Text('Guardar URL'),
          ),
        ],
      ),
    );
  }

  /// Eliminar imagen seleccionada
  void _eliminarImagen() {
    setState(() {
      _imagenSeleccionada = null;
      _imagenUrlController.clear();
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _precioOriginalController.removeListener(_calcularDescuento);
    _precioOriginalController.dispose();
    _precioDescuentoController.removeListener(_calcularDescuento);
    _precioDescuentoController.dispose();
    _stockController.dispose();
    _imagenUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.producto != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Producto' : 'Agregar Producto'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    // Nombre del producto
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Producto *',
                        hintText: 'Ej: Torta de Chocolate',
                        prefixIcon: Icon(Icons.cake),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el nombre del producto';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Descripción
                    TextFormField(
                      controller: _descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción *',
                        hintText:
                            'Describe el producto y sus características',
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa una descripción';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Precio y Stock en fila
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _precioController,
                            decoration: const InputDecoration(
                              labelText: 'Precio *',
                              hintText: '0.00',
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa el precio';
                              }
                              final precio = double.tryParse(value);
                              if (precio == null || precio <= 0) {
                                return 'Precio inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            decoration: const InputDecoration(
                              labelText: 'Stock *',
                              hintText: '0',
                              prefixIcon: Icon(Icons.inventory_2),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa el stock';
                              }
                              final stock = int.tryParse(value);
                              if (stock == null || stock < 0) {
                                return 'Stock inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Sección de Descuentos (Opcional)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.local_offer, color: Colors.orange.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Descuento (Opcional)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ingresa el precio original y el precio con descuento. El porcentaje se calculará automáticamente.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _precioOriginalController,
                                  decoration: InputDecoration(
                                    labelText: 'Precio Original',
                                    hintText: '0.00',
                                    prefixIcon: const Icon(Icons.money_off),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}')),
                                  ],
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      final precio = double.tryParse(value);
                                      if (precio == null || precio <= 0) {
                                        return 'Precio inválido';
                                      }
                                      // Si hay precio con descuento, validar que sea menor
                                      final precioDesc = double.tryParse(_precioDescuentoController.text);
                                      if (precioDesc != null && precioDesc >= precio) {
                                        return 'Debe ser mayor al precio con descuento';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _precioDescuentoController,
                                  decoration: InputDecoration(
                                    labelText: 'Precio con Descuento',
                                    hintText: '0.00',
                                    prefixIcon: const Icon(Icons.discount),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}')),
                                  ],
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      final precio = double.tryParse(value);
                                      if (precio == null || precio <= 0) {
                                        return 'Precio inválido';
                                      }
                                      // Si hay precio original, validar que sea menor
                                      final precioOrig = double.tryParse(_precioOriginalController.text);
                                      if (precioOrig != null && precio >= precioOrig) {
                                        return 'Debe ser menor al precio original';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (_porcentajeDescuentoCalculado != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Descuento: ${_porcentajeDescuentoCalculado!.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Categoría
                    if (!_categoriasLoaded)
                      const LinearProgressIndicator()
                    else
                      DropdownButtonFormField<String>(
                        initialValue: _categorias.any((cat) => cat['id'] == _categoriaSeleccionada)
                            ? _categoriaSeleccionada
                            : (_categorias.isNotEmpty ? _categorias.first['id'] : null),
                        decoration: InputDecoration(
                          labelText: 'Categoría *',
                          prefixIcon: const Icon(Icons.category),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.refresh, size: 20),
                            onPressed: _cargarCategorias,
                            tooltip: 'Recargar categorías',
                          ),
                        ),
                        items: _categorias.map((cat) {
                          return DropdownMenuItem(
                            value: cat['id'],
                            child: Text(cat['nombre']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _categoriaSeleccionada = value;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor selecciona una categoría';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 16),

                    // Sección de imagen del producto
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.image, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Imagen del Producto',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                if (_subiendoImagen)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Vista previa de la imagen
                            if (_imagenSeleccionada != null || _imagenUrlController.text.isNotEmpty)
                              Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _imagenSeleccionada != null
                                      ? Image.file(
                                          _imagenSeleccionada!,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          _imagenUrlController.text,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.broken_image,
                                                      size: 48, color: Colors.grey[400]),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Error al cargar imagen',
                                                    style: TextStyle(color: Colors.grey[600]),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return const Center(
                                                child: CircularProgressIndicator());
                                          },
                                        ),
                                ),
                              )
                            else
                              Container(
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_outlined,
                                        size: 48,
                                        color: Colors.grey[400]
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Sin imagen',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),

                            // Texto de ayuda
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Recomendado: Sube tu imagen a imgbb.com y pega la URL aquí',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Botón para seleccionar imagen
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _mostrarOpcionesImagen,
                                icon: const Icon(Icons.add_photo_alternate),
                                label: Text(
                                  _imagenSeleccionada != null || _imagenUrlController.text.isNotEmpty
                                      ? 'Cambiar Imagen'
                                      : 'Agregar Imagen',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Switch de disponibilidad
                    Card(
                      child: SwitchListTile(
                        title: const Text('Producto Disponible'),
                        subtitle: Text(_disponible
                            ? 'Visible en el catálogo'
                            : 'Oculto del catálogo'),
                        value: _disponible,
                        onChanged: (value) {
                          setState(() {
                            _disponible = value;
                          });
                        },
                        secondary: Icon(
                          _disponible ? Icons.visibility : Icons.visibility_off,
                          color: _disponible ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botones
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
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _guardarProducto,
                            icon: const Icon(Icons.save),
                            label: Text(isEditing ? 'Guardar' : 'Crear Producto'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Nota informativa
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Los cambios se guardarán en Firebase y estarán disponibles inmediatamente.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _guardarProducto() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final isEditing = widget.producto != null;
      final ahora = DateTime.now();
      final productoId = isEditing ? widget.producto!.id : 'prod_${ahora.millisecondsSinceEpoch}';

      // Si hay una imagen seleccionada, subirla a Firebase Storage
      String? urlImagen = _imagenUrlController.text.trim().isEmpty
          ? null
          : _imagenUrlController.text.trim();

      if (_imagenSeleccionada != null) {
        setState(() {
          _subiendoImagen = true;
        });

        try {
          if (isEditing && widget.producto?.imagenUrl != null) {
            // Actualizar imagen existente
            urlImagen = await _storageService.actualizarImagenProducto(
              archivoNuevaImagen: _imagenSeleccionada!,
              productoId: productoId,
              categoria: ProductosService.convertirIdANombre(_categoriaSeleccionada),
              imagenUrlAnterior: widget.producto?.imagenUrl,
            );
          } else {
            // Subir nueva imagen
            urlImagen = await _storageService.subirImagenProducto(
              archivoImagen: _imagenSeleccionada!,
              productoId: productoId,
              categoria: ProductosService.convertirIdANombre(_categoriaSeleccionada),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al subir imagen: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _subiendoImagen = false;
            });
          }
        }
      }

      // Procesar precios opcionales
      final precioOriginal = _precioOriginalController.text.isNotEmpty
          ? double.tryParse(_precioOriginalController.text)
          : null;
      final precioDescuento = _precioDescuentoController.text.isNotEmpty
          ? double.tryParse(_precioDescuentoController.text)
          : null;

      final productoData = ProductoModelo(
        id: productoId,
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        precio: double.parse(_precioController.text),
        precioOriginal: precioOriginal,
        precioDescuento: precioDescuento,
        porcentajeDescuento: _porcentajeDescuentoCalculado,
        categoria: _categoriaSeleccionada,
        imagenUrl: urlImagen,
        disponible: _disponible,
        stock: int.parse(_stockController.text),
        fechaCreacion: isEditing ? widget.producto!.fechaCreacion : ahora,
        fechaActualizacion: ahora,
      );

      Map<String, dynamic> resultado;

      if (isEditing) {
        // Actualizar producto existente
        resultado = await _productosService.actualizarProducto(
          productoId: productoData.id,
          cambios: productoData.toJson(),
        );
      } else {
        // Crear nuevo producto
        resultado = await _productosService.crearProducto(productoData);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (resultado['success']) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultado['message'] ?? 'Error al guardar producto'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
