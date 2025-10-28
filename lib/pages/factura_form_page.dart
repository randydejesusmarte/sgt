import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'dart:async';
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
  final ClienteRepository _clienteRepo = Modular.get<ClienteRepository>();
  final ServicioRepository _servicioRepo = Modular.get<ServicioRepository>();
  final VehiculoRepository _vehiculoRepo = Modular.get<VehiculoRepository>();
  final InventarioRepository _inventarioRepo = Modular.get<InventarioRepository>();
  bool _guardando = false;

  List<Cliente> _clientes = [];
  Cliente? _clienteSeleccionado;
  Servicio? _servicioSeleccionado;
  List<Servicio> _serviciosCliente = [];
  final List<DetalleFactura> _detalles = [];
  
  final double _tasaImpuesto = 18.0;
  double _descuento = 0.0;
  String _numeroFactura = '';

  late StreamSubscription<FacturaState>? _blocSubscription;

  @override
  void initState() {
    super.initState();
    _bloc = Modular.get<FacturaBloc>();
    _setupBlocListener();
    _loadData();
  }

  void _setupBlocListener() {
    _blocSubscription = _bloc.stream.listen((state) {
      if (!mounted) return;
      
      if (state is FacturaLoaded) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Factura guardada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Modular.to.navigate('/facturas');
      } else if (state is FacturaError) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${state.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _blocSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      _clientes = await _clienteRepo.getAll();
      final facturaRepo = Modular.get<FacturaRepository>();
      _numeroFactura = await facturaRepo.getNextNumeroFactura();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cargarServiciosCliente(int clienteId) async {
    try {
      // Obtener todos los vehículos del cliente
      final vehiculos = await _vehiculoRepo.getByClienteId(clienteId);
      
      // Obtener todos los servicios de esos vehículos que estén completados
      List<Servicio> servicios = [];
      for (var vehiculo in vehiculos) {
        final serviciosVehiculo = await _servicioRepo.getByVehiculoId(vehiculo.id!);
        // Solo servicios completados
        servicios.addAll(serviciosVehiculo.where((s) => s.estado == 'completado'));
      }
      
      if (mounted) {
        setState(() {
          _serviciosCliente = servicios;
          _servicioSeleccionado = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar servicios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double get subtotal => _detalles.fold(0, (sum, d) => sum + d.total);
  double get impuesto => subtotal * (_tasaImpuesto / 100);
  double get total => subtotal + impuesto - _descuento;

  void _agregarItemInventario() async {
    final inventarioItems = await _inventarioRepo.getDisponibles();
    
    if (inventarioItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay artículos disponibles en el inventario'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    Inventario? itemSeleccionado;
    final cantidadController = TextEditingController(text: '1');
    final precioController = TextEditingController();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agregar Item del Inventario'),
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
                  final cantidad = int.tryParse(cantidadController.text) ?? 0;
                  final precio = double.tryParse(precioController.text) ?? 0;
                  
                  if (cantidad <= 0 || precio <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cantidad y precio deben ser mayores a 0'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
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
                      descripcion: '${itemSeleccionado!.nombre} (Inventario: ${itemSeleccionado!.codigo})',
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

  void _guardarFactura() async {
    if (_guardando) return;
    
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un cliente')),
      );
      return;
    }
    
    if (_servicioSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un servicio')),
      );
      return;
    }
    
    if (_detalles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un item del inventario')),
      );
      return;
    }

    setState(() => _guardando = true);
    
    try {
      // Verificar disponibilidad de inventario antes de guardar
      for (var detalle in _detalles) {
        if (detalle.descripcion.contains('Inventario:')) {
          final match = RegExp(r'Inventario:\s*([^)]+)').firstMatch(detalle.descripcion);
          if (match != null) {
            final codigo = match.group(1)?.trim();
            if (codigo != null) {
              final item = await _inventarioRepo.getByCodigo(codigo);
              if (item == null) {
                throw Exception('Item no encontrado: $codigo');
              }
              if (item.cantidadDisponible < detalle.cantidad) {
                throw Exception('Cantidad insuficiente de ${item.nombre}. Disponible: ${item.cantidadDisponible}');
              }
            }
          }
        }
      }

      // Agregar el servicio como primer detalle
      final vehiculo = await _vehiculoRepo.getById(_servicioSeleccionado!.vehiculoId);
      final detallesConServicio = [
        DetalleFactura(
          facturaId: 0,
          servicioId: _servicioSeleccionado!.id,
          descripcion: '${_servicioSeleccionado!.descripcion} - ${vehiculo?.marca ?? ''} ${vehiculo?.modelo ?? ''} (${vehiculo?.placa ?? ''})',
          cantidad: 1,
          precioUnitario: _servicioSeleccionado!.costo,
          total: _servicioSeleccionado!.costo,
        ),
        ..._detalles,
      ];

      final subtotalTotal = subtotal + _servicioSeleccionado!.costo;
      final impuestoTotal = subtotalTotal * (_tasaImpuesto / 100);
      final totalFinal = subtotalTotal + impuestoTotal - _descuento;

      // Crear la factura
      final factura = Factura(
        clienteId: _clienteSeleccionado!.id!,
        numeroFactura: _numeroFactura,
        fecha: DateTime.now(),
        subtotal: subtotalTotal,
        impuesto: impuestoTotal,
        descuento: _descuento,
        total: totalFinal,
        estado: 'pendiente',
      );

      // Actualizar inventario ANTES de guardar la factura
      for (var detalle in _detalles) {
        if (detalle.descripcion.contains('Inventario:')) {
          final match = RegExp(r'Inventario:\s*([^)]+)').firstMatch(detalle.descripcion);
          if (match != null) {
            final codigo = match.group(1)?.trim();
            if (codigo != null) {
              final item = await _inventarioRepo.getByCodigo(codigo);
              if (item != null) {
                await _inventarioRepo.ajustarCantidad(
                  item.id!,
                  detalle.cantidad,
                  'salida',
                  referencia: 'Factura: $_numeroFactura',
                  motivo: 'Venta - Servicio: ${_servicioSeleccionado!.descripcion}',
                );
              }
            }
          }
        }
      }

      // Guardar usando el BLoC (esto disparará el listener)
      _bloc.add(AddFactura(factura, detallesConServicio));
      
    } catch (e) {
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Modular.to.navigate('/facturas'),
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
                        setState(() {
                          _clienteSeleccionado = value;
                          _servicioSeleccionado = null;
                          _serviciosCliente = [];
                        });
                        if (value != null) {
                          _cargarServiciosCliente(value.id!);
                        }
                      },
                      validator: (value) =>
                          value == null ? 'Selecciona un cliente' : null,
                    ),
                    const SizedBox(height: 16),
                    if (_clienteSeleccionado != null) ...[
                      DropdownButtonFormField<Servicio>(
                        decoration: const InputDecoration(
                          labelText: 'Servicio Completado *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.build),
                        ),
                        value: _servicioSeleccionado,
                        items: _serviciosCliente.map((servicio) {
                          return DropdownMenuItem(
                            value: servicio,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(servicio.descripcion),
                                Text(
                                  '\$${servicio.costo.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _servicioSeleccionado = value);
                        },
                        validator: (value) =>
                            value == null ? 'Selecciona un servicio' : null,
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (_servicioSeleccionado != null) ...[
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Servicio Seleccionado:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(_servicioSeleccionado!.descripcion),
                              Text(
                                'Costo: \$${_servicioSeleccionado!.costo.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Items Utilizados',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _agregarItemInventario,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Agregar'),
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
                              child: Text('No hay items agregados del inventario'),
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
                                  const Text('Servicio:'),
                                  Text(
                                    '\$${_servicioSeleccionado!.costo.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Items:'),
                                  Text(
                                    '\$${subtotal.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal:'),
                                  Text(
                                    '\$${(subtotal + _servicioSeleccionado!.costo).toStringAsFixed(2)}',
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
                                    '\$${((subtotal + _servicioSeleccionado!.costo) * (_tasaImpuesto / 100)).toStringAsFixed(2)}',
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
                                    '\$${((subtotal + _servicioSeleccionado!.costo) + ((subtotal + _servicioSeleccionado!.costo) * (_tasaImpuesto / 100)) - _descuento).toStringAsFixed(2)}',
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
                  ],
                ),
              ),
            ),
            if (_servicioSeleccionado != null)
              Container(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardarFactura,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _guardando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
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