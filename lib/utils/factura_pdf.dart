// Crear archivo lib/utils/factura_pdf.dart

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models.dart';

class FacturaPdf {
  static const String nombreNegocio = 'TECNICA 3';
  static const String direccionNegocio = 'AUTOPISTA JUAQUIN BALAGUER #7 SANTIAGO';
  static const String direccionNegocio2 = 'FRENTE A BOMBA NELSON';
  static const String telefonoNegocio = 'Tel: (809) 996-4545';
  static const String rnc = 'RNC: 123-4567890-1';

  static Future<void> generarFactura({
    required Factura factura,
    required Cliente cliente,
    required List<DetalleFactura> detalles,
    Servicio? servicio,
    Vehiculo? vehiculo,
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
              _buildHeader(factura),
              pw.SizedBox(height: 20),

              // Información del cliente
              _buildClienteInfo(cliente),
              pw.SizedBox(height: 20),

              // Información del servicio
              if (servicio != null && vehiculo != null) ...[
                _buildServicioInfo(servicio, vehiculo),
                pw.SizedBox(height: 20),
              ],

              // Tabla de detalles
              _buildDetallesTable(detalles),
              pw.SizedBox(height: 20),

              // Totales
              _buildTotales(factura),
              
              pw.Spacer(),

              // Pie de página
              _buildFooter(),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Factura_${factura.numeroFactura}.pdf',
    );
  }

  static pw.Widget _buildHeader(Factura factura) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 2),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                nombreNegocio,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(direccionNegocio, style: const pw.TextStyle(fontSize: 10)),
              pw.Text(direccionNegocio2, style: const pw.TextStyle(fontSize: 10)),
              pw.Text(telefonoNegocio, style: const pw.TextStyle(fontSize: 10)),
              pw.Text(rnc, style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue900,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Text(
                  'FACTURA',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'No. ${factura.numeroFactura}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Fecha: ${DateFormat('dd/MM/yyyy').format(factura.fecha)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildClienteInfo(Cliente cliente) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DATOS DEL CLIENTE',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Cliente: ${cliente.nombre}', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('Teléfono: ${cliente.telefono}', style: const pw.TextStyle(fontSize: 10)),
          if (cliente.direccion != null)
            pw.Text('Dirección: ${cliente.direccion}', style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _buildServicioInfo(Servicio servicio, Vehiculo vehiculo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SERVICIO REALIZADO',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Descripción:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(servicio.descripcion, style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Vehículo: ${vehiculo.marca} ${vehiculo.modelo}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text('Placa: ${vehiculo.placa}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Año: ${vehiculo.anio}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Text(
                  '${servicio.costo.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDetallesTable(List<DetalleFactura> detalles) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Encabezado
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('DESCRIPCIÓN', isHeader: true),
            _buildTableCell('CANT.', isHeader: true, align: pw.TextAlign.center),
            _buildTableCell('PRECIO UNIT.', isHeader: true, align: pw.TextAlign.right),
            _buildTableCell('TOTAL', isHeader: true, align: pw.TextAlign.right),
          ],
        ),
        // Detalles
        ...detalles.map((detalle) {
          return pw.TableRow(
            children: [
              _buildTableCell(detalle.descripcion),
              _buildTableCell(detalle.cantidad.toString(), align: pw.TextAlign.center),
              _buildTableCell('${detalle.precioUnitario.toStringAsFixed(2)}', align: pw.TextAlign.right),
              _buildTableCell('${detalle.total.toStringAsFixed(2)}', align: pw.TextAlign.right),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildTotales(Factura factura) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 250,
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 2),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildTotalRow('Subtotal:', '${factura.subtotal.toStringAsFixed(2)}'),
              pw.SizedBox(height: 5),
              _buildTotalRow('ITBIS (18%):', '${factura.impuesto.toStringAsFixed(2)}'),
              if (factura.descuento > 0) ...[
                pw.SizedBox(height: 5),
                _buildTotalRow('Descuento:', '-${factura.descuento.toStringAsFixed(2)}'),
              ],
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL A PAGAR:',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue900,
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Text(
                      '${factura.total.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTotalRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 200,
                  height: 1,
                  color: PdfColors.black,
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Firma Autorizada',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 200,
                  height: 1,
                  color: PdfColors.black,
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Firma del Cliente',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 15),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'GRACIAS POR SU PREFERENCIA',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Esta factura es válida como comprobante de pago',
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}