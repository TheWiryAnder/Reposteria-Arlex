import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;

class BoletaPdfService {
  static Future<void> generarYDescargarBoleta({
    required String numeroPedido,
    required String fecha,
    required String estado,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double costoEnvio,
    required double total,
    required String metodoEntrega,
    required String metodoPago,
    String? direccionEntrega,
    String? notasCliente,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                color: PdfColors.brown300,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Repostería Arlex',
                              style: pw.TextStyle(
                                fontSize: 24,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Boleta de Compra',
                              style: const pw.TextStyle(
                                fontSize: 14,
                                color: PdfColors.white,
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              numeroPedido,
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              fecha,
                              style: const pw.TextStyle(
                                fontSize: 12,
                                color: PdfColors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Información del pedido
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 20),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildInfoItem('Estado', _formatearEstado(estado)),
                        pw.SizedBox(height: 8),
                        _buildInfoItem('Método de Entrega', _formatearMetodoEntrega(metodoEntrega)),
                        if (direccionEntrega != null && direccionEntrega.isNotEmpty) ...[
                          pw.SizedBox(height: 8),
                          _buildInfoItem('Dirección', direccionEntrega),
                        ],
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildInfoItem('Método de Pago', _formatearMetodoPago(metodoPago)),
                        if (notasCliente != null && notasCliente.isNotEmpty) ...[
                          pw.SizedBox(height: 8),
                          _buildInfoItem('Notas', notasCliente),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Tabla de productos
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Productos',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey300),
                      children: [
                        // Encabezado
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.grey200,
                          ),
                          children: [
                            _buildTableHeader('Cant.'),
                            _buildTableHeader('Producto'),
                            _buildTableHeader('Descripción'),
                            _buildTableHeader('Descuento'),
                            _buildTableHeader('P. Unit.'),
                            _buildTableHeader('Total'),
                          ],
                        ),
                        // Productos
                        ...items.map((item) {
                          final nombre = item['productoNombre'] as String? ?? '';
                          final cantidad = item['cantidad'] as int? ?? 0;
                          final precio = (item['precioUnitario'] as num?)?.toDouble() ?? 0.0;
                          final subtotalItem = (item['subtotal'] as num?)?.toDouble() ?? 0.0;
                          final descripcion = item['productoDescripcion'] as String? ?? item['descripcion'] as String? ?? '';
                          final descuento = (item['descuento'] as num?)?.toDouble() ?? 0.0;

                          return pw.TableRow(
                            children: [
                              _buildTableCell('${cantidad}x'),
                              _buildTableCell(nombre),
                              _buildTableCell(descripcion),
                              _buildTableCell(descuento > 0 ? '-${descuento.toInt()}%' : '-'),
                              _buildTableCell('S/. ${precio.toStringAsFixed(2)}'),
                              _buildTableCell('S/. ${subtotalItem.toStringAsFixed(2)}'),
                            ],
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Totales
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 20),
                child: pw.Column(
                  children: [
                    pw.Divider(),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.SizedBox(
                          width: 250,
                          child: pw.Column(
                            children: [
                              _buildTotalRow('Subtotal:', subtotal),
                              if (costoEnvio > 0) ...[
                                pw.SizedBox(height: 8),
                                _buildTotalRow('Envío a domicilio:', costoEnvio),
                              ],
                              pw.SizedBox(height: 12),
                              pw.Divider(),
                              pw.SizedBox(height: 8),
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'Total:',
                                    style: pw.TextStyle(
                                      fontSize: 18,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.Text(
                                    'S/. ${total.toStringAsFixed(2)}',
                                    style: pw.TextStyle(
                                      fontSize: 20,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.brown700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer
              pw.Padding(
                padding: const pw.EdgeInsets.all(20),
                child: pw.Column(
                  children: [
                    pw.Divider(),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      '¡Gracias por tu compra!',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Repostería Arlex - Los mejores productos artesanales',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Generar el PDF
    final Uint8List bytes = await pdf.save();

    // Descargar el PDF (para web)
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'Boleta_$numeroPedido.pdf')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  static pw.Widget _buildInfoItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: const pw.TextStyle(
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, double amount) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.Text(
          'S/. ${amount.toStringAsFixed(2)}',
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  static String _formatearEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_proceso':
        return 'En Proceso';
      case 'listo':
        return 'Listo para Recoger';
      case 'completado':
        return 'Completado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return estado;
    }
  }

  static String _formatearMetodoEntrega(String metodo) {
    return metodo == 'domicilio' ? 'Entrega a Domicilio' : 'Recoger en Tienda';
  }

  static String _formatearMetodoPago(String metodo) {
    switch (metodo) {
      case 'efectivo':
        return 'Efectivo';
      case 'transferencia':
        return 'Transferencia Bancaria';
      case 'tarjeta':
        return 'Tarjeta';
      default:
        return metodo;
    }
  }
}
