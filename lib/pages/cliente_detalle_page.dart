import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../repositories.dart';
import '../vehiculo_bloc.dart';
import '../factura_bloc.dart';

class ClienteDetallePage extends StatefulWidget {
  final int clienteId;

  const ClienteDetallePage({super.key, required this.clienteId});

  @override
  State<ClienteDetallePage> createState() => _ClienteDetallePageState();
}

class _ClienteDetallePageState extends State<ClienteDetallePage> {
  final ClienteRepository _clienteRepo = Modular.get<ClienteRepository>();
  final VehiculoBloc _vehiculoBloc = Modular.get<VehiculoBloc>();
  final FacturaBloc _facturaBloc = Modular.get<FacturaBloc>();

  Cliente? _cliente;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _cliente = await _clienteRepo.getById(widget.clienteId);
    _vehiculoBloc.add(LoadVehiculosByCliente(widget.clienteId));
    _facturaBloc.add(LoadFacturasByCliente(widget.clienteId));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _cliente == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Modular.to.navigate('/clientes'),
        ),
          title: Text(_cliente!.nombre),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.directions_car), text: 'Vehículos'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Facturas'),
            ],
          ),
        ),
        body: Column(
          children: [
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue.shade700,
                          child: Text(
                            _cliente!.nombre[0].toUpperCase(),
                            style: const TextStyle(fontSize: 30, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _cliente!.nombre,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.phone, size: 16),
                                  const SizedBox(width: 4),
                                  Text(_cliente!.telefono),
                                ],
                              ),
                              if (_cliente!.email != null)
                                Row(
                                  children: [
                                    const Icon(Icons.email, size: 16),
                                    const SizedBox(width: 4),
                                    Text(_cliente!.email!),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_cliente!.direccion != null) ...[
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 4),
                          Expanded(child: Text(_cliente!.direccion!)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildVehiculosTab(),
                  _buildFacturasTab(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddVehiculoDialog(),
          backgroundColor: Colors.blue.shade700,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildVehiculosTab() {
    return BlocBuilder<VehiculoBloc, VehiculoState>(
      bloc: _vehiculoBloc,
      builder: (context, state) {
        if (state is VehiculoLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is VehiculoLoaded) {
          if (state.vehiculos.isEmpty) {
            return const Center(child: Text('No hay vehículos registrados'));
          }

          return ListView.builder(
            itemCount: state.vehiculos.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final vehiculo = state.vehiculos[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.directions_car, size: 40),
                  title: Text('${vehiculo.marca} ${vehiculo.modelo}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Año: ${vehiculo.anio}'),
                      Text('Placa: ${vehiculo.placa}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _vehiculoBloc.add(DeleteVehiculo(vehiculo.id!));
                      _vehiculoBloc.add(LoadVehiculosByCliente(widget.clienteId));
                    },
                  ),
                ),
              );
            },
          );
        }

        return const Center(child: Text('Error cargando vehículos'));
      },
    );
  }

  Widget _buildFacturasTab() {
    return BlocBuilder<FacturaBloc, FacturaState>(
      bloc: _facturaBloc,
      builder: (context, state) {
        if (state is FacturaLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FacturaLoaded) {
          if (state.facturas.isEmpty) {
            return const Center(child: Text('No hay facturas registradas'));
          }

          final totalFacturado = state.facturas
              .where((f) => f.estado == 'pagada')
              .fold<double>(0, (sum, f) => sum + f.total);
          
          final totalPendiente = state.facturas
              .where((f) => f.estado == 'pendiente')
              .fold<double>(0, (sum, f) => sum + f.total);

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.green.shade50,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Pagado:', style: TextStyle(fontSize: 14)),
                              Text(
                                '\$${totalFacturado.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Pendiente:', style: TextStyle(fontSize: 14)),
                              Text(
                                '\$${totalPendiente.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: state.facturas.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final factura = state.facturas[index];
                    Color estadoColor = factura.estado == 'pagada'
                        ? Colors.green
                        : factura.estado == 'pendiente'
                            ? Colors.orange
                            : Colors.red;

                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.receipt, color: estadoColor, size: 40),
                        title: Text(factura.numeroFactura),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('dd/MM/yyyy').format(factura.fecha)),
                            Chip(
                              label: Text(
                                factura.estado.toUpperCase(),
                                style: const TextStyle(fontSize: 10, color: Colors.white),
                              ),
                              backgroundColor: estadoColor,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                        trailing: Text(
                          '\$${factura.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }

        return const Center(child: Text('Error cargando facturas'));
      },
    );
  }

  void _showAddVehiculoDialog() {
    final marcaController = TextEditingController();
    final modeloController = TextEditingController();
    final anioController = TextEditingController();
    final placaController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Vehículo'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: marcaController,
                  decoration: const InputDecoration(
                    labelText: 'Marca *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: modeloController,
                  decoration: const InputDecoration(
                    labelText: 'Modelo *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: anioController,
                  decoration: const InputDecoration(
                    labelText: 'Año *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: placaController,
                  decoration: const InputDecoration(
                    labelText: 'Placa *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final vehiculo = Vehiculo(
                  clienteId: widget.clienteId,
                  marca: marcaController.text,
                  modelo: modeloController.text,
                  anio: int.parse(anioController.text),
                  placa: placaController.text,
                );
                _vehiculoBloc.add(AddVehiculo(vehiculo));
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}