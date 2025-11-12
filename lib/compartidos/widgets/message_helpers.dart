import 'package:flutter/material.dart';

enum MessageType { success, error, info, warning }

void showAppMessage(
  BuildContext context,
  String message, {
  required MessageType type,
}) {
  if (!context.mounted) return;

  Color backgroundColor;
  Color textColor;
  IconData icon;
  double fontSize;

  switch (type) {
    case MessageType.success:
      backgroundColor = Colors.green.shade600;
      textColor = Colors.white;
      icon = Icons.check_circle_outline;
      fontSize = 16;
      break;
    case MessageType.error:
      backgroundColor = Colors.red.shade700;
      textColor = Colors.white;
      icon = Icons.error_outline;
      fontSize = 16;
      break;
    case MessageType.info:
      backgroundColor = Colors.blue.shade600;
      textColor = Colors.white;
      icon = Icons.info_outline;
      fontSize = 15;
      break;
    case MessageType.warning:
      backgroundColor = Colors.orange.shade600;
      textColor = Colors.white;
      icon = Icons.warning_outlined;
      fontSize = 16;
      break;
  }

  // Crear el overlay entry para mostrar en la parte superior
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 0,
      right: 0,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
            minWidth: 300,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IntrinsicWidth(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: textColor, size: 22),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          message,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (type != MessageType.info) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => overlayEntry.remove(),
                          child: Icon(Icons.close, color: textColor, size: 18),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  // Insertar el overlay
  overlay.insert(overlayEntry);

  // Remover automáticamente después del tiempo especificado
  Future.delayed(Duration(seconds: type == MessageType.info ? 3 : 5), () {
    if (overlayEntry.mounted) {
      overlayEntry.remove();
    }
  });
}
