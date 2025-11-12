import 'package:flutter/material.dart';

abstract class BaseWidget<T> extends StatelessWidget {
  final T? data;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final bool isSelected;
  final bool isEnabled;

  const BaseWidget({
    super.key,
    this.data,
    this.onTap,
    this.margin,
    this.padding,
    this.isSelected = false,
    this.isEnabled = true,
  });

  Widget buildContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      margin: margin,
      padding: padding,
      decoration: getDecoration(context),
      child: buildContent(context),
    );

    if (onTap != null && isEnabled) {
      content = GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }

  BoxDecoration? getDecoration(BuildContext context) {
    return BoxDecoration(
      color: getBackgroundColor(context),
      borderRadius: BorderRadius.circular(getBorderRadius()),
      border: getBorder(context),
      boxShadow: getShadow(context),
    );
  }

  Color getBackgroundColor(BuildContext context) {
    if (!isEnabled) {
      return Theme.of(context).colorScheme.surface.withValues(alpha: 0.5);
    }
    if (isSelected) {
      return Theme.of(context).colorScheme.primaryContainer;
    }
    return Theme.of(context).colorScheme.surface;
  }

  double getBorderRadius() => 12.0;

  Border? getBorder(BuildContext context) {
    if (isSelected) {
      return Border.all(
        color: Theme.of(context).colorScheme.primary,
        width: 2,
      );
    }
    return Border.all(
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
      width: 1,
    );
  }

  List<BoxShadow>? getShadow(BuildContext context) {
    if (!isEnabled) return null;

    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        offset: const Offset(0, 2),
        blurRadius: 4,
        spreadRadius: 0,
      ),
    ];
  }
}

abstract class BaseListTile<T> extends StatelessWidget {
  final T data;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? leading;
  final Widget? trailing;
  final bool isSelected;
  final bool isEnabled;
  final EdgeInsetsGeometry? contentPadding;

  const BaseListTile({
    super.key,
    required this.data,
    this.onTap,
    this.onLongPress,
    this.leading,
    this.trailing,
    this.isSelected = false,
    this.isEnabled = true,
    this.contentPadding,
  });

  Widget buildTitle(BuildContext context);
  Widget? buildSubtitle(BuildContext context) => null;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        enabled: isEnabled,
        selected: isSelected,
        onTap: isEnabled ? onTap : null,
        onLongPress: isEnabled ? onLongPress : null,
        leading: leading,
        title: buildTitle(context),
        subtitle: buildSubtitle(context),
        trailing: trailing,
        contentPadding: contentPadding ?? const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

abstract class BaseCard<T> extends StatelessWidget {
  final T data;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final bool isSelected;
  final bool isEnabled;

  const BaseCard({
    super.key,
    required this.data,
    this.onTap,
    this.onLongPress,
    this.margin,
    this.padding,
    this.elevation,
    this.isSelected = false,
    this.isEnabled = true,
  });

  Widget buildCardContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(8),
      child: Card(
        elevation: elevation ?? (isSelected ? 4 : 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : BorderSide.none,
        ),
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1)
            : null,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          onLongPress: isEnabled ? onLongPress : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: buildCardContent(context),
          ),
        ),
      ),
    );
  }
}

mixin LoadingStateMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  void setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
        if (loading) {
          _errorMessage = null;
        }
      });
    }
  }

  void setError(String? error) {
    if (mounted) {
      setState(() {
        _errorMessage = error;
        _isLoading = false;
      });
    }
  }

  void clearError() {
    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  Widget buildWithLoadingState({
    required Widget Function() builder,
    Widget? loadingWidget,
    Widget Function(String error)? errorBuilder,
  }) {
    if (_isLoading) {
      return loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return errorBuilder?.call(_errorMessage!) ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: clearError,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
    }

    return builder();
  }
}