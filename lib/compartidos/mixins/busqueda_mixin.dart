import 'package:flutter/material.dart';
import 'dart:async';

mixin BusquedaMixin<T extends StatefulWidget> on State<T> {
  final TextEditingController controladorBusqueda = TextEditingController();
  final FocusNode focoBusqueda = FocusNode();

  Timer? _debounceTimer;
  String _queryAnterior = '';
  List<dynamic> _resultadosOriginales = [];
  List<dynamic> _resultadosFiltrados = [];
  bool _isBuscando = false;

  Duration get tiempoDebounce => const Duration(milliseconds: 500);

  List<dynamic> get resultados => _resultadosFiltrados;
  bool get isBuscando => _isBuscando;
  String get queryActual => controladorBusqueda.text;

  @override
  void initState() {
    super.initState();
    controladorBusqueda.addListener(_onBusquedaChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    controladorBusqueda.dispose();
    focoBusqueda.dispose();
    super.dispose();
  }

  void _onBusquedaChanged() {
    final query = controladorBusqueda.text;

    if (query == _queryAnterior) return;

    _queryAnterior = query;

    // Cancelar el timer anterior si existe
    _debounceTimer?.cancel();

    // Si la búsqueda está vacía, mostrar todos los resultados
    if (query.trim().isEmpty) {
      setState(() {
        _isBuscando = false;
        _resultadosFiltrados = List.from(_resultadosOriginales);
      });
      onBusquedaLimpiada();
      return;
    }

    // Establecer nuevo timer para la búsqueda
    _debounceTimer = Timer(tiempoDebounce, () {
      _realizarBusqueda(query);
    });
  }

  Future<void> _realizarBusqueda(String query) async {
    if (!mounted) return;

    setState(() {
      _isBuscando = true;
    });

    try {
      // Si es búsqueda local
      if (esBusquedaLocal()) {
        _resultadosFiltrados = _filtrarLocal(query);
      } else {
        // Si es búsqueda remota
        _resultadosFiltrados = await buscarRemoto(query);
      }

      setState(() {
        _isBuscando = false;
      });

      onBusquedaCompletada(query, _resultadosFiltrados);
    } catch (error) {
      setState(() {
        _isBuscando = false;
      });
      onErrorBusqueda(error);
    }
  }

  List<dynamic> _filtrarLocal(String query) {
    final queryLower = query.toLowerCase().trim();

    return _resultadosOriginales.where((item) {
      return camposBusquedaLocal(item)
          .any((campo) => campo.toLowerCase().contains(queryLower));
    }).toList();
  }

  void establecerDatos(List<dynamic> datos) {
    setState(() {
      _resultadosOriginales = List.from(datos);
      _resultadosFiltrados = List.from(datos);
    });
  }

  void agregarDatos(List<dynamic> nuevosDatos) {
    setState(() {
      _resultadosOriginales.addAll(nuevosDatos);
      if (controladorBusqueda.text.trim().isEmpty) {
        _resultadosFiltrados.addAll(nuevosDatos);
      }
    });
  }

  void limpiarBusqueda() {
    controladorBusqueda.clear();
    focoBusqueda.unfocus();
  }

  void buscarTexto(String texto) {
    controladorBusqueda.text = texto;
  }

  Widget buildBuscador({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    InputDecoration? decoration,
  }) {
    return Container(
      margin: margin,
      padding: padding,
      child: TextField(
        controller: controladorBusqueda,
        focusNode: focoBusqueda,
        keyboardType: keyboardType ?? TextInputType.text,
        decoration: decoration ?? InputDecoration(
          hintText: hintText ?? 'Buscar...',
          prefixIcon: prefixIcon ?? const Icon(Icons.search),
          suffixIcon: _buildSuffixIcon(suffixIcon),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon(Widget? customSuffixIcon) {
    if (_isBuscando) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (controladorBusqueda.text.isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.clear),
        onPressed: limpiarBusqueda,
      );
    }

    return customSuffixIcon;
  }

  // Métodos que pueden ser sobrescritos

  /// Determina si la búsqueda se realiza localmente o remotamente
  bool esBusquedaLocal() => true;

  /// Campos que se utilizan para la búsqueda local
  List<String> camposBusquedaLocal(dynamic item) {
    // Override este método para especificar los campos de búsqueda
    return [item.toString()];
  }

  /// Búsqueda remota (override si es necesario)
  Future<List<dynamic>> buscarRemoto(String query) async {
    throw UnimplementedError('Implementar buscarRemoto si esBusquedaLocal() retorna false');
  }

  /// Callback cuando se completa una búsqueda
  void onBusquedaCompletada(String query, List<dynamic> resultados) {}

  /// Callback cuando se limpia la búsqueda
  void onBusquedaLimpiada() {}

  /// Callback cuando ocurre un error en la búsqueda
  void onErrorBusqueda(dynamic error) {}
}