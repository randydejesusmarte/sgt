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
  late final FacturaBloc _bloc;
  final FacturaRepository _facturaRepo = Modular.get<FacturaRepository>();
  final ClienteRepository _clienteRepo = Modular.get<ClienteRepository>();
  final InventarioRepository _inventarioRepo = Modular.get<InventarioRepository>();
  bool _guardando = false;

  List<Cliente> _clientes = [];
  Cliente? _clienteSeleccionado;
  final List<DetalleFactura> _detalles = [];
  
  final double _tasaImpuesto = 18.0; // ITBIS 18%
  double _descuento = 0.0;
  String _numeroFactura = '';

  @override
  void initState() {
    super.initState();
    _bloc = Modular.get<FacturaBloc>();
    _bloc.stream.listen((state) {
      if (state is FacturaError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (state is FacturaLoaded) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Factura guardada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    });
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

  void _agregarDetalleDesdeInventario() async {
    final inventarioItems = await _inventarioRepo.getDisponibles();
    
    if (inventarioItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay artículos disponibles en el inventario'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Inventario? itemSeleccionado;
    final cantidadController = TextEditingController(text: '1');
    final precioController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Seleccionar del Inventario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Inventario>(
                  decoration: const InputDecoration(
                    labelText: 'Artículo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory_2),
                  ),
                  items: inventarioItems.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item.nombre),
                          Text(
                            'Disponible: ${item.cantidadDisponible} | \$${item.precioVenta.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      itemSeleccionado = value;
                      if (value != null) {
                        precioController.text = value.precioVenta.toStringAsFixed(2);
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cantidadController,
                  decoration: InputDecoration(
                    labelText: 'Cantidad',
                    border: const OutlineInputBorder(),
                    suffixText: itemSeleccionado != null
                        ? 'Disp: ${itemSeleccionado!.cantidadDisponible}'
                        : null,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if (itemSeleccionado != null && value.isNotEmpty) {
                      final cantidad = int.tryParse(value) ?? 0;
                      if (cantidad > itemSeleccionado!.cantidadDisponible) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cantidad mayor a la disponible'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    }
                  },
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
                if (itemSeleccionado != null &&
                    cantidadController.text.isNotEmpty &&
                    precioController.text.isNotEmpty) {
                  final cantidad = int.parse(cantidadController.text);
                  final precio = double.parse(precioController.text);
                  
                  if (cantidad > itemSeleccionado!.cantidadDisponible) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cantidad insuficiente en inventario'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  setState(() {
                    _detalles.add(DetalleFactura(
                      facturaId: 0,
                      descripcion: '${itemSeleccionado!.nombre} (${itemSeleccionado!.codigo})',
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
      ),
    );
  }

  void _agregarDetalleManual() {
    final descripcionController = TextEditingController();
    final cantidadController = TextEditingController(text: '1');
    final precioController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Item Manual'),
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

  void _guardarFactura() async {
    if (_formKey.currentState!.validate() && 
        _clienteSeleccionado != null && 
        _detalles.isNotEmpty) {
      if (_guardando) return; // Evitar doble guardado
      setState(() => _guardando = true);
      
      try {
        // Verificar disponibilidad de inventario
        for (var detalle in _detalles) {
          final match = RegExp(r'\(([^)]+)\)').firstMatch(detalle.descripcion);
          if (match != null) {
            final codigo = match.group(1);
            final item = await _inventarioRepo.getByCodigo(codigo!);
            if (item != null && item.cantidadDisponible < detalle.cantidad) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cantidad insuficiente de ${item.nombre}'),
                  backgroundColor: Colors.red,
                ),
              );
              setState(() => _guardando = false);
              return;
            }
          }
        }

        // Crear la factura primero
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

        // Actualizar inventario antes de guardar la factura
        for (var detalle in _detalles) {
          final match = RegExp(r'\(([^)]+)\)').firstMatch(detalle.descripcion);
          if (match != null) {
            final codigo = match.group(1);
            final item = await _inventarioRepo.getByCodigo(codigo!);
            if (item != null) {
              await _inventarioRepo.ajustarCantidad(
                item.id!,
                detalle.cantidad,
                'salida',
                referencia: 'Factura: $_numeroFactura',
                motivo: 'Venta',
              );
            }
          }
        }

        // Usar el BLoC para guardar la factura y sus detalles
        _bloc.add(AddFactura(factura, _detalles));
        
      } catch (e) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la factura: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                        Wrap(
                          spacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _agregarDetalleDesdeInventario,
                              icon: const Icon(Icons.inventory_2, size: 18),
                              label: const Text('Inventario'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _agregarDetalleManual,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Manual'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple.shade500,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
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
                          margin: const EdgeInsets.only(bottom: 8),
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