import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../controladores/configuracion_sistema_controlador.dart';

class ConfiguracionSistemaVista extends StatefulWidget {
  final String? usuarioId;

  const ConfiguracionSistemaVista({
    super.key,
    this.usuarioId,
  });

  @override
  State<ConfiguracionSistemaVista> createState() => _ConfiguracionSistemaVistaState();
}

class _ConfiguracionSistemaVistaState extends State<ConfiguracionSistemaVista>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final controlador = context.read<ConfiguracionSistemaControlador>();
    if (widget.usuarioId != null) {
      controlador.setUsuarioId(widget.usuarioId!);
    }
    await controlador.cargarConfiguracion();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración del Sistema'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Módulos', icon: Icon(Icons.apps, size: 20)),
            Tab(text: 'Características', icon: Icon(Icons.settings, size: 20)),
            Tab(text: 'Inicio', icon: Icon(Icons.home, size: 20)),
            Tab(text: 'Productos', icon: Icon(Icons.shopping_bag, size: 20)),
            Tab(text: 'Pedidos', icon: Icon(Icons.shopping_cart, size: 20)),
            Tab(text: 'Métodos de Pago', icon: Icon(Icons.payment, size: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Recargar',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'restaurar') {
                _mostrarDialogoRestaurar();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'restaurar',
                child: Row(
                  children: [
                    Icon(Icons.restore, size: 20),
                    SizedBox(width: 8),
                    Text('Restaurar por defecto'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<ConfiguracionSistemaControlador>(
        builder: (context, controlador, child) {
          if (controlador.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controlador.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar la configuración',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controlador.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _cargarDatos,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (controlador.configuracion == null) {
            return const Center(
              child: Text('No se pudo cargar la configuración'),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildModulosTab(controlador),
              _buildCaracteristicasTab(controlador),
              _buildSeccionesInicioTab(controlador),
              _buildProductosTab(controlador),
              _buildPedidosTab(controlador),
              _buildMetodosPagoTab(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModulosTab(ConfiguracionSistemaControlador controlador) {
    final modulos = controlador.modulos;
    if (modulos == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSeccionHeader(
          'Módulos Principales',
          'Controla qué módulos son visibles para los clientes',
        ),
        _buildSwitchCard(
          'Catálogo de Productos',
          'Muestra el catálogo completo de productos',
          Icons.shopping_bag,
          modulos.catalogo,
          (value) => controlador.toggleModulo('catalogo', value),
        ),
        _buildSwitchCard(
          'Carrito de Compras',
          'Permite agregar productos al carrito',
          Icons.shopping_cart,
          modulos.carrito,
          (value) => controlador.toggleModulo('carrito', value),
        ),
        _buildSwitchCard(
          'Pedidos',
          'Sistema de gestión de pedidos',
          Icons.receipt_long,
          modulos.pedidos,
          (value) => controlador.toggleModulo('pedidos', value),
        ),
        _buildSwitchCard(
          'Reservas',
          'Sistema de reservas anticipadas',
          Icons.event,
          modulos.reservas,
          (value) => controlador.toggleModulo('reservas', value),
        ),
        _buildSwitchCard(
          'Promociones',
          'Muestra promociones y ofertas especiales',
          Icons.local_offer,
          modulos.promociones,
          (value) => controlador.toggleModulo('promociones', value),
        ),
        _buildSwitchCard(
          'Sobre Nosotros',
          'Información del negocio',
          Icons.info,
          modulos.sobreNosotros,
          (value) => controlador.toggleModulo('sobreNosotros', value),
        ),
        _buildSwitchCard(
          'Contacto',
          'Formulario y datos de contacto',
          Icons.contact_mail,
          modulos.contacto,
          (value) => controlador.toggleModulo('contacto', value),
        ),
        _buildSwitchCard(
          'Testimonios',
          'Opiniones de clientes',
          Icons.star,
          modulos.testimonios,
          (value) => controlador.toggleModulo('testimonios', value),
        ),
        _buildSwitchCard(
          'Galería',
          'Galería de fotos del negocio',
          Icons.photo_library,
          modulos.galeria,
          (value) => controlador.toggleModulo('galeria', value),
        ),
        _buildSwitchCard(
          'Blog',
          'Blog y artículos (Experimental)',
          Icons.article,
          modulos.blog,
          (value) => controlador.toggleModulo('blog', value),
        ),
      ],
    );
  }

  Widget _buildCaracteristicasTab(ConfiguracionSistemaControlador controlador) {
    final caracteristicas = controlador.caracteristicas;
    if (caracteristicas == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSeccionHeader(
          'Características del Sistema',
          'Activa o desactiva funcionalidades específicas',
        ),
        _buildSwitchCard(
          'Registro de Usuarios',
          'Permite que nuevos usuarios se registren',
          Icons.person_add,
          caracteristicas.registroUsuarios,
          (value) => controlador.toggleCaracteristica('registroUsuarios', value),
        ),
        _buildSwitchCard(
          'Login Requerido',
          'Requiere login para realizar compras',
          Icons.lock,
          caracteristicas.loginRequerido,
          (value) => controlador.toggleCaracteristica('loginRequerido', value),
        ),
        _buildSwitchCard(
          'Comentarios en Productos',
          'Permite a los clientes comentar productos',
          Icons.comment,
          caracteristicas.comentariosProductos,
          (value) => controlador.toggleCaracteristica('comentariosProductos', value),
        ),
        _buildSwitchCard(
          'Calificación de Productos',
          'Permite calificar productos con estrellas',
          Icons.star_rate,
          caracteristicas.calificacionProductos,
          (value) => controlador.toggleCaracteristica('calificacionProductos', value),
        ),
        _buildSwitchCard(
          'Compartir en Redes',
          'Botones para compartir en redes sociales',
          Icons.share,
          caracteristicas.compartirRedes,
          (value) => controlador.toggleCaracteristica('compartirRedes', value),
        ),
        _buildSwitchCard(
          'Newsletter',
          'Suscripción a boletín de noticias',
          Icons.email,
          caracteristicas.newsletter,
          (value) => controlador.toggleCaracteristica('newsletter', value),
        ),
        _buildSwitchCard(
          'Cupones de Descuento',
          'Sistema de cupones promocionales',
          Icons.discount,
          caracteristicas.cupones,
          (value) => controlador.toggleCaracteristica('cupones', value),
        ),
        _buildSwitchCard(
          'Programa de Lealtad',
          'Sistema de puntos y recompensas (Experimental)',
          Icons.loyalty,
          caracteristicas.programaLealtad,
          (value) => controlador.toggleCaracteristica('programaLealtad', value),
        ),
        _buildSwitchCard(
          'Notificaciones Push',
          'Envío de notificaciones push (Experimental)',
          Icons.notifications,
          caracteristicas.notificacionesPush,
          (value) => controlador.toggleCaracteristica('notificacionesPush', value),
        ),
        _buildSwitchCard(
          'Chat en Vivo',
          'Chat de soporte en tiempo real (Experimental)',
          Icons.chat,
          caracteristicas.chatEnVivo,
          (value) => controlador.toggleCaracteristica('chatEnVivo', value),
        ),
      ],
    );
  }

  Widget _buildSeccionesInicioTab(ConfiguracionSistemaControlador controlador) {
    final secciones = controlador.seccionesInicio;
    if (secciones == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSeccionHeader(
          'Secciones de la Página de Inicio',
          'Personaliza qué se muestra en la página principal',
        ),
        _buildSwitchCard(
          'Banner Principal',
          'Slider de imágenes promocionales',
          Icons.view_carousel,
          secciones.bannerPrincipal,
          (value) => controlador.toggleSeccionInicio('bannerPrincipal', value),
        ),
        _buildSwitchCard(
          'Productos Destacados',
          'Sección de productos recomendados',
          Icons.star,
          secciones.productosDestacados,
          (value) => controlador.toggleSeccionInicio('productosDestacados', value),
        ),
        _buildSwitchCard(
          'Promociones',
          'Banner de promociones activas',
          Icons.local_offer,
          secciones.promociones,
          (value) => controlador.toggleSeccionInicio('promociones', value),
        ),
        _buildSwitchCard(
          'Categorías',
          'Grid de categorías principales',
          Icons.category,
          secciones.categorias,
          (value) => controlador.toggleSeccionInicio('categorias', value),
        ),
        _buildSwitchCard(
          'Testimonios',
          'Opiniones destacadas de clientes',
          Icons.format_quote,
          secciones.testimonios,
          (value) => controlador.toggleSeccionInicio('testimonios', value),
        ),
        _buildSwitchCard(
          'Sobre Nosotros',
          'Resumen de la información del negocio',
          Icons.info,
          secciones.sobreNosotros,
          (value) => controlador.toggleSeccionInicio('sobreNosotros', value),
        ),
        _buildSwitchCard(
          'Galería',
          'Galería de fotos destacadas',
          Icons.photo_library,
          secciones.galeria,
          (value) => controlador.toggleSeccionInicio('galeria', value),
        ),
        _buildSwitchCard(
          'Blog',
          'Últimas entradas del blog',
          Icons.article,
          secciones.blog,
          (value) => controlador.toggleSeccionInicio('blog', value),
        ),
        _buildSwitchCard(
          'Newsletter',
          'Formulario de suscripción',
          Icons.mail_outline,
          secciones.newsletter,
          (value) => controlador.toggleSeccionInicio('newsletter', value),
        ),
        _buildSwitchCard(
          'Redes Sociales',
          'Iconos de redes sociales',
          Icons.share,
          secciones.redesSociales,
          (value) => controlador.toggleSeccionInicio('redesSociales', value),
        ),
      ],
    );
  }

  Widget _buildProductosTab(ConfiguracionSistemaControlador controlador) {
    final productos = controlador.productos;
    if (productos == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSeccionHeader(
          'Configuración de Productos',
          'Controla qué información se muestra en los productos',
        ),
        _buildSwitchCard(
          'Mostrar Precio',
          'Muestra el precio de los productos',
          Icons.attach_money,
          productos.mostrarPrecio,
          (value) async {
            final nuevos = productos.copyWith(mostrarPrecio: value);
            await controlador.actualizarConfiguracionProductos(nuevos);
          },
        ),
        _buildSwitchCard(
          'Mostrar Descuentos',
          'Muestra descuentos y precios tachados',
          Icons.discount,
          productos.mostrarDescuento,
          (value) async {
            final nuevos = productos.copyWith(mostrarDescuento: value);
            await controlador.actualizarConfiguracionProductos(nuevos);
          },
        ),
        _buildSwitchCard(
          'Mostrar Stock',
          'Muestra disponibilidad de productos',
          Icons.inventory,
          productos.mostrarStock,
          (value) async {
            final nuevos = productos.copyWith(mostrarStock: value);
            await controlador.actualizarConfiguracionProductos(nuevos);
          },
        ),
        _buildSwitchCard(
          'Mostrar Calificaciones',
          'Muestra estrellas de calificación',
          Icons.star,
          productos.mostrarCalificaciones,
          (value) async {
            final nuevos = productos.copyWith(mostrarCalificaciones: value);
            await controlador.actualizarConfiguracionProductos(nuevos);
          },
        ),
        _buildSwitchCard(
          'Mostrar Comentarios',
          'Muestra comentarios de clientes',
          Icons.comment,
          productos.mostrarComentarios,
          (value) async {
            final nuevos = productos.copyWith(mostrarComentarios: value);
            await controlador.actualizarConfiguracionProductos(nuevos);
          },
        ),
        _buildSwitchCard(
          'Permitir Compra Directa',
          'Botón "Comprar ahora" en productos',
          Icons.shopping_cart,
          productos.permitirCompraDirecta,
          (value) async {
            final nuevos = productos.copyWith(permitirCompraDirecta: value);
            await controlador.actualizarConfiguracionProductos(nuevos);
          },
        ),
        _buildSwitchCard(
          'Productos Relacionados',
          'Muestra productos similares',
          Icons.link,
          productos.mostrarProductosRelacionados,
          (value) async {
            final nuevos = productos.copyWith(mostrarProductosRelacionados: value);
            await controlador.actualizarConfiguracionProductos(nuevos);
          },
        ),
        _buildSwitchCard(
          'Imágenes Adicionales',
          'Galería de múltiples imágenes',
          Icons.photo_size_select_actual,
          productos.mostrarImagenesAdicionales,
          (value) async {
            final nuevos = productos.copyWith(mostrarImagenesAdicionales: value);
            await controlador.actualizarConfiguracionProductos(nuevos);
          },
        ),
      ],
    );
  }

  Widget _buildPedidosTab(ConfiguracionSistemaControlador controlador) {
    final pedidos = controlador.pedidos;
    if (pedidos == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSeccionHeader(
          'Configuración de Pedidos',
          'Gestiona cómo funcionan los pedidos y reservas',
        ),
        _buildSwitchCard(
          'Permitir Pedidos Online',
          'Los clientes pueden hacer pedidos por la web',
          Icons.shopping_bag,
          pedidos.permitirPedidosOnline,
          (value) async {
            final nuevos = pedidos.copyWith(permitirPedidosOnline: value);
            await controlador.actualizarConfiguracionPedidos(nuevos);
          },
        ),
        _buildSwitchCard(
          'Permitir Reservas',
          'Los clientes pueden hacer reservas anticipadas',
          Icons.event,
          pedidos.permitirReservas,
          (value) async {
            final nuevos = pedidos.copyWith(permitirReservas: value);
            await controlador.actualizarConfiguracionPedidos(nuevos);
          },
        ),
        _buildSwitchCard(
          'Requerir Confirmación',
          'Los pedidos requieren confirmación del admin',
          Icons.check_circle,
          pedidos.requerirConfirmacion,
          (value) async {
            final nuevos = pedidos.copyWith(requerirConfirmacion: value);
            await controlador.actualizarConfiguracionPedidos(nuevos);
          },
        ),
        _buildSwitchCard(
          'Mostrar Estado del Pedido',
          'Los clientes pueden ver el estado en tiempo real',
          Icons.track_changes,
          pedidos.mostrarEstadoPedido,
          (value) async {
            final nuevos = pedidos.copyWith(mostrarEstadoPedido: value);
            await controlador.actualizarConfiguracionPedidos(nuevos);
          },
        ),
        _buildSwitchCard(
          'Permitir Cancelación',
          'Los clientes pueden cancelar sus pedidos',
          Icons.cancel,
          pedidos.permitirCancelacion,
          (value) async {
            final nuevos = pedidos.copyWith(permitirCancelacion: value);
            await controlador.actualizarConfiguracionPedidos(nuevos);
          },
        ),
        _buildSwitchCard(
          'Notificar Cliente',
          'Enviar notificaciones sobre cambios en el pedido',
          Icons.notifications,
          pedidos.notificarCliente,
          (value) async {
            final nuevos = pedidos.copyWith(notificarCliente: value);
            await controlador.actualizarConfiguracionPedidos(nuevos);
          },
        ),
        _buildSwitchCard(
          'Pago Online',
          'Permitir pago con tarjeta online (Experimental)',
          Icons.credit_card,
          pedidos.permitirPagoOnline,
          (value) async {
            final nuevos = pedidos.copyWith(permitirPagoOnline: value);
            await controlador.actualizarConfiguracionPedidos(nuevos);
          },
        ),
        _buildSwitchCard(
          'Pago Contraentrega',
          'Permitir pago al recibir el pedido',
          Icons.local_shipping,
          pedidos.permitirPagoContraentrega,
          (value) async {
            final nuevos = pedidos.copyWith(permitirPagoContraentrega: value);
            await controlador.actualizarConfiguracionPedidos(nuevos);
          },
        ),
      ],
    );
  }

  Widget _buildSeccionHeader(String titulo, String subtitulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildSwitchCard(
    String titulo,
    String descripcion,
    IconData icono,
    bool valor,
    Future<void> Function(bool) onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        secondary: Icon(icono, color: Theme.of(context).primaryColor),
        title: Text(titulo),
        subtitle: Text(descripcion),
        value: valor,
        onChanged: (value) async {
          await onChanged(value);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$titulo ${value ? "activado" : "desactivado"}'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  Future<void> _mostrarDialogoRestaurar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar Configuración'),
        content: const Text(
          '¿Estás seguro de que deseas restaurar toda la configuración a los valores por defecto?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      final controlador = context.read<ConfiguracionSistemaControlador>();
      final resultado = await controlador.restaurarPorDefecto();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resultado
                ? 'Configuración restaurada exitosamente'
                : 'Error al restaurar configuración',
          ),
          backgroundColor: resultado ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Widget _buildMetodosPagoTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('configuracion')
          .doc('metodosPago')
          .snapshots(),
      builder: (context, snapshot) {
        // Manejar errores
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar configuración',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        // Manejar estado de carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        String? yapeQR;
        String? plinQR;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          yapeQR = data?['yapeQR'] as String?;
          plinQR = data?['plinQR'] as String?;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSeccionHeader(
              'Configuración de Métodos de Pago',
              'Configura las imágenes QR para los métodos de pago Yape y Plin',
            ),

            // Sección Yape
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payment, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Yape',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (yapeQR != null && yapeQR.isNotEmpty)
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              'QR actual:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  yapeQR,
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return SizedBox(
                                      width: 200,
                                      height: 200,
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
                                      width: 200,
                                      height: 200,
                                      color: Colors.grey.shade200,
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.error_outline, size: 40, color: Colors.red),
                                          SizedBox(height: 8),
                                          Text('Error al cargar imagen'),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Center(
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code, size: 60, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'No hay QR configurado',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _subirQR('yape', yapeQR),
                        icon: const Icon(Icons.upload_file),
                        label: Text(yapeQR != null && yapeQR.isNotEmpty
                            ? 'Cambiar QR de Yape'
                            : 'Subir QR de Yape'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sección Plin
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payment, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Plin',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (plinQR != null && plinQR.isNotEmpty)
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              'QR actual:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  plinQR,
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return SizedBox(
                                      width: 200,
                                      height: 200,
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
                                      width: 200,
                                      height: 200,
                                      color: Colors.grey.shade200,
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.error_outline, size: 40, color: Colors.red),
                                          SizedBox(height: 8),
                                          Text('Error al cargar imagen'),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Center(
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code, size: 60, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'No hay QR configurado',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _subirQR('plin', plinQR),
                        icon: const Icon(Icons.upload_file),
                        label: Text(plinQR != null && plinQR.isNotEmpty
                            ? 'Cambiar QR de Plin'
                            : 'Subir QR de Plin'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _subirQR(String metodoPago, String? qrActual) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      if (!mounted) return;

      // Mostrar diálogo de progreso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Subiendo imagen...'),
            ],
          ),
        ),
      );

      // Leer bytes de la imagen
      final Uint8List imageBytes = await image.readAsBytes();

      // Subir a Firebase Storage
      final String fileName = '${metodoPago}_qr_${DateTime.now().millisecondsSinceEpoch}.png';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('metodos_pago')
          .child(fileName);

      final UploadTask uploadTask = storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/png'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Guardar URL en Firestore
      await FirebaseFirestore.instance
          .collection('configuracion')
          .doc('metodosPago')
          .set(
        {
          '${metodoPago}QR': downloadUrl,
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      // Cerrar diálogo de progreso
      Navigator.pop(context);

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR de $metodoPago actualizado exitosamente'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Cerrar diálogo de progreso si está abierto
      Navigator.of(context).pop();

      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir imagen: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
