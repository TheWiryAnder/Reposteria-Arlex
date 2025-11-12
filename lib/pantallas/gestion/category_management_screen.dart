import 'package:flutter/material.dart';
import '../../servicios/categorias_service.dart';
import '../../compartidos/widgets/message_helpers.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final CategoriasService _categoriasService = CategoriasService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Categorías'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _mostrarFormularioCategoria(context),
            tooltip: 'Agregar Categoría',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: StreamBuilder<List<CategoriaModelo>>(
            stream: _categoriasService.streamCategorias(soloActivas: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                // Si hay error de permisos, mostrar mensaje amigable
                final errorMessage = snapshot.error.toString();
                final isPermissionError = errorMessage.contains('permission-denied');

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPermissionError ? Icons.lock_outline : Icons.error_outline,
                        size: 64,
                        color: isPermissionError ? Colors.orange : Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isPermissionError
                            ? 'Sin permisos para acceder a categorías'
                            : 'Error al cargar categorías',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          isPermissionError
                              ? 'Por favor, verifica que estés autenticado como administrador y que las reglas de Firebase permitan el acceso a la colección "categorias".'
                              : errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {}); // Forzar recarga
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              final categorias = snapshot.data ?? [];

              if (categorias.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay categorías registradas',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Presiona el botón + para agregar una categoría',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: categorias.length,
                itemBuilder: (context, index) {
                  final categoria = categorias[index];
                  return _buildCategoriaCard(categoria);
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioCategoria(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Categoría'),
      ),
    );
  }

  Widget _buildCategoriaCard(CategoriaModelo categoria) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: categoria.activa
                ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getIconData(categoria.icono),
            color: categoria.activa
                ? Theme.of(context).primaryColor
                : Colors.grey,
            size: 28,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                categoria.nombre,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: categoria.activa
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                categoria.activa ? 'Activa' : 'Inactiva',
                style: TextStyle(
                  color: categoria.activa ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (categoria.descripcion.isNotEmpty)
              Text(
                categoria.descripcion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.sort, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Orden: ${categoria.orden}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.confirmation_number, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'ID: ${categoria.id}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'editar':
                _mostrarFormularioCategoria(context, categoria: categoria);
                break;
              case 'toggle':
                _cambiarEstado(categoria);
                break;
              case 'eliminar':
                _confirmarEliminar(categoria);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'editar',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    categoria.activa ? Icons.block : Icons.check_circle,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(categoria.activa ? 'Desactivar' : 'Activar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'eliminar',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'cake':
        return Icons.cake;
      case 'cookie':
        return Icons.cookie;
      case 'bakery_dining':
        return Icons.bakery_dining;
      case 'breakfast_dining':
        return Icons.breakfast_dining;
      case 'emoji_food_beverage':
        return Icons.emoji_food_beverage;
      case 'icecream':
        return Icons.icecream;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'cake_outlined':
        return Icons.cake_outlined;
      default:
        return Icons.category;
    }
  }

  Future<void> _mostrarFormularioCategoria(BuildContext context, {CategoriaModelo? categoria}) async {
    final isEditing = categoria != null;
    final nombreController = TextEditingController(text: categoria?.nombre ?? '');
    final descripcionController = TextEditingController(text: categoria?.descripcion ?? '');

    // Si es nueva categoría, calcular el siguiente orden automáticamente
    int siguienteOrden = categoria?.orden ?? 0;
    if (!isEditing) {
      try {
        final categorias = await _categoriasService.streamCategorias(soloActivas: false).first;
        // Encontrar el orden máximo y sumarle 1
        if (categorias.isNotEmpty) {
          siguienteOrden = categorias.map((cat) => cat.orden).reduce((a, b) => a > b ? a : b) + 1;
        } else {
          siguienteOrden = 1;
        }
      } catch (e) {
        siguienteOrden = 1; // Valor por defecto si hay error
      }
    }

    final ordenController = TextEditingController(text: siguienteOrden.toString());
    String iconoSeleccionado = categoria?.icono ?? 'cake';
    bool activa = categoria?.activa ?? true;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? 'Editar Categoría' : 'Nueva Categoría'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la categoría',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ordenController,
                    decoration: InputDecoration(
                      labelText: 'Orden de visualización',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.sort),
                      helperText: isEditing
                          ? null
                          : 'Se asigna automáticamente el siguiente número disponible',
                      filled: !isEditing,
                      fillColor: !isEditing ? Colors.grey.withValues(alpha: 0.1) : null,
                    ),
                    keyboardType: TextInputType.number,
                    enabled: isEditing, // Solo editable si estamos editando una categoría existente
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Seleccionar icono:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'cake',
                      'cookie',
                      'bakery_dining',
                      'breakfast_dining',
                      'emoji_food_beverage',
                      'icecream',
                      'local_cafe',
                      'cake_outlined',
                    ].map((icono) {
                      final isSelected = iconoSeleccionado == icono;
                      return InkWell(
                        onTap: () {
                          setDialogState(() {
                            iconoSeleccionado = icono;
                          });
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _getIconData(icono),
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Categoría activa'),
                    subtitle: const Text('Los usuarios podrán ver esta categoría'),
                    value: activa,
                    onChanged: (value) {
                      setDialogState(() {
                        activa = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nombreController.text.trim().isEmpty) {
                    showAppMessage(
                      context,
                      'Por favor ingresa un nombre para la categoría',
                      type: MessageType.warning,
                    );
                    return;
                  }

                  final nombre = nombreController.text.trim();
                  final descripcion = descripcionController.text.trim();
                  final orden = int.tryParse(ordenController.text.trim()) ?? 0;

                  if (isEditing) {
                    // Actualizar categoría existente
                    final resultado = await _categoriasService.actualizarCategoria(
                      categoriaId: categoria.id,
                      cambios: {
                        'nombre': nombre,
                        'descripcion': descripcion,
                        'icono': iconoSeleccionado,
                        'orden': orden,
                        'activa': activa,
                      },
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      showAppMessage(
                        context,
                        resultado['success']
                            ? 'Categoría actualizada exitosamente'
                            : resultado['message'],
                        type: resultado['success']
                            ? MessageType.success
                            : MessageType.error,
                      );
                    }
                  } else {
                    // Crear nueva categoría
                    final id = _categoriasService.generarIdCategoria(nombre);

                    final nuevaCategoria = CategoriaModelo(
                      id: id,
                      nombre: nombre,
                      descripcion: descripcion,
                      icono: iconoSeleccionado,
                      orden: orden,
                      activa: activa,
                      fechaCreacion: DateTime.now(),
                      fechaActualizacion: DateTime.now(),
                    );

                    final resultado = await _categoriasService.crearCategoria(nuevaCategoria);

                    if (context.mounted) {
                      Navigator.pop(context);
                      showAppMessage(
                        context,
                        resultado['success']
                            ? 'Categoría creada exitosamente'
                            : resultado['message'],
                        type: resultado['success']
                            ? MessageType.success
                            : MessageType.error,
                      );
                    }
                  }
                },
                child: Text(isEditing ? 'Actualizar' : 'Crear'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _cambiarEstado(CategoriaModelo categoria) async {
    final resultado = await _categoriasService.cambiarEstado(
      categoriaId: categoria.id,
      activa: !categoria.activa,
    );

    if (mounted) {
      showAppMessage(
        context,
        resultado['success']
            ? 'Estado actualizado exitosamente'
            : resultado['message'],
        type: resultado['success'] ? MessageType.success : MessageType.error,
      );
    }
  }

  void _confirmarEliminar(CategoriaModelo categoria) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar la categoría "${categoria.nombre}"?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);

              final resultado = await _categoriasService.eliminarCategoria(categoria.id);

              if (mounted) {
                showAppMessage(
                  context,
                  resultado['success']
                      ? 'Categoría eliminada exitosamente'
                      : resultado['message'],
                  type: resultado['success']
                      ? MessageType.success
                      : MessageType.error,
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}