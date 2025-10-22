import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../models.dart';
import '../factura_bloc.dart';
import '../repositories.dart';

class FacturaFormPage extends StatefulWidget {
  const FacturaFormPage({super.key});

  @override
  State<FacturaFormPage> createState() => _FacturaFormPageState();
}

class _FacturaFormPageState extends State<FacturaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final FacturaBloc _bloc = Modular.get<FacturaBloc>();
  final FacturaRepository _facturaRepo = Modular.get<FacturaRepository>();
  final ClienteRepository _clienteRepo = Modular.get<ClienteRepository>();

  List<Cliente> _clientes = [];
  Cliente? _clienteSeleccionado;
  final List<DetalleFactura> _detalles = [];
  
  final double _tasaImpuesto = 18.0; // ITBIS 18%
  double _descuento = 0.0;
  String _numeroFactura = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _clientes = await _clienteRepo.getAll();
    _numeroFactura = await _facturaRepo.getNextNumeroFactura();
    setState(() {});
  }

  double get subtotal => _detalles.fold(0, (sum, d) => sum + d.total);
  double get impuesto => subtotal * (_tasaImpuesto / 100);
  double get total => subtotal + impuesto - _descuento;

  void _agregarDetalle() {
    final descripcionController = TextEditingController();
    final cantidadController = TextEditingController(text: '1');
    final precioController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cantidadController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: precioController,
                decoration: const InputDecoration(
                  labelText: 'Precio unitario',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (descripcionController.text.isNotEmpty &&
                  cantidadController.text.isNotEmpty &&
                  precioController.text.isNotEmpty) {
                final cantidad = int.parse(cantidadController.text);
                final precio = double.parse(precioController.text);
                setState(() {
                  _detalles.add(DetalleFactura(
                    facturaId: 0,
                    descripcion: descripcionController.text,
                    cantidad: cantidad,
                    precioUnitario: precio,
                    total: cantidad * precio,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _guardarFactura() {
    if (_formKey.currentState!.validate() && _clienteSeleccionado != null && _detalles.isNotEmpty) {
      final factura = Factura(
        clienteId: _clienteSeleccionado!.id!,
        numeroFactura: _numeroFactura,
        fecha: DateTime.now(),
        subtotal: subtotal,
        impuesto: impuesto,
        descuento: _descuento,
        total: total,
        estado: 'pendiente',
      );

      _bloc.add(AddFactura(factura, _detalles));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Factura creada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      Modular.to.navigate('/facturas');
    } else if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un cliente')),
      );
    } else if (_detalles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un item')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Modular.to.navigate('/'),
        ),
        title: const Text('Nueva Factura'),
        backgroundColor: Colors.purple.shade700,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Factura: $_numeroFactura',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Cliente>(
                      initialValue: _clienteSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Cliente *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: _clientes.map((cliente) {
                        return DropdownMenuItem(
                          value: cliente,
                          child: Text(cliente.nombre),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _clienteSeleccionado = value);
                      },
                      validator: (value) =>
                          value == null ? 'Selecciona un cliente' : null,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _agregarDetalle,
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar Item'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_detalles.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text('No hay items agregados'),
                          ),
                        ),
                      )
                    else
                      ..._detalles.asMap().entries.map((entry) {
                        final index = entry.key;
                        final detalle = entry.value;
                        return Card(
                          child: ListTile(
                            title: Text(detalle.descripcion),
                            subtitle: Text(
                              'Cant: ${detalle.cantidad} × \$${detalle.precioUnitario.toStringAsFixed(2)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '\$${detalle.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() => _detalles.removeAt(index));
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 24),
                    Card(
                      color: Colors.purple.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal:'),
                                Text(
                                  '\$${subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Impuesto ($_tasaImpuesto%):'),
                                Text(
                                  '\$${impuesto.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Descuento:'),
                                SizedBox(
                                  width: 100,
                                  child: TextField(
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      prefixText: '\$',
                                      isDense: true,
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _descuento = double.tryParse(value) ?? 0;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'TOTAL:',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '\$${total.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _guardarFactura,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Guardar Factura',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}