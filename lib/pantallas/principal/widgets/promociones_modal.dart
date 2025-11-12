import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../../providers/auth_provider_simple.dart';
import '../../../compartidos/widgets/message_helpers.dart';
import '../../auth/login_vista.dart';

/// Modal emergente que muestra las promociones activas al ingresar al sitio
class PromocionesModal extends StatefulWidget {
  final List<QueryDocumentSnapshot> promociones;

  const PromocionesModal({
    super.key,
    required this.promociones,
  });

  @override
  State<PromocionesModal> createState() => _PromocionesModalState();
}

class _PromocionesModalState extends State<PromocionesModal> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Auto-play solo si hay más de una promoción
    if (widget.promociones.length > 1) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;

      final nextPage = (_currentPage + 1) % widget.promociones.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? screenSize.width * 0.9 : 650,
          maxHeight: screenSize.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con botón de cerrar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_offer, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        '¡Promociones Especiales!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 18 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Contenido del modal con PageView y flechas de navegación
            Flexible(
              child: Stack(
                children: [
                  // PageView con las promociones
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: widget.promociones.length,
                    itemBuilder: (context, index) {
                      return _buildPromocionCard(
                        context,
                        widget.promociones[index],
                        isMobile,
                      );
                    },
                  ),

                  // Flechas de navegación (solo si hay más de una promoción)
                  if (widget.promociones.length > 1) ...[
                    // Flecha izquierda
                    Positioned(
                      left: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(30),
                          elevation: 4,
                          child: InkWell(
                            onTap: () {
                              final previousPage = _currentPage == 0
                                  ? widget.promociones.length - 1
                                  : _currentPage - 1;
                              _pageController.animateToPage(
                                previousPage,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.chevron_left,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Flecha derecha
                    Positioned(
                      right: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(30),
                          elevation: 4,
                          child: InkWell(
                            onTap: () {
                              final nextPage =
                                  (_currentPage + 1) % widget.promociones.length;
                              _pageController.animateToPage(
                                nextPage,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.chevron_right,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Footer con indicadores de página
            if (widget.promociones.length > 1)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.promociones.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildPromocionCard(BuildContext context, QueryDocumentSnapshot promo, bool isMobile) {
    final data = promo.data() as Map<String, dynamic>;
    final titulo = data['titulo'] as String? ?? 'Promoción';
    final descripcion = data['descripcion'] as String? ?? '';
    final imagenUrl = data['imagenUrl'] as String?;
    final porcentajeDescuento = data['porcentajeDescuento'] as num?;
    final fechaFin = (data['fechaFin'] as Timestamp?)?.toDate();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular altura disponible para la imagen
        // Restar espacio para: badge (60), título (80), descripción (60), fecha (40), botón (70), padding (40)
        final availableHeight = constraints.maxHeight - 280;

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Imagen de la promoción
              if (imagenUrl != null && imagenUrl.isNotEmpty)
                Container(
                  constraints: BoxConstraints(
                    maxHeight: availableHeight > 150 ? availableHeight : 150,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imagenUrl,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.cake, size: 80, color: Colors.white),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Badge de descuento
              if (porcentajeDescuento != null && porcentajeDescuento > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.shade600,
                        Colors.orange.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    '¡${porcentajeDescuento.toStringAsFixed(0)}% DE DESCUENTO!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Título
              Text(
                titulo,
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Descripción
              if (descripcion.isNotEmpty)
                Text(
                  descripcion,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 16),

              // Fecha de vencimiento
              if (fechaFin != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer, size: 16, color: Colors.orange.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Válido hasta: ${_formatearFecha(fechaFin)}',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Botón de agregar al carrito
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final authProvider = AuthProvider.instance;
                    final bool isAuthenticated = authProvider.authState == AuthState.authenticated;

                    if (!isAuthenticated) {
                      // Mostrar mensaje y redirigir a login
                      showAppMessage(
                        context,
                        'Debes iniciar sesión para realizar compras',
                        type: MessageType.warning,
                      );
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginVista(),
                        ),
                      );
                      return;
                    }

                    // Verificar si el usuario es empleado
                    if (authProvider.currentUser?.rol == 'empleado') {
                      showAppMessage(
                        context,
                        'Los empleados no pueden realizar compras',
                        type: MessageType.warning,
                      );
                      return;
                    }

                    // Cerrar modal y mostrar mensaje de éxito
                    Navigator.of(context).pop();
                    showAppMessage(
                      context,
                      '$titulo - Compra exitosa',
                      type: MessageType.success,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.shopping_cart, size: 22),
                  label: const Text(
                    'Comprar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatearFecha(DateTime fecha) {
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${fecha.day} de ${meses[fecha.month - 1]} ${fecha.year}';
  }
}
