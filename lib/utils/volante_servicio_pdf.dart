import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import 'formatters.dart';

class VolanteServicioPdf {
  static const String nombreNegocio = 'TECNICA 3';
  static const String direccionNegocio = 'AUTOPISTA JUAQUIN BALAGUER #7 SANTIAGO, FRENTE A BOMBA NELSON';
  static const String telefonoNegocio = 'Tel: 809-996-4545';

  // TODO: TAMAÑO Y FORMATO DE PÁGINA DEL VOLANTE DE SERVICIO
  // Para modificar las dimensiones del volante en el futuro, edite los valores a continuación:
  // - Formato Cuarta Hoja (por defecto): 8.5 x 2.75 pulgadas (215.9 mm x 69.85 mm)
  // - Formato Térmica 80 mm: 80 mm de ancho x 150 mm de largo
  static final pageFormatCuartaHoja = PdfPageFormat(
    8.5 * PdfPageFormat.inch,
    2.75 * PdfPageFormat.inch,
    marginAll: 8,
  );

  static final pageFormat80mm = PdfPageFormat(
    80 * PdfPageFormat.mm,
    150 * PdfPageFormat.mm,
    marginAll: 4 * PdfPageFormat.mm,
  );

  static Future<void> generarVolante({
    required Cliente cliente,
    required Vehiculo vehiculo,
    required Servicio servicio,
    Empleado? empleado,
    bool esImpresora80mm = false,
  }) async {
    final pdf = pw.Document();
    final format = esImpresora80mm ? pageFormat80mm : pageFormatCuartaHoja;

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          if (esImpresora80mm) {
            return _buildLayout80mm(cliente, vehiculo, servicio, empleado);
          }
          return _buildLayoutCuartaHoja(cliente, vehiculo, servicio, empleado);
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Volante_Servicio_${servicio.id}.pdf',
      format: format,
    );
  }

  /// Layout optimizado para Cuarta Hoja (8.5 x 2.75 pulgadas)
  static pw.Widget _buildLayoutCuartaHoja(
    Cliente cliente,
    Vehiculo vehiculo,
    Servicio servicio,
    Empleado? empleado,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Encabezado
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          decoration: const pw.BoxDecoration(color: PdfColors.blue700),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                nombreNegocio,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                'VOLANTE DE RECEPCIÓN #${servicio.id ?? ''}',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                telefonoNegocio,
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.white),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          direccionNegocio,
          style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 3),

        // Fila Principal: Cliente y Vehículo
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Cliente
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(3),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CLIENTE',
                      style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 1),
                    _buildCompactInfoRow('Nombre:', cliente.nombre),
                    _buildCompactInfoRow('Tel:', formatTelefono(cliente.telefono)),
                    if (cliente.direccion != null && cliente.direccion!.isNotEmpty)
                      _buildCompactInfoRow('Dir:', cliente.direccion!),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 4),
            // Vehículo
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(3),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'VEHÍCULO / EQUIPO',
                      style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 1),
                    _buildCompactInfoRow('Marca/Mod:', '${vehiculo.marca} ${vehiculo.modelo}'),
                    _buildCompactInfoRow('Placa/Serie:', '${vehiculo.placa} (${vehiculo.anio})'),
                  ],
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 3),

        // Servicio y Mecánico
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Servicio
            pw.Expanded(
              flex: 2,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(3),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  border: pw.Border.all(color: PdfColors.blue200, width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'SERVICIO',
                          style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                        ),
                        pw.Text(
                          'Costo: \$${servicio.costo.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 1),
                    pw.Text(
                      toTitleCase(servicio.descripcion),
                      style: const pw.TextStyle(fontSize: 6),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 4),
            // Mecánico y Fecha
            pw.Expanded(
              flex: 1,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(3),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildCompactInfoRow('Fecha:', DateFormat('dd/MM/yyyy').format(servicio.fecha)),
                    if (empleado != null)
                      _buildCompactInfoRow('Mecánico:', empleado.nombre),
                  ],
                ),
              ),
            ),
          ],
        ),
        pw.Spacer(),

        // Firma y Nota
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'NOTA: Conserve este volante para reclamar su equipo o vehículo.',
              style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
            ),
            pw.Column(
              children: [
                pw.Container(width: 100, height: 0.5, color: PdfColors.black),
                pw.SizedBox(height: 1),
                pw.Text('Firma del Cliente', style: const pw.TextStyle(fontSize: 6)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Layout optimizado para impresoras térmicas de 80 mm
  static pw.Widget _buildLayout80mm(
    Cliente cliente,
    Vehiculo vehiculo,
    Servicio servicio,
    Empleado? empleado,
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
            telefonoNegocio,
            style: const pw.TextStyle(fontSize: 6),
          ),
        ),
        pw.Divider(thickness: 0.5),
        pw.Center(
          child: pw.Text(
            'VOLANTE DE RECEPCIÓN #${servicio.id ?? ''}',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Text(
          'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(servicio.fecha)}',
          style: const pw.TextStyle(fontSize: 6),
        ),
        pw.Divider(thickness: 0.5),
        pw.Text('CLIENTE: ${cliente.nombre}', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
        pw.Text('Tel: ${formatTelefono(cliente.telefono)}', style: const pw.TextStyle(fontSize: 6)),
        if (cliente.direccion != null && cliente.direccion!.isNotEmpty)
          pw.Text('Dir: ${cliente.direccion}', style: const pw.TextStyle(fontSize: 6)),
        pw.SizedBox(height: 3),
        pw.Text('VEHÍCULO / EQUIPO:', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
        pw.Text('${vehiculo.marca} ${vehiculo.modelo} (${vehiculo.anio})', style: const pw.TextStyle(fontSize: 6)),
        pw.Text('Placa/Serie: ${vehiculo.placa}', style: const pw.TextStyle(fontSize: 6)),
        pw.SizedBox(height: 3),
        pw.Text('SERVICIO:', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
        pw.Text(toTitleCase(servicio.descripcion), style: const pw.TextStyle(fontSize: 6)),
        pw.Text('Costo: \$${servicio.costo.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
        if (empleado != null) ...[
          pw.SizedBox(height: 3),
          pw.Text('MECÁNICO: ${empleado.nombre}', style: const pw.TextStyle(fontSize: 6)),
        ],
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 15),
        pw.Center(
          child: pw.Container(width: 120, height: 0.5, color: PdfColors.black),
        ),
        pw.Center(
          child: pw.Text('Firma del Cliente', style: const pw.TextStyle(fontSize: 6)),
        ),
        pw.SizedBox(height: 5),
        pw.Center(
          child: pw.Text(
            'Conserve este ticket para retirar su equipo o vehículo',
            style: const pw.TextStyle(fontSize: 5),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildCompactInfoRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(width: 2),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 6),
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
          ),
        ),
      ],
    );
  }
}
