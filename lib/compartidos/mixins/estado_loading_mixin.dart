import 'package:flutter/material.dart';

enum EstadoCarga {
  inicial,
  cargando,
  exito,
  error,
  vacio,
}

mixin EstadoLoadingMixin<T extends StatefulWidget> on State<T> {
  EstadoCarga _estadoActual = EstadoCarga.inicial;
  String? _mensajeError;
  dynamic _datos;

  EstadoCarga get estado => _estadoActual;
  String? get mensajeError => _mensajeError;
  dynamic get datos => _datos;

  void setEstado(EstadoCarga nuevoEstado, {String? error, dynamic data}) {
    setState(() {
      _estadoActual = nuevoEstado;
      _mensajeError = error;
      _datos = data;
    });
  }

  void setLoading() {
    setEstado(EstadoCarga.cargando);
  }

  void setExito(dynamic data) {
    setEstado(EstadoCarga.exito, data: data);
  }

  void setError(String error) {
    setEstado(EstadoCarga.error, error: error);
  }

  void setVacio() {
    setEstado(EstadoCarga.vacio);
  }

  void setInicial() {
    setEstado(EstadoCarga.inicial);
  }

  bool get isLoading => _estadoActual == EstadoCarga.cargando;
  bool get hasError => _estadoActual == EstadoCarga.error;
  bool get hasData => _estadoActual == EstadoCarga.exito;
  bool get isEmpty => _estadoActual == EstadoCarga.vacio;
  bool get isInicial => _estadoActual == EstadoCarga.inicial;

  Widget buildConEstado({
    required Widget Function() onExito,
    Widget Function()? onLoading,
    Widget Function(String error)? onError,
    Widget Function()? onVacio,
    Widget Function()? onInicial,
  }) {
    switch (_estadoActual) {
      case EstadoCarga.inicial:
        return onInicial?.call() ?? const SizedBox.shrink();

      case EstadoCarga.cargando:
        return onLoading?.call() ?? _buildDefaultLoading();

      case EstadoCarga.exito:
        return onExito();

      case EstadoCarga.error:
        return onError?.call(_mensajeError ?? 'Error desconocido') ??
               _buildDefaultError(_mensajeError ?? 'Error desconocido');

      case EstadoCarga.vacio:
        return onVacio?.call() ?? _buildDefaultEmpty();
    }
  }

  Widget _buildDefaultLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando...'),
        ],
      ),
    );
  }

  Widget _buildDefaultError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Algo salió mal',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: reintentar,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay datos disponibles',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'No se encontraron elementos para mostrar',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> ejecutarConEstado<R>(
    Future<R> Function() operacion, {
    void Function(R resultado)? onExito,
    void Function(dynamic error)? onError,
  }) async {
    setLoading();

    try {
      final resultado = await operacion();

      if (resultado == null ||
          (resultado is List && resultado.isEmpty) ||
          (resultado is Map && resultado.isEmpty)) {
        setVacio();
      } else {
        setExito(resultado);
        onExito?.call(resultado);
      }
    } catch (error) {
      final errorMessage = _extractErrorMessage(error);
      setError(errorMessage);
      onError?.call(error);
    }
  }

  String _extractErrorMessage(dynamic error) {
    if (error is String) return error;
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'Ha ocurrido un error inesperado';
  }

  // Método que puede ser sobrescrito para manejar reintentos
  void reintentar() {
    // Override en las clases que usen este mixin
  }
}