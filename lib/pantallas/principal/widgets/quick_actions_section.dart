import 'package:flutter/material.dart';

/// Modelo para las acciones rápidas
class QuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const QuickAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

/// Widget para mostrar la sección de accesos rápidos
class QuickActionsSection extends StatelessWidget {
  final List<QuickAction> actions;

  const QuickActionsSection({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Accesos Rápidos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Layout responsivo con Wrap para múltiples filas
          LayoutBuilder(
            builder: (context, constraints) {
              // Determinar cuántas columnas según el ancho
              int crossAxisCount;
              double childAspectRatio;

              if (width < 600) {
                // Móvil: 2 columnas
                crossAxisCount = 2;
                childAspectRatio = 1.0;
              } else if (width < 900) {
                // Tablet: 3 columnas
                crossAxisCount = 3;
                childAspectRatio = 1.1;
              } else if (width < 1200) {
                // Desktop pequeño: 4 columnas
                crossAxisCount = 4;
                childAspectRatio = 1.2;
              } else {
                // Desktop grande: todas en una fila si caben, sino 4-5 columnas
                crossAxisCount = actions.length > 6 ? 5 : actions.length;
                childAspectRatio = 1.2;
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: actions.length,
                itemBuilder: (context, index) => _buildQuickActionCard(
                  context,
                  actions[index].title,
                  actions[index].icon,
                  actions[index].color,
                  actions[index].onTap,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Tamaños responsivos según el ancho disponible
        final width = MediaQuery.of(context).size.width;
        final isMobile = width < 600;

        final iconSize = isMobile ? 24.0 : 28.0;
        final fontSize = isMobile ? 11.0 : 12.0;
        final iconPadding = isMobile ? 10.0 : 12.0;
        final borderRadius = isMobile ? 12.0 : 16.0;

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(iconPadding),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: iconSize, color: color),
                ),
                SizedBox(height: isMobile ? 6 : 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
