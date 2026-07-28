import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../repositories.dart';
import '../vehiculo_bloc.dart';
import '../factura_bloc.dart';
import '../servicio_bloc.dart';
import '../utils/formatters.dart';
import '../utils/volante_servicio_pdf.dart';

class ClienteDetallePage extends StatefulWidget {
  final int clienteId;

  const ClienteDetallePage({super.key, required this.clienteId});

  @override
  State<ClienteDetallePage> createState() => _ClienteDetallePageState();
}

class _ClienteDetallePageState extends State<ClienteDetallePage> {
  final ClienteRepository _clienteRepo = inject<ClienteRepository>();
  final VehiculoBloc _vehiculoBloc = inject<VehiculoBloc>();
  final FacturaBloc _facturaBloc = inject<FacturaBloc>();
  final ServicioBloc _servicioBloc = inject<ServicioBloc>();

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
    _servicioBloc.add(LoadServiciosByCliente(widget.clienteId));
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
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.navigate('/clientes'),
          ),
          title: Text(_cliente!.nombre),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.work_history), text: 'Historial de Trabajos'),
              Tab(icon: Icon(Icons.build_circle), text: 'Vehículos / Equipos'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Facturas'),
            ],
          ),
        ),
        body: Column(
          children: [
            Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.blue.shade700,
                          child: Text(
                            _cliente!.nombre[0].toUpperCase(),
                            style: const TextStyle(fontSize: 24, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _cliente!.nombre,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  _buildClasificacionBadge(_cliente!.clasificacion),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.phone, size: 14),
                                  const SizedBox(width: 4),
                                  Text(formatTelefono(_cliente!.telefono), style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                              if (_cliente!.email != null && _cliente!.email!.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.email, size: 14),
                                    const SizedBox(width: 4),
                                    Text(_cliente!.email!, style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_cliente!.direccion != null && _cliente!.direccion!.isNotEmpty) ...[
                      const Divider(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14),
                          const SizedBox(width: 4),
                          Expanded(child: Text(_cliente!.direccion!, style: const TextStyle(fontSize: 13))),
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
                  _buildHistorialTrabajosTab(),
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

  Widget _buildHistorialTrabajosTab() {
    return BlocBuilder<ServicioBloc, ServicioState>(
      bloc: _servicioBloc,
      builder: (context, state) {
        if (state is ServicioLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ServiciosLoaded) {
          if (state.servicios.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_off_outlined, size: 54, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Este cliente no tiene trabajos o servicios registrados aún',
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          final totalInvertido = state.servicios.fold<double>(0, (sum, s) => sum + s.costo);
          final ultimoServicio = state.servicios.first;

          return Column(
            children: [
              // Tarjetas de Resumen del Historial
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryMetric(
                        title: 'Trabajos Traídos',
                        value: '${state.servicios.length}',
                        icon: Icons.assignment_turned_in,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildSummaryMetric(
                        title: 'Última Entrada',
                        value: DateFormat('dd/MM/yyyy').format(ultimoServicio.fecha),
                        icon: Icons.calendar_today,
                        color: Colors.indigo.shade800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildSummaryMetric(
                        title: 'Total Trabajos',
                        value: '\$${totalInvertido.toStringAsFixed(2)}',
                        icon: Icons.attach_money,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: state.servicios.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final servicio = state.servicios[index];
                    final vehiculo = state.vehiculos[servicio.vehiculoId];
                    final empleado = servicio.empleadoId != null ? state.empleados[servicio.empleadoId] : null;

                    Color estadoColor = servicio.estado == 'entregado' || servicio.estado == 'completado'
                        ? Colors.green
                        : servicio.estado == 'en_proceso'
                            ? Colors.blue
                            : servicio.estado == 'pendiente'
                                ? Colors.orange
                                : Colors.red;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '#${servicio.id}',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900, fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat('dd/MM/yyyy hh:mm a').format(servicio.fecha),
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: estadoColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: estadoColor),
                                  ),
                                  child: Text(
                                    servicio.estado.toUpperCase().replaceAll('_', ' '),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: estadoColor),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 14),
                            Text(
                              toTitleCase(servicio.descripcion),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            if (vehiculo != null)
                              Row(
                                children: [
                                  Icon(Icons.build_circle, size: 15, color: Colors.grey.shade700),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Equipo/Vehículo: ${vehiculo.marca} ${vehiculo.modelo} (${vehiculo.placa})',
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                                  ),
                                ],
                              ),
                            if (empleado != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.person, size: 15, color: Colors.grey.shade700),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Técnico: ${empleado.nombre}',
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Costo: \$${servicio.costo.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                ),
                                Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: () async {
                                        if (_cliente != null && vehiculo != null) {
                                          await VolanteServicioPdf.generarVolante(
                                            cliente: _cliente!,
                                            vehiculo: vehiculo,
                                            servicio: servicio,
                                            empleado: empleado,
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.print, size: 16),
                                      label: const Text('Volante'),
                                    ),
                                    const SizedBox(width: 4),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        context.navigate('/facturas/nueva/${servicio.id}');
                                      },
                                      icon: const Icon(Icons.receipt_long, size: 16),
                                      label: const Text('Facturar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple.shade700,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }

        return const Center(child: Text('Error cargando historial de trabajos'));
      },
    );
  }

  Widget _buildSummaryMetric({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
            return const Center(child: Text('No hay vehículos o equipos registrados'));
          }

          return ListView.builder(
            itemCount: state.vehiculos.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final vehiculo = state.vehiculos[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.build_circle, size: 40),
                  title: Text('${vehiculo.marca} ${vehiculo.modelo}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Año / Modelo: ${vehiculo.anio}'),
                      Text('Placa / Serie: ${vehiculo.placa}'),
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

        return const Center(child: Text('Error cargando vehículos / equipos'));
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
        title: const Text('Agregar Vehículo / Equipo'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: marcaController,
                  decoration: const InputDecoration(labelText: 'Marca / Tipo de Equipo'),
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: modeloController,
                  decoration: const InputDecoration(labelText: 'Modelo / Referencia'),
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: anioController,
                  decoration: const InputDecoration(labelText: 'Año / Modelo'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: placaController,
                  decoration: const InputDecoration(labelText: 'Placa / N° Serie'),
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
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final vehiculo = Vehiculo(
                  clienteId: widget.clienteId,
                  marca: marcaController.text.trim(),
                  modelo: modeloController.text.trim(),
                  anio: int.parse(anioController.text.trim()),
                  placa: placaController.text.trim().toUpperCase(),
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

  Widget _buildClasificacionBadge(String clasificacion) {
    final clasif = ClasificacionCliente.fromString(clasificacion);
    Color bg;
    Color fg;
    IconData icon;
    switch (clasif) {
      case ClasificacionCliente.conCredito:
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        icon = Icons.credit_card;
        break;
      case ClasificacionCliente.deudor:
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        icon = Icons.warning_amber_rounded;
        break;
      case ClasificacionCliente.vip:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade800;
        icon = Icons.star_rounded;
        break;
      case ClasificacionCliente.normal:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        icon = Icons.person_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            clasif.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}