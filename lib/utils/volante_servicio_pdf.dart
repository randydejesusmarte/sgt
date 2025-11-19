import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models.dart';

class VolanteServicioPdf {
  static const String nombreNegocio = 'TECNICA 3';
  static const String direccionNegocio = 'AUTOPISTA JUAQUIN BALAGUER #7 SANTIAGO, FRENTE A BOMBA NELSON';
  static const String telefonoNegocio = 'Tel: (809) 996-4545';

  static Future<void> generarVolante({
    required Cliente cliente,
    required Vehiculo vehiculo,
    required Servicio servicio,
    Empleado? empleado,
  }) async {
    final pdf = pw.Document();

    //final pageFormat = PdfPageFormat(
    //  4 * PdfPageFormat.inch,
    //  2 * PdfPageFormat.inch,
    //  marginAll: 0.10 * PdfPageFormat.inch,
    //);
     final pageFormat = PdfPageFormat(
      80 * PdfPageFormat.mm,
      60 * PdfPageFormat.mm,
      marginAll: 0.10 * PdfPageFormat.mm,
     );

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue700,
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      nombreNegocio,
                      style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 1),
                    pw.Text(
                      direccionNegocio,
                      style: const pw.TextStyle(
                        fontSize: 4,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                      maxLines: 2,
                    ),
                    pw.Text(
                      telefonoNegocio,
                      style: const pw.TextStyle(
                        fontSize: 4,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Center(
                child: pw.Text(
                  'VOLANTE DE RECEPCIÓN',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Container(
                padding: const pw.EdgeInsets.all(2),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'ID: ${servicio.id ?? 'N/A'}',
                      style: const pw.TextStyle(fontSize: 5),
                    ),
                    pw.Text(
                      'Fecha: ${DateFormat('dd/MM/yyyy').format(servicio.fecha)}',
                      style: const pw.TextStyle(fontSize: 5),
                    ),
                    pw.Text(
                      'Estado: ${servicio.estado}',
                      style: const pw.TextStyle(fontSize: 5),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(3),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'CLIENTE',
                            style: pw.TextStyle(
                              fontSize: 6,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 1),
                          _buildCompactInfoRow('Nombre:', cliente.nombre),
                          _buildCompactInfoRow('Tel:', cliente.telefono),
                          if (cliente.email != null)
                            _buildCompactInfoRow('Email:', cliente.email!),
                          if (cliente.direccion != null)
                            _buildCompactInfoRow('Dir:', cliente.direccion!),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 2),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(3),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'VEHÍCULO',
                            style: pw.TextStyle(
                              fontSize: 6,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 1),
                          _buildCompactInfoRow('Marca:', vehiculo.marca),
                          _buildCompactInfoRow('Modelo:', vehiculo.modelo),
                          _buildCompactInfoRow('Año:', vehiculo.anio.toString()),
                          _buildCompactInfoRow('Placa:', vehiculo.placa),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Container(
                padding: const pw.EdgeInsets.all(3),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SERVICIO',
                      style: pw.TextStyle(
                        fontSize: 6,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 1),
                    pw.Text(
                      servicio.descripcion,
                      style: const pw.TextStyle(fontSize: 5),
                      maxLines: 3,
                      overflow: pw.TextOverflow.clip,
                    ),
                    pw.SizedBox(height: 1),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Costo: \$${servicio.costo.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold),
                        ),
                        if (servicio.notas != null)
                          pw.Expanded(
                            child: pw.Text(
                              'Notas: ${servicio.notas}',
                              style: const pw.TextStyle(fontSize: 5),
                              maxLines: 1,
                              overflow: pw.TextOverflow.clip,
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                children: [
                  if (empleado != null)
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(3),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue50,
                          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'MECÁNICO',
                              style: pw.TextStyle(
                                fontSize: 6,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 1),
                            _buildCompactInfoRow('Nombre:', empleado.nombre),
                            _buildCompactInfoRow('Tel:', empleado.telefono),
                            if (empleado.especialidad != null)
                              _buildCompactInfoRow('Esp:', empleado.especialidad!),
                          ],
                        ),
                      ),
                    ),
                  if (empleado != null)
                    pw.SizedBox(width: 2),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(2),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                        children: [
                          pw.Container(
                            width: double.infinity,
                            height: 0.5,
                            color: PdfColors.black,
                          ),
                          pw.SizedBox(height: 1),
                          pw.Text(
                            'Firma del Cliente',
                            style: const pw.TextStyle(fontSize: 5),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(2),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                  color: PdfColors.yellow50,
                ),
                child: pw.Text(
                  'NOTA: Conserve este volante para reclamar su vehículo',
                  style: const pw.TextStyle(fontSize: 5),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Volante_Servicio_${servicio.id}.pdf',
      format: pageFormat,
    );
  }

  static pw.Widget _buildCompactInfoRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(width: 1),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 5),
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
          ),
        ),
      ],
    );
  }
}
