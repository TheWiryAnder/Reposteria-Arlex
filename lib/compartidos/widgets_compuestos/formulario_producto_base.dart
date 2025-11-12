import 'package:flutter/material.dart';
import '../ui/inputs/input_text.dart';
import '../ui/inputs/input_selector.dart';
import '../ui/buttons/app_button.dart';
import '../mixins/formulario_mixin.dart';

class FormularioProductoBase extends StatefulWidget {
  final ProductoFormData? datosIniciales;
  final List<CategoriaOption> categorias;
  final Future<void> Function(ProductoFormData datos) onGuardar;
  final VoidCallback? onCancelar;
  final bool modoEdicion;
  final String? tituloPersonalizado;

  const FormularioProductoBase({
    super.key,
    this.datosIniciales,
    required this.categorias,
    required this.onGuardar,
    this.onCancelar,
    this.modoEdicion = false,
    this.tituloPersonalizado,
  });

  @override
  State<FormularioProductoBase> createState() => _FormularioProductoBaseState();
}

class _FormularioProductoBaseState extends State<FormularioProductoBase>
    with FormularioMixin {

  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _precioController;
  late TextEditingController _stockController;

  String? _categoriaSeleccionada;
  bool _productoActivo = true;
  List<String> _imagenesUrls = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nombreController = TextEditingController(
      text: widget.datosIniciales?.nombre ?? '',
    );
    _descripcionController = TextEditingController(
      text: widget.datosIniciales?.descripcion ?? '',
    );
    _precioController = TextEditingController(
      text: widget.datosIniciales?.precio.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: widget.datosIniciales?.stock.toString() ?? '',
    );

    _categoriaSeleccionada = widget.datosIniciales?.categoriaId;
    _productoActivo = widget.datosIniciales?.activo ?? true;
    _imagenesUrls = List.from(widget.datosIniciales?.imagenesUrls ?? []);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Map<String, String> validacionesPersonalizadas() {
    final errores = <String, String>{};

    // Validar precio
    final precio = double.tryParse(_precioController.text);
    if (precio == null || precio <= 0) {
      errores['precio'] = 'El precio debe ser mayor a 0';
    }

    // Validar stock
    final stock = int.tryParse(_stockController.text);
    if (stock == null || stock < 0) {
      errores['stock'] = 'El stock debe ser mayor o igual a 0';
    }

    // Validar categoría
    if (_categoriaSeleccionada == null || _categoriaSeleccionada!.isEmpty) {
      errores['categoria'] = 'Selecciona una categoría';
    }

    return errores;
  }

  @override
  Future<void> procesarFormulario() async {
    final datos = ProductoFormData(
      nombre: _nombreController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      precio: double.parse(_precioController.text),
      stock: int.parse(_stockController.text),
      categoriaId: _categoriaSeleccionada!,
      activo: _productoActivo,
      imagenesUrls: _imagenesUrls,
    );

    await widget.onGuardar(datos);
  }

  @override
  void onFormularioExitoso() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.modoEdicion
              ? 'Producto actualizado correctamente'
              : 'Producto creado correctamente',
        ),
        backgroundColor: Colors.green,
      ),
    );

    if (!widget.modoEdicion) {
      // Limpiar formulario para nuevo producto
      _limpiarFormulario();
    }
  }

  @override
  void onFormularioError(dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${error.toString()}'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _descripcionController.clear();
    _precioController.clear();
    _stockController.clear();
    setState(() {
      _categoriaSeleccionada = null;
      _productoActivo = true;
      _imagenesUrls.clear();
    });
  }


  void _removerImagen(int index) {
    setState(() {
      _imagenesUrls.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información básica
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información Básica',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

                  InputText(
                    label: 'Nombre del producto',
                    controller: _nombreController,
                    isRequired: true,
                    errorText: obtenerError('nombre'),
                  ),

                  InputText(
                    label: 'Descripción',
                    controller: _descripcionController,
                    maxLines: 3,
                    errorText: obtenerError('descripcion'),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: InputText(
                          label: 'Precio',
                          controller: _precioController,
                          keyboardType: TextInputType.number,
                          isRequired: true,
                          prefixIcon: const Icon(Icons.attach_money),
                          errorText: obtenerError('precio'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InputText(
                          label: 'Stock',
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          isRequired: true,
                          prefixIcon: const Icon(Icons.inventory),
                          errorText: obtenerError('stock'),
                        ),
                      ),
                    ],
                  ),

                  InputSelector<String>(
                    label: 'Categoría',
                    value: _categoriaSeleccionada,
                    items: widget.categorias.map((categoria) {
                      return DropdownMenuItem<String>(
                        value: categoria.id,
                        child: Text(categoria.nombre),
                      );
                    }).toList(),
                    onChanged: (valor) {
                      setState(() {
                        _categoriaSeleccionada = valor;
                      });
                    },
                    isRequired: true,
                    errorText: obtenerError('categoria'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Imágenes
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Imágenes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      AppIconButton(
                        icon: const Icon(Icons.add_photo_alternate),
                        onPressed: () {
                          // TODO: Implementar selector de imágenes
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_imagenesUrls.isEmpty)
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('No hay imágenes'),
                      ),
                    )
                  else
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imagenesUrls.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _imagenesUrls[index],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 100,
                                        height: 100,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.error),
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removerImagen(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Configuración
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuración',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: const Text('Producto activo'),
                    subtitle: const Text('El producto estará visible para los clientes'),
                    value: _productoActivo,
                    onChanged: (valor) {
                      setState(() {
                        _productoActivo = valor;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Botones de acción
          Row(
            children: [
              if (widget.onCancelar != null) ...[
                Expanded(
                  child: AppOutlineButton(
                    text: 'Cancelar',
                    onPressed: widget.onCancelar,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: AppButton(
                  text: widget.modoEdicion ? 'Actualizar' : 'Guardar',
                  onPressed: enviarFormulario,
                  isLoading: isLoading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProductoFormData {
  final String nombre;
  final String descripcion;
  final double precio;
  final int stock;
  final String categoriaId;
  final bool activo;
  final List<String> imagenesUrls;

  ProductoFormData({
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.stock,
    required this.categoriaId,
    required this.activo,
    required this.imagenesUrls,
  });
}

class CategoriaOption {
  final String id;
  final String nombre;

  CategoriaOption({
    required this.id,
    required this.nombre,
  });
}