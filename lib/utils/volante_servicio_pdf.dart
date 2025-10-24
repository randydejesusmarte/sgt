// Crear archivo lib/utils/volante_servicio_pdf.dart
// Agregar estas dependencias en pubspec.yaml:
// pdf: ^3.10.4
// printing: ^5.11.0
// path_provider: ^2.1.1

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

    // Formato de 6x4 pulgadas (152.4 x 101.6 mm)
    final pageFormat = PdfPageFormat(
      6 * PdfPageFormat.inch,
      4 * PdfPageFormat.inch,
      marginAll: 0.25 * PdfPageFormat.inch,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado con nombre del negocio
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue700,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      nombreNegocio,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      direccionNegocio,
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      telefonoNegocio,
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),

              // Título del documento
              pw.Center(
                child: pw.Text(
                  'VOLANTE DE RECEPCIÓN',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),

              // Fecha y hora de llegada
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Fecha: ${DateFormat('dd/MM/yyyy').format(servicio.fecha)}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Hora: ${DateFormat('hh:mm a').format(servicio.fecha)}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),

              // Información del cliente
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
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
                    _buildInfoRow('Nombre:', cliente.nombre),
                    _buildInfoRow('Teléfono:', cliente.telefono),
                    if (cliente.direccion != null)
                      _buildInfoRow('Dirección:', cliente.direccion!),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),

              // Información del vehículo
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DATOS DEL VEHÍCULO',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    _buildInfoRow('Marca/Modelo:', '${vehiculo.marca} ${vehiculo.modelo}'),
                    _buildInfoRow('Año:', vehiculo.anio.toString()),
                    _buildInfoRow('Placa:', vehiculo.placa),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),

              // Servicio a realizar
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SERVICIO A REALIZAR',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      servicio.descripcion,
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    if (servicio.notas != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Notas: ${servicio.notas}',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 6),

              // Mecánico asignado
              if (empleado != null)
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        'Mecánico asignado: ',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        empleado.nombre,
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                ),
              
              pw.Spacer(),

              // Línea de firma
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: double.infinity,
                    height: 1,
                    color: PdfColors.black,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Firma del Cliente',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),

              // Nota al pie
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'NOTA: Conserve este volante para reclamar su vehículo',
                  style: const pw.TextStyle(fontSize: 7),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    // Mostrar diálogo de impresión
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Volante_Servicio_${servicio.id}.pdf',
      format: pageFormat,
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 70,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
        ],
      ),
    );
  }
}