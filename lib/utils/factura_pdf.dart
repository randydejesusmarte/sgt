import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import 'formatters.dart';

class FacturaPdf {
  static const String nombreNegocio = 'TECNICA 3';
  static const String direccionNegocio = 'AUTOPISTA JUAQUIN BALAGUER #7 SANTIAGO';
  static const String direccionNegocio2 = 'FRENTE A BOMBA NELSON';
  static const String telefonoNegocio = 'Tel: 809-996-4545';
  static const String rnc = 'RNC: 123-4567890-1';

  // TODO: TAMAÑO Y FORMATO DE PÁGINA DE LA FACTURA
  // Para cambiar las dimensiones de la factura en el futuro, edite los valores a continuación:
  // - Formato Media Hoja (por defecto): 6 x 8 pulgadas (152.4 mm x 203.2 mm)
  // - Formato Térmica 80 mm: 80 mm de ancho x 220 mm de largo
  static final pageFormatMediaHoja = PdfPageFormat(
    6 * PdfPageFormat.inch,
    8 * PdfPageFormat.inch,
    marginAll: 15,
  );

  static final pageFormat80mm = PdfPageFormat(
    80 * PdfPageFormat.mm,
    220 * PdfPageFormat.mm,
    marginAll: 4 * PdfPageFormat.mm,
  );

  static Future<void> generarFactura({
    required Factura factura,
    required Cliente cliente,
    required List<DetalleFactura> detalles,
    Servicio? servicio,
    Vehiculo? vehiculo,
    bool esImpresora80mm = false,
  }) async {
    final pdf = pw.Document();
    final format = esImpresora80mm ? pageFormat80mm : pageFormatMediaHoja;

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          if (esImpresora80mm) {
            return _buildLayout80mm(factura, cliente, detalles, servicio, vehiculo);
          }
          return _buildLayoutMediaHoja(factura, cliente, detalles, servicio, vehiculo);
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Factura_${factura.numeroFactura}.pdf',
      format: format,
    );
  }

  /// Layout para Media Hoja (6x8 pulgadas)
  static pw.Widget _buildLayoutMediaHoja(
    Factura factura,
    Cliente cliente,
    List<DetalleFactura> detalles,
    Servicio? servicio,
    Vehiculo? vehiculo,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildHeader(factura),
        pw.SizedBox(height: 8),
        _buildClienteInfo(cliente),
        pw.SizedBox(height: 8),
        if (servicio != null && vehiculo != null) ...[
          _buildServicioInfo(servicio, vehiculo),
          pw.SizedBox(height: 8),
        ],
        _buildDetallesTable(detalles),
        pw.SizedBox(height: 8),
        _buildTotales(factura),
        pw.Spacer(),
        _buildFooter(),
      ],
    );
  }

  /// Layout optimizado para impresoras térmicas de 80 mm
  static pw.Widget _buildLayout80mm(
    Factura factura,
    Cliente cliente,
    List<DetalleFactura> detalles,
    Servicio? servicio,
    Vehiculo? vehiculo,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Text(
            nombreNegocio,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Center(
          child: pw.Text(
            direccionNegocio,
            style: const pw.TextStyle(fontSize: 6),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Center(
          child: pw.Text(
            '$telefonoNegocio - $rnc',
            style: const pw.TextStyle(fontSize: 6),
          ),
        ),
        pw.Divider(thickness: 0.5),
        pw.Center(
          child: pw.Text(
            'FACTURA #${factura.numeroFactura}',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Text(
          'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(factura.fecha)}',
          style: const pw.TextStyle(fontSize: 6),
        ),
        pw.Text(
          'Pago: ${factura.tipoPago == 'credito' ? 'A CRÉDITO' : 'AL CONTADO'}',
          style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
        ),
        if (factura.conComprobante)
          pw.Text(
            'NCF: ${factura.ncf ?? 'CON COMPROBANTE'}',
            style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
          )
        else
          pw.Text(
            'Comprobante: SIN COMPROBANTE FISCAL',
            style: const pw.TextStyle(fontSize: 6),
          ),
        pw.Divider(thickness: 0.5),
        pw.Text('CLIENTE: ${cliente.nombre}', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
        pw.Text('Tel: ${formatTelefono(cliente.telefono)}', style: const pw.TextStyle(fontSize: 6)),
        if (vehiculo != null)
          pw.Text('Vehículo/Equipo: ${vehiculo.marca} ${vehiculo.modelo} (${vehiculo.placa})', style: const pw.TextStyle(fontSize: 6)),
        pw.Divider(thickness: 0.5),
        pw.Text('DETALLES:', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 2),
        ...detalles.map((d) {
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 1),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Text('${d.cantidad}x ${d.descripcion}', style: const pw.TextStyle(fontSize: 6)),
                ),
                pw.Text('\$${d.total.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 6)),
              ],
            ),
          );
        }),
        pw.Divider(thickness: 0.5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 6)),
            pw.Text('\$${factura.subtotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 6)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('ITBIS (18%):', style: const pw.TextStyle(fontSize: 6)),
            pw.Text('\$${factura.impuesto.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 6)),
          ],
        ),
        if (factura.descuento > 0)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Descuento:', style: const pw.TextStyle(fontSize: 6)),
              pw.Text('-\$${factura.descuento.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 6)),
            ],
          ),
        pw.SizedBox(height: 2),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('TOTAL:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
            pw.Text('\$${factura.total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text('¡Gracias por su preferencia!', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
        ),
      ],
    );
  }

  static pw.Widget _buildHeader(Factura factura) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 1.5),
        borderRadius: pw.BorderRadius.circular(4),
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
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(direccionNegocio, style: const pw.TextStyle(fontSize: 8)),
              pw.Text(direccionNegocio2, style: const pw.TextStyle(fontSize: 8)),
              pw.Text(telefonoNegocio, style: const pw.TextStyle(fontSize: 8)),
              pw.Text(rnc, style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue900,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'FACTURA',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'No. ${factura.numeroFactura}',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Fecha: ${DateFormat('dd/MM/yyyy').format(factura.fecha)}',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Pago: ${factura.tipoPago == 'credito' ? 'A CRÉDITO' : 'AL CONTADO'}',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              ),
              if (factura.conComprobante) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  factura.ncf != null && factura.ncf!.isNotEmpty
                      ? 'NCF: ${factura.ncf}'
                      : 'CON COMPROBANTE FISCAL',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
              ] else ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'COMPROBANTE: SIN COMPROBANTE',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildClienteInfo(Cliente cliente) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DATOS DEL CLIENTE',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Cliente: ${cliente.nombre}', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Tel: ${formatTelefono(cliente.telefono)}', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
          if (cliente.direccion != null && cliente.direccion!.isNotEmpty)
            pw.Text('Dirección: ${cliente.direccion}', style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  static pw.Widget _buildServicioInfo(Servicio servicio, Vehiculo vehiculo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SERVICIO REALIZADO',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Servicio: ${toTitleCase(servicio.descripcion)}', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(
                      'Vehículo/Equipo: ${vehiculo.marca} ${vehiculo.modelo} (${vehiculo.anio}) - Placa/Serie: ${vehiculo.placa}',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  '\$${servicio.costo.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 10,
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
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('DESCRIPCIÓN', isHeader: true),
            _buildTableCell('CANT.', isHeader: true, align: pw.TextAlign.center),
            _buildTableCell('PRECIO UNIT.', isHeader: true, align: pw.TextAlign.right),
            _buildTableCell('TOTAL', isHeader: true, align: pw.TextAlign.right),
          ],
        ),
        ...detalles.map((detalle) {
          return pw.TableRow(
            children: [
              _buildTableCell(detalle.descripcion),
              _buildTableCell(detalle.cantidad.toString(), align: pw.TextAlign.center),
              _buildTableCell(detalle.precioUnitario.toStringAsFixed(2), align: pw.TextAlign.right),
              _buildTableCell(detalle.total.toStringAsFixed(2), align: pw.TextAlign.right),
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
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 8 : 8,
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
          width: 180,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 1),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildTotalRow('Subtotal:', '\$${factura.subtotal.toStringAsFixed(2)}'),
              pw.SizedBox(height: 2),
              _buildTotalRow('ITBIS (18%):', '\$${factura.impuesto.toStringAsFixed(2)}'),
              if (factura.descuento > 0) ...[
                pw.SizedBox(height: 2),
                _buildTotalRow('Descuento:', '-\$${factura.descuento.toStringAsFixed(2)}'),
              ],
              pw.Divider(thickness: 1, height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL A PAGAR:',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue900,
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                    child: pw.Text(
                      '\$${factura.total.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 11,
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
        pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 140,
                  height: 0.5,
                  color: PdfColors.black,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Firma Autorizada',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 140,
                  height: 0.5,
                  color: PdfColors.black,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Firma del Cliente',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'GRACIAS POR SU PREFERENCIA',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Esta factura es válida como comprobante de pago',
                style: const pw.TextStyle(fontSize: 7),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}