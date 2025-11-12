import 'package:flutter/material.dart';

mixin PaginacionMixin<T extends StatefulWidget> on State<T> {
  final ScrollController scrollController = ScrollController();

  int currentPage = 1;
  int itemsPerPage = 20;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  List<dynamic> items = [];
  String? searchQuery;
  Map<String, dynamic> filtros = {};

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
    cargarDatos();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore && hasMoreData) {
        cargarMasDatos();
      }
    }
  }

  Future<void> cargarDatos({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        currentPage = 1;
        items.clear();
        hasMoreData = true;
      });
    }

    try {
      final nuevosItems = await obtenerDatos(
        page: currentPage,
        limit: itemsPerPage,
        search: searchQuery,
        filters: filtros,
      );

      setState(() {
        if (refresh) {
          items = nuevosItems;
        } else {
          items.addAll(nuevosItems);
        }

        hasMoreData = nuevosItems.length == itemsPerPage;
        if (hasMoreData) {
          currentPage++;
        }
      });
    } catch (error) {
      onError(error);
    }
  }

  Future<void> cargarMasDatos() async {
    if (isLoadingMore || !hasMoreData) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      final nuevosItems = await obtenerDatos(
        page: currentPage,
        limit: itemsPerPage,
        search: searchQuery,
        filters: filtros,
      );

      setState(() {
        items.addAll(nuevosItems);
        hasMoreData = nuevosItems.length == itemsPerPage;
        if (hasMoreData) {
          currentPage++;
        }
      });
    } catch (error) {
      onError(error);
    } finally {
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  Future<void> buscar(String query) async {
    searchQuery = query.isNotEmpty ? query : null;
    await cargarDatos(refresh: true);
  }

  Future<void> aplicarFiltros(Map<String, dynamic> nuevosFiltros) async {
    filtros = nuevosFiltros;
    await cargarDatos(refresh: true);
  }

  Future<void> limpiarFiltros() async {
    filtros.clear();
    searchQuery = null;
    await cargarDatos(refresh: true);
  }

  Future<void> refresh() async {
    await cargarDatos(refresh: true);
  }

  Widget buildPaginatedList({
    required Widget Function(dynamic item, int index) itemBuilder,
    Widget? emptyWidget,
    Widget? loadingWidget,
    Widget? errorWidget,
    EdgeInsetsGeometry? padding,
  }) {
    if (items.isEmpty && !isLoadingMore) {
      return emptyWidget ?? const Center(
        child: Text('No hay elementos para mostrar'),
      );
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.builder(
        controller: scrollController,
        padding: padding,
        itemCount: items.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return loadingWidget ?? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return itemBuilder(items[index], index);
        },
      ),
    );
  }

  Widget buildGridPaginatedList({
    required Widget Function(dynamic item, int index) itemBuilder,
    required int crossAxisCount,
    double? crossAxisSpacing,
    double? mainAxisSpacing,
    double? childAspectRatio,
    Widget? emptyWidget,
    Widget? loadingWidget,
    EdgeInsetsGeometry? padding,
  }) {
    if (items.isEmpty && !isLoadingMore) {
      return emptyWidget ?? const Center(
        child: Text('No hay elementos para mostrar'),
      );
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: GridView.builder(
        controller: scrollController,
        padding: padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing ?? 8.0,
          mainAxisSpacing: mainAxisSpacing ?? 8.0,
          childAspectRatio: childAspectRatio ?? 1.0,
        ),
        itemCount: items.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return loadingWidget ?? const Center(
              child: CircularProgressIndicator(),
            );
          }

          return itemBuilder(items[index], index);
        },
      ),
    );
  }

  // Métodos abstractos que deben ser implementados
  Future<List<dynamic>> obtenerDatos({
    required int page,
    required int limit,
    String? search,
    Map<String, dynamic>? filters,
  });

  void onError(dynamic error);
}