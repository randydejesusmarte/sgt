import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:taller_autos/marca_bloc.dart';
import 'package:taller_autos/modelo_bloc.dart';
import 'package:taller_autos/pieza_bloc.dart';
import 'package:taller_autos/models.dart';

// Modelo local para la lista de la orden (sin persistencia directa, solo para impresión)
class OrdenCompraItem {
  final String marca;
  final String modelo;
  final String pieza;
  final String medidas;
  final int cantidad;

  OrdenCompraItem({
    required this.marca,
    required this.modelo,
    required this.pieza,
    required this.medidas,
    required this.cantidad,
  });
}

class OrdenCompraPage extends StatefulWidget {
  const OrdenCompraPage({super.key});

  @override
  State<OrdenCompraPage> createState() => _OrdenCompraPageState();
}

class _OrdenCompraPageState extends State<OrdenCompraPage> {
  final _formKey = GlobalKey<FormState>();

  // BLoCs
  final _marcaBloc = Modular.get<MarcaBloc>();
  final _modeloBloc = Modular.get<ModeloBloc>();
  final _piezaBloc = Modular.get<PiezaBloc>();

  // State
  Marca? _selectedMarca;
  Modelo? _selectedModelo;
  Pieza? _selectedPieza;

  // Controllers
  final _cantidadController = TextEditingController();

  final List<OrdenCompraItem> _items = [];

  @override
  void initState() {
    super.initState();
    _marcaBloc.loadMarcas();
  }

  void _onMarcaChanged(Marca? marca) {
    setState(() {
      _selectedMarca = marca;
      _selectedModelo = null;
      _selectedPieza = null;
      _modeloBloc.modelos.clear();
      _piezaBloc.piezas.clear();
    });
    if (marca != null) {
      _modeloBloc.loadModelos(marca.id!);
    }
  }

  void _onModeloChanged(Modelo? modelo) {
    setState(() {
      _selectedModelo = modelo;
      _selectedPieza = null;
      _piezaBloc.piezas.clear();
    });
    if (modelo != null) {
      _piezaBloc.loadPiezas(modelo.id!);
    }
  }

  void _addItem() {
    if (_formKey.currentState!.validate() &&
        _selectedMarca != null &&
        _selectedModelo != null &&
        _selectedPieza != null) {
      setState(() {
        _items.add(OrdenCompraItem(
          marca: _selectedMarca!.nombre,
          modelo: _selectedModelo!.nombre,
          pieza: _selectedPieza!.nombre,
          medidas: _selectedPieza!.medidas,
          cantidad: int.parse(_cantidadController.text),
        ));
      });

      // Reset only quantity and piece
      setState(() {
        _selectedPieza = null;
        _cantidadController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pieza agregada a la orden')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor complete todos los campos')),
      );
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _printPdf() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay items en la orden')),
      );
      return;
    }

    final pdf = pw.Document();
    final date = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    // Agrupar por Marca - Modelo
    final Map<String, List<OrdenCompraItem>> groupedItems = {};
    for (var item in _items) {
      final key = '${item.marca} - ${item.modelo}';
      if (!groupedItems.containsKey(key)) {
        groupedItems[key] = [];
      }
      groupedItems[key]!.add(item);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Orden de Compra',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(date, style: const pw.TextStyle(fontSize: 14)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            ...groupedItems.entries.map((entry) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: double.infinity,
                    color: PdfColors.grey200,
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(entry.key,
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.TableHelper.fromTextArray(
                    context: context,
                    headerDecoration:
                        const pw.BoxDecoration(color: PdfColors.grey100),
                    headerHeight: 25,
                    cellHeight: 30,
                    cellAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.centerLeft,
                      2: pw.Alignment.centerRight,
                    },
                    headers: ['Pieza', 'Medidas', 'Cant.'],
                    data: entry.value
                        .map((item) => [
                              item.pieza,
                              item.medidas,
                              item.cantidad.toString(),
                            ])
                        .toList(),
                  ),
                  pw.SizedBox(height: 15),
                ],
              );
            }).toList(),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Orden de Compra'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Modular.to.navigate('/compras'),
        ),
      ),
      body: Column(
        children: [
          // FORMULARIO SUPERIOR
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 3))
            ]),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      // MARCA
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _marcaBloc,
                          builder: (context, _) {
                            return DropdownButtonFormField<Marca>(
                              initialValue: _selectedMarca,
                              decoration: const InputDecoration(
                                labelText: 'Marca',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 0),
                              ),
                              items: _marcaBloc.marcas
                                  .map((m) => DropdownMenuItem(
                                        value: m,
                                        child: Text(m.nombre,
                                            overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: _onMarcaChanged,
                              validator: (v) => v == null ? 'Requerido' : null,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // MODELO
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _modeloBloc,
                          builder: (context, _) {
                            return DropdownButtonFormField<Modelo>(
                              initialValue: _selectedModelo,
                              decoration: const InputDecoration(
                                labelText: 'Modelo',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 0),
                              ),
                              items: _modeloBloc.modelos
                                  .map((m) => DropdownMenuItem(
                                        value: m,
                                        child: Text(m.nombre,
                                            overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: _selectedMarca == null
                                  ? null
                                  : _onModeloChanged,
                              validator: (v) => v == null ? 'Requerido' : null,
                              disabledHint: const Text('Elija Marca'),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // PIEZA
                      Expanded(
                        flex: 2,
                        child: AnimatedBuilder(
                          animation: _piezaBloc,
                          builder: (context, _) {
                            return DropdownButtonFormField<Pieza>(
                              initialValue: _selectedPieza,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Pieza',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 0),
                              ),
                              items: _piezaBloc.piezas
                                  .map((p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(
                                            '${p.nombre} (${p.medidas})',
                                            overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedPieza = val),
                              validator: (v) => v == null ? 'Requerido' : null,
                              disabledHint: const Text('Elija Modelo'),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // CANTIDAD
                      Expanded(
                        child: TextFormField(
                          controller: _cantidadController,
                          decoration: const InputDecoration(
                            labelText: 'Cant.',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 0),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (val) =>
                              val?.isEmpty ?? true ? 'Req' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // BOTON AGREGAR
                      ElevatedButton(
                        onPressed: _addItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        child: const Text('Agregar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // LISTA
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.assignment_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Agregue items a la orden',
                            style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (c, i) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return ListTile(
                        title: Text('${item.pieza} (x${item.cantidad})',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            '${item.marca} ${item.modelo} - Medidas: ${item.medidas}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeItem(index),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _items.isNotEmpty ? _printPdf : null,
        icon: const Icon(Icons.print),
        label: const Text('Imprimir Orden'),
        backgroundColor:
            _items.isNotEmpty ? Colors.green.shade700 : Colors.grey,
      ),
    );
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }
}
