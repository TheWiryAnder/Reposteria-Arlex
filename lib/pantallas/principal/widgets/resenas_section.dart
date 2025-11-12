import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../modelos/resena_modelo.dart';
import '../../../modelos/producto_modelo.dart';
import '../../../servicios/resenas_service.dart';
import '../../../providers/auth_provider_simple.dart';
import '../../../compartidos/widgets/message_helpers.dart';
import '../../auth/login_vista.dart';

/// Widget para mostrar y gestionar las reseñas de los clientes
class ResenasSection extends StatefulWidget {
  const ResenasSection({super.key});

  @override
  State<ResenasSection> createState() => _ResenasSectionState();
}

class _ResenasSectionState extends State<ResenasSection> {
  final ResenasService _resenasService = ResenasService();
  final _comentarioController = TextEditingController();
  int _valoracionSeleccionada = 5;

  // Producto seleccionado
  String? _productoSeleccionadoId;
  List<ProductoModelo> _productosDisponibles = [];
  bool _cargandoProductos = true;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  /// Cargar productos disponibles
  Future<void> _cargarProductos() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('productos')
          .where('disponible', isEqualTo: true)
          .get();

      setState(() {
        _productosDisponibles = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return ProductoModelo.fromJson(data);
        }).toList();

        // Ordenar por nombre en memoria
        _productosDisponibles.sort((a, b) => a.nombre.compareTo(b.nombre));
        _cargandoProductos = false;
      });
    } catch (e) {
      setState(() {
        _cargandoProductos = false;
      });
    }
  }

  /// Agregar una nueva reseña
  Future<void> _agregarResena() async {
    final authProvider = AuthProvider.instance;
    final usuario = authProvider.currentUser;

    // Si no está autenticado, redirigir directamente a login
    if (usuario == null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginVista(),
        ),
      );
      return;
    }

    // Validar comentario
    if (_comentarioController.text.trim().isEmpty) {
      if (!mounted) return;
      showAppMessage(
        context,
        'Por favor escribe un comentario',
        type: MessageType.warning,
      );
      return;
    }

    // Validar que se haya seleccionado un producto
    if (_productoSeleccionadoId == null) {
      if (!mounted) return;
      showAppMessage(
        context,
        'Por favor selecciona un producto',
        type: MessageType.warning,
      );
      return;
    }

    try {
      // Obtener datos del producto seleccionado
      final producto = _productosDisponibles.firstWhere(
        (p) => p.id == _productoSeleccionadoId,
      );

      await _resenasService.agregarResena(
        usuarioId: usuario.id,
        usuarioNombre: usuario.nombre,
        comentario: _comentarioController.text.trim(),
        valoracion: _valoracionSeleccionada,
        productoId: producto.id,
        productoNombre: producto.nombre,
        productoImagen: producto.imagenUrl,
      );

      if (!mounted) return;

      // Limpiar formulario
      _comentarioController.clear();
      setState(() {
        _valoracionSeleccionada = 5;
        _productoSeleccionadoId = null;
      });

      showAppMessage(
        context,
        '¡Gracias por tu reseña!',
        type: MessageType.success,
      );
    } catch (e) {
      if (!mounted) return;
      showAppMessage(
        context,
        'Error al agregar reseña: $e',
        type: MessageType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título y estadísticas
            _buildEncabezado(),
            const SizedBox(height: 24),

            // Formulario siempre visible
            _buildFormularioResena(),
            const SizedBox(height: 32),

            // Lista de reseñas
            _buildListaResenas(),
          ],
        ),
      ),
    );
  }

  Widget _buildEncabezado() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _resenasService.obtenerEstadisticas(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'total': 0, 'promedio': 0.0};
        final total = stats['total'] as int;
        final promedio = stats['promedio'] as double;

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reseñas de Clientes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < promedio.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        '${promedio.toStringAsFixed(1)} ($total ${total == 1 ? 'reseña' : 'reseñas'})',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFormularioResena() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de producto
            const Text(
              'Selecciona un Producto',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_cargandoProductos)
              const Center(child: CircularProgressIndicator())
            else if (_productosDisponibles.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('No hay productos disponibles'),
              )
            else
              DropdownButtonFormField<String>(
                value: _productoSeleccionadoId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Selecciona un producto...',
                ),
                isExpanded: true,
                items: _productosDisponibles.map((producto) {
                  return DropdownMenuItem<String>(
                    value: producto.id,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Miniatura del producto
                        if (producto.imagenUrl != null && producto.imagenUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              producto.imagenUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 40,
                                  height: 40,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.cake, size: 20),
                                );
                              },
                            ),
                          )
                        else
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.cake, size: 20),
                          ),
                        const SizedBox(width: 12),
                        Text(
                          producto.nombre,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _productoSeleccionadoId = value;
                  });
                },
              ),

            const SizedBox(height: 20),

            // Valoración
            const Text(
              'Tu Valoración',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                final estrella = index + 1;
                return IconButton(
                  onPressed: () {
                    setState(() => _valoracionSeleccionada = estrella);
                  },
                  icon: Icon(
                    estrella <= _valoracionSeleccionada
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Comentario
            const Text(
              'Tu Comentario',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _comentarioController,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Comparte tu experiencia con nosotros...',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),

            // Botón publicar
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _agregarResena,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Publicar Reseña'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaResenas() {
    return StreamBuilder<List<ResenaModelo>>(
      stream: _resenasService.streamResenas(limite: 10),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error al cargar reseñas: ${snapshot.error}'),
          );
        }

        final resenas = snapshot.data ?? [];

        if (resenas.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aún no hay reseñas',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¡Sé el primero en dejar tu opinión!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: resenas.map((resena) {
            return _buildTarjetaResena(resena);
          }).toList(),
        );
      },
    );
  }

  Widget _buildTarjetaResena(ResenaModelo resena) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final usuario = AuthProvider.instance.currentUser;
    final esPropia = usuario?.id == resena.usuarioId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto en miniatura
            if (resena.productoImagen != null && resena.productoImagen!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  resena.productoImagen!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.cake, size: 30),
                    );
                  },
                ),
              )
            else
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cake, size: 30),
              ),
            const SizedBox(width: 16),

            // Contenido de la reseña
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          resena.usuarioNombre[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  resena.usuarioNombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (esPropia) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Tu reseña',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            if (resena.productoNombre != null)
                              Text(
                                resena.productoNombre!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < resena.valoracion
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        _formatearFecha(resena.fecha),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    resena.comentario,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inDays == 0) {
      if (diferencia.inHours == 0) {
        if (diferencia.inMinutes == 0) {
          return 'Hace un momento';
        }
        return 'Hace ${diferencia.inMinutes} min';
      }
      return 'Hace ${diferencia.inHours}h';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays} días';
    } else if (diferencia.inDays < 30) {
      final semanas = (diferencia.inDays / 7).floor();
      return 'Hace $semanas ${semanas == 1 ? 'semana' : 'semanas'}';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }
}
