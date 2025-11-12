import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SalesCharts extends StatelessWidget {
  final String dateFilter;
  final String categoryFilter;

  const SalesCharts({
    super.key,
    required this.dateFilter,
    required this.categoryFilter,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900; // Móvil y tablets pequeñas

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Visualización de Datos',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Layout responsivo: columna en móvil, fila en desktop
        if (isMobile)
          // Móvil: mostrar gráficos uno debajo del otro
          Column(
            children: [
              _buildProductSalesChart(),
              const SizedBox(height: 16),
              _buildPromotionSalesChart(),
              const SizedBox(height: 16),
              _buildTopProductsPieChart(),
            ],
          )
        else
          // Desktop: mostrar gráficos en una fila
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildProductSalesChart()),
              const SizedBox(width: 16),
              Expanded(child: _buildPromotionSalesChart()),
              const SizedBox(width: 16),
              Expanded(child: _buildTopProductsPieChart()),
            ],
          ),
      ],
    );
  }

  Widget _buildProductSalesChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ventas Totales Diarias',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: StreamBuilder<QuerySnapshot>(
              stream: _getOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Debug logs
                print('📊 GRÁFICA PRODUCTOS - Estado conexión: ${snapshot.connectionState}');
                print('📊 GRÁFICA PRODUCTOS - Tiene datos: ${snapshot.hasData}');
                print('📊 GRÁFICA PRODUCTOS - Cantidad docs: ${snapshot.data?.docs.length ?? 0}');

                if (snapshot.hasError) {
                  print('❌ Error en gráfica productos: ${snapshot.error}');
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No hay datos disponibles'),
                  );
                }

                // Procesar datos para la gráfica - Ventas totales diarias
                final dailySales = _calculateDailySales(snapshot.data!.docs);
                print('📊 Ventas diarias calculadas: ${dailySales.length} días');

                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxY(dailySales),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${dailySales.keys.elementAt(groupIndex)}\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                                    .format(rod.toY),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= dailySales.length) {
                              return const SizedBox.shrink();
                            }
                            final dateLabel = dailySales.keys.elementAt(value.toInt());
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                dateLabel,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                          reservedSize: 40,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              NumberFormat.compact().format(value),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    barGroups: dailySales.entries
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.value,
                            color: Colors.blue,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionSalesChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ventas por Método de Pago',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: StreamBuilder<QuerySnapshot>(
              stream: _getOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No hay datos disponibles'),
                  );
                }

                // Procesar datos para la gráfica de métodos de pago
                final paymentMethodSales = _calculatePaymentMethodSales(snapshot.data!.docs);

                if (paymentMethodSales.isEmpty) {
                  return const Center(
                    child: Text('No hay datos disponibles'),
                  );
                }

                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxY(paymentMethodSales),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${paymentMethodSales.keys.elementAt(groupIndex)}\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                                    .format(rod.toY),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= paymentMethodSales.length) {
                              return const SizedBox.shrink();
                            }
                            final methodName = paymentMethodSales.keys.elementAt(value.toInt());
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                methodName,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                          reservedSize: 40,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              NumberFormat.compact().format(value),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    barGroups: paymentMethodSales.entries
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.value,
                            color: Colors.green,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsPieChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 5 Productos Más Vendidos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 350,
            child: StreamBuilder<QuerySnapshot>(
              stream: _getOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No hay datos disponibles'),
                  );
                }

                // Calcular top 5 productos
                final top5Products = _calculateTop5Products(snapshot.data!.docs);

                if (top5Products.isEmpty) {
                  return const Center(
                    child: Text('No hay datos de ventas'),
                  );
                }

                final total = top5Products.values.reduce((a, b) => a + b);

                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: PieChart(
                        PieChartData(
                          sections: top5Products.entries.map((entry) {
                            final index = top5Products.keys.toList().indexOf(entry.key);
                            final percentage = (entry.value / total * 100);

                            return PieChartSectionData(
                              value: entry.value.toDouble(),
                              title: '${percentage.toStringAsFixed(1)}%',
                              color: _getColorForIndex(index),
                              radius: 100,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: top5Products.entries.map((entry) {
                          final index = top5Products.keys.toList().indexOf(entry.key);
                          final percentage = (entry.value / total * 100);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: _getColorForIndex(index),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${entry.value} uds (${percentage.toStringAsFixed(1)}%)',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getOrdersStream() {
    final now = DateTime.now();
    DateTime startDate;

    // Calcular el rango de fechas según el filtro
    switch (dateFilter) {
      case 'last_7_days':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'last_30_days':
      case '30_days':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 'this_month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'last_month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        startDate = lastMonth;
        break;
      case 'this_year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = now.subtract(const Duration(days: 30));
    }

    var query = FirebaseFirestore.instance
        .collection('pedidos')
        .where('fechaPedido', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));

    return query.snapshots();
  }

  Map<String, double> _calculateDailySales(List<QueryDocumentSnapshot> orders) {
    final Map<String, double> dailySales = {};

    print('📊 Calculando ventas diarias totales...');
    print('📊 Total de pedidos: ${orders.length}');

    for (var order in orders) {
      final data = order.data() as Map<String, dynamic>;

      // Obtener la fecha del pedido
      final fechaPedido = data['fechaPedido'] as Timestamp?;
      if (fechaPedido == null) continue;

      final fecha = fechaPedido.toDate();
      final fechaFormateada = DateFormat('dd/MM').format(fecha);

      // Obtener el total del pedido
      final total = (data['total'] ?? 0).toDouble();

      print('📊 Fecha: $fechaFormateada, Total: \$$total');

      // Sumar al total del día
      dailySales[fechaFormateada] = (dailySales[fechaFormateada] ?? 0) + total;
    }

    print('📊 Ventas por día: $dailySales');

    // Ordenar por fecha
    final sortedEntries = dailySales.entries.toList()
      ..sort((a, b) {
        // Convertir de nuevo a fecha para ordenar correctamente
        final dateA = DateFormat('dd/MM').parse(a.key);
        final dateB = DateFormat('dd/MM').parse(b.key);
        return dateA.compareTo(dateB);
      });

    return Map.fromEntries(sortedEntries);
  }

  Map<String, double> _calculatePaymentMethodSales(List<QueryDocumentSnapshot> orders) {
    final Map<String, double> paymentSales = {};

    print('📊 Calculando ventas por método de pago...');

    for (var order in orders) {
      final data = order.data() as Map<String, dynamic>;

      // Obtener el método de pago
      final metodoPago = data['metodoPago'] as String? ?? 'No especificado';
      final total = (data['total'] ?? 0).toDouble();

      // Capitalizar primera letra
      final metodoPagoCapitalizado = metodoPago.substring(0, 1).toUpperCase() +
                                     metodoPago.substring(1);

      paymentSales[metodoPagoCapitalizado] = (paymentSales[metodoPagoCapitalizado] ?? 0) + total;
    }

    print('📊 Ventas por método de pago: $paymentSales');

    return paymentSales;
  }

  Map<String, int> _calculateTop5Products(List<QueryDocumentSnapshot> orders) {
    final Map<String, int> productQuantities = {};

    print('📊 Calculando top 5 productos...');

    for (var order in orders) {
      final data = order.data() as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>?;

      if (items != null) {
        for (var item in items) {
          // Usar los nombres de campos correctos de Firebase
          final productName = item['productoNombre'] ?? 'Sin nombre';
          final cantidad = (item['cantidad'] ?? 0) as int;

          productQuantities[productName] = (productQuantities[productName] ?? 0) + cantidad;
        }
      }
    }

    print('📊 Cantidades de productos: $productQuantities');

    // Ordenar por cantidad y tomar los top 5
    final sortedEntries = productQuantities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries.take(5));
  }

  double _getMaxY(Map<String, double> data) {
    if (data.isEmpty) return 100;
    final maxValue = data.values.reduce((a, b) => a > b ? a : b);
    // Redondear hacia arriba al múltiplo de 10 más cercano
    return (maxValue * 1.2 / 10).ceil() * 10;
  }

  Color _getColorForIndex(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    return colors[index % colors.length];
  }
}
