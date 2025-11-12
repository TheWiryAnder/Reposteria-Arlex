import 'package:flutter/material.dart';
import '../ui/inputs/input_text.dart';

class HeaderConBuscador extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final TextEditingController? controladorBusqueda;
  final ValueChanged<String>? onBusquedaChanged;
  final VoidCallback? onBusquedaSubmitted;
  final String? hintBusqueda;
  final List<Widget>? acciones;
  final Widget? leading;
  final bool mostrarBuscador;
  final bool centerTitle;
  final Color? backgroundColor;
  final double? elevation;
  final EdgeInsetsGeometry? padding;

  const HeaderConBuscador({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.controladorBusqueda,
    this.onBusquedaChanged,
    this.onBusquedaSubmitted,
    this.hintBusqueda,
    this.acciones,
    this.leading,
    this.mostrarBuscador = true,
    this.centerTitle = true,
    this.backgroundColor,
    this.elevation,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Theme.of(context).colorScheme.surface,
      padding: padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header principal
          Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: centerTitle
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitulo != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitulo!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (acciones != null) ...acciones!,
            ],
          ),

          // Buscador
          if (mostrarBuscador) ...[
            const SizedBox(height: 16),
            InputText(
              controller: controladorBusqueda,
              hint: hintBusqueda ?? 'Buscar...',
              prefixIcon: const Icon(Icons.search),
              onChanged: onBusquedaChanged,
              onSubmitted: onBusquedaSubmitted != null
                  ? (_) => onBusquedaSubmitted!()
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

class HeaderConFiltros extends StatelessWidget {
  final String titulo;
  final Widget? buscador;
  final List<Widget> filtros;
  final List<Widget>? acciones;
  final VoidCallback? onLimpiarFiltros;
  final EdgeInsetsGeometry? padding;

  const HeaderConFiltros({
    super.key,
    required this.titulo,
    this.buscador,
    this.filtros = const [],
    this.acciones,
    this.onLimpiarFiltros,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título y acciones
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (acciones != null) ...acciones!,
            ],
          ),

          // Buscador
          if (buscador != null) ...[
            const SizedBox(height: 16),
            buscador!,
          ],

          // Filtros
          if (filtros.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Filtros:',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: filtros,
                  ),
                ),
                if (onLimpiarFiltros != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onLimpiarFiltros,
                    child: const Text('Limpiar'),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class HeaderSeccion extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final Widget? icono;
  final List<Widget>? acciones;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const HeaderSeccion({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.icono,
    this.acciones,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      margin: margin,
      child: Row(
        children: [
          if (icono != null) ...[
            icono!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitulo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitulo!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (acciones != null) ...acciones!,
        ],
      ),
    );
  }
}