import 'package:flutter/material.dart';
import '../mixins/paginacion_mixin.dart';
import '../mixins/busqueda_mixin.dart';
import '../ui/buttons/app_button.dart';
import '../ui/buttons/button_base.dart';

class ListaConFiltros<T> extends StatefulWidget {
  final Future<List<T>> Function({
    int page,
    int limit,
    String? search,
    Map<String, dynamic>? filters,
  }) cargarDatos;

  final Widget Function(T item, int index) itemBuilder;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final Widget? loadingWidget;
  final List<Widget> filtros;
  final Map<String, dynamic> filtrosIniciales;
  final String? hintBusqueda;
  final bool permitirBusqueda;
  final bool permitirRefresh;
  final EdgeInsetsGeometry? padding;

  const ListaConFiltros({
    super.key,
    required this.cargarDatos,
    required this.itemBuilder,
    this.emptyWidget,
    this.errorWidget,
    this.loadingWidget,
    this.filtros = const [],
    this.filtrosIniciales = const {},
    this.hintBusqueda,
    this.permitirBusqueda = true,
    this.permitirRefresh = true,
    this.padding,
  });

  @override
  State<ListaConFiltros<T>> createState() => _ListaConFiltrosState<T>();
}

class _ListaConFiltrosState<T> extends State<ListaConFiltros<T>>
    with PaginacionMixin, BusquedaMixin {

  Map<String, dynamic> filtrosActivos = {};
  bool mostrarFiltros = false;

  @override
  void initState() {
    super.initState();
    filtrosActivos = Map.from(widget.filtrosIniciales);
    filtros = Map.from(widget.filtrosIniciales);
  }

  @override
  Future<List<dynamic>> obtenerDatos({
    required int page,
    required int limit,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    return await widget.cargarDatos(
      page: page,
      limit: limit,
      search: search,
      filters: filters,
    );
  }

  @override
  void onError(dynamic error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  bool esBusquedaLocal() => false;

  @override
  void onBusquedaCompletada(String query, List<dynamic> resultados) {
    // Los resultados ya están en el estado de paginación
  }

  void _aplicarFiltros(Map<String, dynamic> nuevosFiltros) {
    setState(() {
      filtrosActivos = Map.from(nuevosFiltros);
    });
    aplicarFiltros(nuevosFiltros);
  }

  void _limpiarFiltros() {
    setState(() {
      filtrosActivos.clear();
    });
    limpiarFiltros();
  }

  void _toggleFiltros() {
    setState(() {
      mostrarFiltros = !mostrarFiltros;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header con búsqueda y filtros
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              // Búsqueda
              if (widget.permitirBusqueda)
                buildBuscador(
                  hintText: widget.hintBusqueda ?? 'Buscar...',
                ),

              // Toggle filtros
              if (widget.filtros.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Filtros ${filtrosActivos.isNotEmpty ? '(${filtrosActivos.length})' : ''}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    AppIconButton(
                      icon: Icon(
                        mostrarFiltros
                            ? Icons.expand_less
                            : Icons.expand_more,
                      ),
                      onPressed: _toggleFiltros,
                    ),
                    if (filtrosActivos.isNotEmpty)
                      AppTextButton(
                        text: 'Limpiar',
                        onPressed: _limpiarFiltros,
                        size: ButtonSize.small,
                      ),
                  ],
                ),
              ],

              // Filtros expandibles
              if (mostrarFiltros && widget.filtros.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                ...widget.filtros,
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppOutlineButton(
                        text: 'Limpiar filtros',
                        onPressed: _limpiarFiltros,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppButton(
                        text: 'Aplicar filtros',
                        onPressed: () => _aplicarFiltros(filtrosActivos),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Lista
        Expanded(
          child: buildPaginatedList(
            itemBuilder: (item, index) => widget.itemBuilder(item as T, index),
            emptyWidget: widget.emptyWidget,
            loadingWidget: widget.loadingWidget,
            padding: widget.padding,
          ),
        ),
      ],
    );
  }
}

class GridConFiltros<T> extends StatefulWidget {
  final Future<List<T>> Function({
    int page,
    int limit,
    String? search,
    Map<String, dynamic>? filters,
  }) cargarDatos;

  final Widget Function(T item, int index) itemBuilder;
  final int crossAxisCount;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;
  final double? childAspectRatio;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final Widget? loadingWidget;
  final List<Widget> filtros;
  final Map<String, dynamic> filtrosIniciales;
  final String? hintBusqueda;
  final bool permitirBusqueda;
  final EdgeInsetsGeometry? padding;

  const GridConFiltros({
    super.key,
    required this.cargarDatos,
    required this.itemBuilder,
    required this.crossAxisCount,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
    this.childAspectRatio,
    this.emptyWidget,
    this.errorWidget,
    this.loadingWidget,
    this.filtros = const [],
    this.filtrosIniciales = const {},
    this.hintBusqueda,
    this.permitirBusqueda = true,
    this.padding,
  });

  @override
  State<GridConFiltros<T>> createState() => _GridConFiltrosState<T>();
}

class _GridConFiltrosState<T> extends State<GridConFiltros<T>>
    with PaginacionMixin, BusquedaMixin {

  @override
  Future<List<dynamic>> obtenerDatos({
    required int page,
    required int limit,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    return await widget.cargarDatos(
      page: page,
      limit: limit,
      search: search,
      filters: filters,
    );
  }

  @override
  void onError(dynamic error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  bool esBusquedaLocal() => false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header con búsqueda
        if (widget.permitirBusqueda)
          Container(
            padding: const EdgeInsets.all(16),
            child: buildBuscador(
              hintText: widget.hintBusqueda ?? 'Buscar...',
            ),
          ),

        // Grid
        Expanded(
          child: buildGridPaginatedList(
            itemBuilder: (item, index) => widget.itemBuilder(item as T, index),
            crossAxisCount: widget.crossAxisCount,
            crossAxisSpacing: widget.crossAxisSpacing,
            mainAxisSpacing: widget.mainAxisSpacing,
            childAspectRatio: widget.childAspectRatio,
            emptyWidget: widget.emptyWidget,
            loadingWidget: widget.loadingWidget,
            padding: widget.padding,
          ),
        ),
      ],
    );
  }
}