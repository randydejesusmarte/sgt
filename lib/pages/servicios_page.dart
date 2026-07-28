import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../servicio_bloc.dart';
import '../repositories.dart';
import '../utils/volante_servicio_pdf.dart';
import '../utils/formatters.dart';

class ServiciosPage extends StatefulWidget {
  const ServiciosPage({super.key});

  @override
  State<ServiciosPage> createState() => _ServiciosPageState();
}

class _ServiciosPageState extends State<ServiciosPage> {
  late final ServicioBloc _servicioBloc;
  String _filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    _servicioBloc = inject<ServicioBloc>();
    _servicioBloc.add(LoadServicios());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.navigate('/'),
        ),
        title: const Text('Servicios'),
        backgroundColor: Colors.indigo.shade700,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo.shade700.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: BlocBuilder<ServicioBloc, ServicioState>(
            bloc: _servicioBloc,
            builder: (context, state) {
              if (state is ServicioLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.indigo.shade700,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Cargando servicios...',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              } else if (state is ServiciosLoaded) {
                if (state.servicios.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.build_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay servicios registrados',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Presiona el botón + para agregar tu primer servicio',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final serviciosFiltrados = _filtroEstado == 'todos'
                    ? state.servicios
                    : state.servicios
                        .where((s) =>
                            s.estado.toLowerCase() ==
                            _filtroEstado.toLowerCase())
                        .toList();

                return Column(
                  children: [
                    // Barra de Filtros por Estado
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          _buildFilterChip('Todos', 'todos'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Pendiente', 'pendiente'),
                          const SizedBox(width: 8),
                          _buildFilterChip('En Proceso', 'en_proceso'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Completado', 'completado'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Cancelado', 'cancelado'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: serviciosFiltrados.isEmpty
                          ? Center(
                              child: Text(
                                'No hay servicios en este estado',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              itemCount: serviciosFiltrados.length,
                              padding: EdgeInsets.all(screenWidth * 0.03),
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                final servicio = serviciosFiltrados[index];
                                final vehiculo =
                                    state.vehiculos[servicio.vehiculoId];
                                final cliente = vehiculo != null
                                    ? state.clientes[vehiculo.clienteId]
                                    : null;
                                final empleado = servicio.empleadoId != null
                                    ? state.empleados[servicio.empleadoId]
                                    : null;

                                return _buildServicioCard(
                                  context,
                                  servicio,
                                  cliente,
                                  vehiculo,
                                  empleado,
                                  isMobile,
                                );
                              },
                            ),
                    ),
                  ],
                );
              } else if (state is ServicioError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _servicioBloc.add(LoadServicios()),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const Center(child: Text('Estado no manejado'));
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddServicioDialog(),
        backgroundColor: Colors.indigo.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          isMobile ? '' : 'Nuevo Servicio',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildServicioCard(
    BuildContext context,
    Servicio servicio,
    Cliente? cliente,
    Vehiculo? vehiculo,
    Empleado? empleado,
    bool isMobile,
  ) {
    final estadoColor = _getEstadoColor(servicio.estado);
    final estadoInfo = _getEstadoInfo(servicio.estado);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: estadoColor.withValues(alpha: 0.3),
        child: InkWell(
          onTap: () {
            _showServicioMenu(context, servicio, cliente, vehiculo, empleado);
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: estadoColor.withValues(alpha: 0.1),
          highlightColor: estadoColor.withValues(alpha: 0.05),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  estadoColor.withValues(alpha: 0.03),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              estadoColor,
                              estadoColor.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: estadoColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          estadoInfo['icon'] as IconData,
                          color: Colors.white,
                          size: isMobile ? 24 : 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: estadoColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                estadoInfo['label'] as String,
                                style: TextStyle(
                                  color: estadoColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('dd/MM/yyyy')
                                      .format(servicio.fecha),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.indigo.shade700,
                              Colors.indigo.shade900,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '\$${servicio.costo.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    toTitleCase(servicio.descripcion),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 16 : 17,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (cliente != null && vehiculo != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 18,
                                color: Colors.indigo.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  cliente.nombre,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.directions_car,
                                size: 18,
                                color: Colors.indigo.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${vehiculo.marca} ${vehiculo.modelo} - ${vehiculo.placa}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (empleado != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.engineering,
                            size: 16,
                            color: Colors.indigo.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mecánico: ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            empleado.nombre,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (cliente != null && vehiculo != null) {
                          await _imprimirVolanteConOpcion(
                            cliente: cliente,
                            vehiculo: vehiculo,
                            servicio: servicio,
                            empleado: empleado,
                          );
                        }
                      },
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Imprimir Volante'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _imprimirVolanteConOpcion({
    required Cliente cliente,
    required Vehiculo vehiculo,
    required Servicio servicio,
    Empleado? empleado,
  }) async {
    final bool? es80mm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.print, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Formato de Volante'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
              title: const Text('Cuarta parte de hoja'),
              subtitle: const Text('Estándar (8.5 x 2.75 in)'),
              onTap: () => Navigator.pop(context, false),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.receipt, color: Colors.green),
              title: const Text('Impresora Térmica'),
              subtitle: const Text('Tique 80 mm'),
              onTap: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );

    if (es80mm != null) {
      await VolanteServicioPdf.generarVolante(
        cliente: cliente,
        vehiculo: vehiculo,
        servicio: servicio,
        empleado: empleado,
        esImpresora80mm: es80mm,
      );
    }
  }

  void _showServicioMenu(
    BuildContext context,
    Servicio servicio,
    Cliente? cliente,
    Vehiculo? vehiculo,
    Empleado? empleado,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.print, color: Colors.green),
              title: const Text('Imprimir Volante'),
              onTap: () async {
                Navigator.pop(context);
                if (cliente != null && vehiculo != null) {
                  await _imprimirVolanteConOpcion(
                    cliente: cliente,
                    vehiculo: vehiculo,
                    servicio: servicio,
                    empleado: empleado,
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.purple),
              title: const Text('Facturar Servicio (1 Clic)'),
              subtitle: const Text('Pre-carga cliente, vehículo y monto'),
              onTap: () {
                Navigator.pop(context);
                context.navigate('/facturas/nueva/${servicio.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: const Text('Editar Estado'),
              onTap: () {
                Navigator.pop(context);
                _showEstadoDialog(servicio);
              },
            ),
            //ListTile(
            //  leading: const Icon(Icons.delete, color: Colors.red),
            //  title: const Text('Eliminar Servicio'),
            //  onTap: () {
            //    Navigator.pop(context);
            //    _showDeleteDialog(servicio.id!);
            //  },
            //),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filtroEstado == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.indigo.shade900,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: Colors.indigo.shade700,
      backgroundColor: Colors.white,
      checkmarkColor: Colors.white,
      onSelected: (selected) {
        setState(() {
          _filtroEstado = value;
        });
      },
    );
  }

  void _showEstadoDialog(Servicio servicio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Estado'),
        content: RadioGroup<String>(
          groupValue: servicio.estado,
          onChanged: (newValue) {
            if (newValue != null) {
              final updated = Servicio(
                id: servicio.id,
                vehiculoId: servicio.vehiculoId,
                empleadoId: servicio.empleadoId,
                descripcion: servicio.descripcion,
                costo: servicio.costo,
                fecha: servicio.fecha,
                estado: newValue,
                notas: servicio.notas,
              );
              _servicioBloc.add(UpdateServicio(updated));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Estado actualizado a: $newValue'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEstadoRadio('Pendiente', 'pendiente'),
              _buildEstadoRadio('En Proceso', 'en_proceso'),
              _buildEstadoRadio('Completado', 'completado'),
              _buildEstadoRadio('Cancelado', 'cancelado'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoRadio(String label, String value) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
    );
  }

  /*void _showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de eliminar este servicio? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              _servicioBloc.add(DeleteServicio(id));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Servicio eliminado'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }*/

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'completado':
        return Colors.green;
      case 'en_proceso':
        return Colors.blue;
      case 'pendiente':
        return Colors.orange;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Map<String, dynamic> _getEstadoInfo(String estado) {
    switch (estado) {
      case 'completado':
        return {'label': 'COMPLETADO', 'icon': Icons.check_circle};
      case 'en_proceso':
        return {'label': 'EN PROCESO', 'icon': Icons.build};
      case 'pendiente':
        return {'label': 'PENDIENTE', 'icon': Icons.schedule};
      case 'cancelado':
        return {'label': 'CANCELADO', 'icon': Icons.cancel};
      default:
        return {'label': 'DESCONOCIDO', 'icon': Icons.help};
    }
  }

  void _showAddServicioDialog() async {
    final clientes = await inject<ClienteRepository>().getAll();
    final serviciosPredefinidos =
        await inject<ServicioPredefinidoRepository>().getActivos();
    final empleados = await inject<EmpleadoRepository>().getActivos();

    bool esNuevoCliente = clientes.isEmpty;

    Cliente? clienteSeleccionado;
    Vehiculo? vehiculoSeleccionado;
    Empleado? empleadoSeleccionado;
    ServicioPredefinido? servicioPredefinidoSeleccionado;
    List<Vehiculo> vehiculos = [];

    // Controladores para nuevo cliente y vehículo
    final nombreClienteController = TextEditingController();
    final telefonoClienteController = TextEditingController();
    final marcaVehiculoController = TextEditingController();
    final modeloVehiculoController = TextEditingController();
    final placaVehiculoController = TextEditingController();
    final anioVehiculoController =
        TextEditingController(text: DateTime.now().year.toString());

    // Controladores para servicio
    final descripcionController = TextEditingController();
    final costoController = TextEditingController();
    final notasController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String estadoSeleccionado = 'pendiente';
    bool usarServicioPredefinido = serviciosPredefinidos.isNotEmpty;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.indigo.shade700,
                      Colors.indigo.shade900,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.build,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Nuevo Servicio')),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Selector de modo: Cliente Existente o Nuevo Cliente + Auto
                  if (clientes.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Cliente Existente'),
                            icon: Icon(Icons.person_search, size: 18),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('+ Nuevo Cliente / Auto'),
                            icon: Icon(Icons.person_add, size: 18),
                          ),
                        ],
                        selected: {esNuevoCliente},
                        onSelectionChanged: (newSelection) {
                          setDialogState(() {
                            esNuevoCliente = newSelection.first;
                          });
                        },
                      ),
                    ),

                  if (esNuevoCliente) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue.shade800, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Se registrará el Cliente, Vehículo y Servicio en 1 solo paso.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildTextField(
                      controller: nombreClienteController,
                      label: 'Nombre del Cliente *',
                      icon: Icons.person,
                      validator: (v) =>
                          v?.trim().isEmpty ?? true ? 'Ingresa el nombre' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: telefonoClienteController,
                      label: 'Teléfono del Cliente *',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v?.trim().isEmpty ?? true
                          ? 'Ingresa el teléfono'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: marcaVehiculoController,
                      label: 'Marca / Equipo (ej: Toyota / Planta) *',
                      icon: Icons.car_repair,
                      validator: (v) =>
                          v?.trim().isEmpty ?? true ? 'Ingresa la marca o equipo' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: modeloVehiculoController,
                      label: 'Modelo / Referencia (ej: Corolla / CAT35) *',
                      icon: Icons.directions_car,
                      validator: (v) =>
                          v?.trim().isEmpty ?? true ? 'Ingresa el modelo o referencia' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: placaVehiculoController,
                            label: 'Placa / N° Serie *',
                            icon: Icons.pin,
                            validator: (v) => v?.trim().isEmpty ?? true
                                ? 'Ingresa placa o N° serie'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTextField(
                            controller: anioVehiculoController,
                            label: 'Año',
                            icon: Icons.calendar_today,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    _buildDropdownField<Cliente?>(
                      value: clienteSeleccionado,
                      label: 'Cliente',
                      icon: Icons.person,
                      items: clientes.map((cliente) {
                        return DropdownMenuItem(
                          value: cliente,
                          child: Text(cliente.nombre),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        setDialogState(() {
                          clienteSeleccionado = value;
                          vehiculoSeleccionado = null;
                        });
                        if (value != null) {
                          vehiculos = await inject<VehiculoRepository>()
                              .getByClienteId(value.id!);
                          setDialogState(() {});
                        }
                      },
                      validator: (v) =>
                          v == null ? 'Selecciona un cliente' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField<Vehiculo?>(
                      value: vehiculoSeleccionado,
                      label: 'Vehículo / Equipo',
                      icon: Icons.build_circle,
                      items: vehiculos.map((vehiculo) {
                        return DropdownMenuItem(
                          value: vehiculo,
                          child: Text(
                              '${vehiculo.marca} ${vehiculo.modelo} - ${vehiculo.placa}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => vehiculoSeleccionado = value);
                      },
                      validator: (v) =>
                          v == null ? 'Selecciona un vehículo o equipo' : null,
                    ),
                    if (clienteSeleccionado != null) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final nuevoVehiculo = await _mostrarDialogoNuevoVehiculo(context, clienteSeleccionado!);
                          if (nuevoVehiculo != null) {
                            final vehiculosActualizados = await inject<VehiculoRepository>().getByClienteId(clienteSeleccionado!.id!);
                            setDialogState(() {
                              vehiculos = vehiculosActualizados;
                              vehiculoSeleccionado = vehiculosActualizados.firstWhere(
                                (v) => v.id == nuevoVehiculo.id,
                                orElse: () => nuevoVehiculo,
                              );
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text('Equipo "${nuevoVehiculo.marca} ${nuevoVehiculo.modelo}" registrado y seleccionado'),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.green.shade700,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.indigo.shade50, Colors.blue.shade50],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.indigo.withValues(alpha: 0.25), width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.shade700,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '¿Es un equipo o vehículo nuevo?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.indigo.shade900,
                                        ),
                                      ),
                                      Text(
                                        'Haz clic aquí para agregarlo a ${clienteSeleccionado!.nombre}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.indigo.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Icon(Icons.chevron_right, color: Colors.indigo.shade700, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],

                  // Switch para elegir entre servicio predefinido o personalizado
                  if (serviciosPredefinidos.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.indigo.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.settings_applications,
                              size: 20, color: Colors.indigo),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Usar servicio predefinido',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Switch(
                            value: usarServicioPredefinido,
                            onChanged: (value) {
                              setDialogState(() {
                                usarServicioPredefinido = value;
                                if (!value) {
                                  servicioPredefinidoSeleccionado = null;
                                  descripcionController.clear();
                                  costoController.clear();
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                  if (serviciosPredefinidos.isNotEmpty)
                    const SizedBox(height: 16),

                  // Mostrar dropdown de servicios predefinidos o campos manuales
                  if (usarServicioPredefinido &&
                      serviciosPredefinidos.isNotEmpty) ...[
                    _buildDropdownField<ServicioPredefinido?>(
                      value: servicioPredefinidoSeleccionado,
                      label: 'Servicio Predefinido *',
                      icon: Icons.build_circle,
                      items: serviciosPredefinidos.map((servicio) {
                        return DropdownMenuItem(
                          value: servicio,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(servicio.nombre),
                              Text(
                                '\$${servicio.precio.toStringAsFixed(2)}${servicio.categoria != null ? ' - ${servicio.categoria}' : ''}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          servicioPredefinidoSeleccionado = value;
                          if (value != null) {
                            descripcionController.text =
                                value.descripcion ?? value.nombre;
                            costoController.text =
                                value.precio.toStringAsFixed(2);
                          }
                        });
                      },
                      validator: (v) =>
                          v == null ? 'Selecciona un servicio' : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Descripción editable
                  if (!usarServicioPredefinido ||
                      servicioPredefinidoSeleccionado != null ||
                      serviciosPredefinidos.isEmpty) ...[
                    _buildTextField(
                      controller: descripcionController,
                      label: usarServicioPredefinido &&
                              servicioPredefinidoSeleccionado != null
                          ? 'Descripción (puedes editarla)'
                          : 'Descripción del servicio *',
                      icon: Icons.description,
                      maxLines: 2,
                      validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Costo editable
                  if (!usarServicioPredefinido ||
                      servicioPredefinidoSeleccionado != null ||
                      serviciosPredefinidos.isEmpty) ...[
                    _buildTextField(
                      controller: costoController,
                      label: usarServicioPredefinido &&
                              servicioPredefinidoSeleccionado != null
                          ? 'Costo (ajustable)'
                          : 'Costo estimado *',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildDropdownField<Empleado?>(
                    value: empleadoSeleccionado,
                    label: 'Mecánico Asignado',
                    icon: Icons.engineering,
                    items: [
                      const DropdownMenuItem<Empleado?>(
                        value: null,
                        child: Text('Sin asignar'),
                      ),
                      ...empleados.map((empleado) {
                        return DropdownMenuItem<Empleado?>(
                          value: empleado,
                          child: Text(
                              '${empleado.nombre}${empleado.especialidad != null ? ' - ${empleado.especialidad}' : ''}'),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setDialogState(() => empleadoSeleccionado = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField<String>(
                    value: estadoSeleccionado,
                    label: 'Estado',
                    icon: Icons.flag,
                    items: const [
                      DropdownMenuItem(
                          value: 'pendiente', child: Text('Pendiente')),
                      DropdownMenuItem(
                          value: 'en_proceso', child: Text('En Proceso')),
                      DropdownMenuItem(
                          value: 'completado', child: Text('Completado')),
                      DropdownMenuItem(
                          value: 'cancelado', child: Text('Cancelado')),
                    ],
                    onChanged: (value) {
                      setDialogState(
                          () => estadoSeleccionado = value ?? 'pendiente');
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: notasController,
                    label: 'Notas adicionales',
                    icon: Icons.note,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  int vehiculoId;

                  if (esNuevoCliente) {
                    final clienteRepo = inject<ClienteRepository>();
                    final vehiculoRepo = inject<VehiculoRepository>();

                    final clienteId = await clienteRepo.create(Cliente(
                      nombre: nombreClienteController.text.trim(),
                      telefono: telefonoClienteController.text.trim(),
                      createdAt: DateTime.now(),
                    ));

                    vehiculoId = await vehiculoRepo.create(Vehiculo(
                      clienteId: clienteId,
                      marca: marcaVehiculoController.text.trim(),
                      modelo: modeloVehiculoController.text.trim(),
                      anio: int.tryParse(anioVehiculoController.text) ??
                          DateTime.now().year,
                      placa: placaVehiculoController.text.trim().toUpperCase(),
                    ));
                  } else {
                    vehiculoId = vehiculoSeleccionado!.id!;
                  }

                  final servicio = Servicio(
                    id: null,
                    vehiculoId: vehiculoId,
                    empleadoId: empleadoSeleccionado?.id,
                    descripcion: toTitleCase(descripcionController.text.trim()),
                    costo: double.parse(costoController.text),
                    fecha: DateTime.now(),
                    estado: estadoSeleccionado,
                    notas: notasController.text.isEmpty
                        ? null
                        : notasController.text,
                  );

                  _servicioBloc.add(CreateServicio(servicio));
                  if (!context.mounted) return;
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Servicio registrado exitosamente'),
                        ],
                      ),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<Vehiculo?> _mostrarDialogoNuevoVehiculo(BuildContext context, Cliente cliente) async {
    final marcaController = TextEditingController();
    final modeloController = TextEditingController();
    final anioController = TextEditingController(text: DateTime.now().year.toString());
    final placaController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return await showDialog<Vehiculo>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxWidth: 520),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Encabezado estilizado con gradiente
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade800, Colors.blue.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.build_circle_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Registrar Nuevo Equipo / Vehículo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Cliente: ${cliente.nombre}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Cuerpo del Formulario
              Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge informativo
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber.shade900),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'El nuevo equipo quedará vinculado al cliente y se seleccionará de inmediato.',
                                style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: marcaController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Marca / Tipo de Equipo *',
                          hintText: 'Ej: Toyota, Caterpillar, Planta Eléctrica, Generador',
                          prefixIcon: const Icon(Icons.car_repair, color: Colors.indigo),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.indigo.shade700, width: 2),
                          ),
                        ),
                        validator: (v) => v?.trim().isEmpty ?? true ? 'Ingresa la marca o tipo de equipo' : null,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: modeloController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Modelo / Referencia *',
                          hintText: 'Ej: Corolla, CAT 3500, GX200, Serie X',
                          prefixIcon: const Icon(Icons.directions_car, color: Colors.indigo),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.indigo.shade700, width: 2),
                          ),
                        ),
                        validator: (v) => v?.trim().isEmpty ?? true ? 'Ingresa el modelo o referencia' : null,
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: placaController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                labelText: 'Placa / N° Serie *',
                                hintText: 'Ej: A123456 / SN-8842',
                                prefixIcon: const Icon(Icons.pin, color: Colors.indigo),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.indigo.shade700, width: 2),
                                ),
                              ),
                              validator: (v) => v?.trim().isEmpty ?? true ? 'Campo requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: anioController,
                              decoration: InputDecoration(
                                labelText: 'Año / Modelo',
                                hintText: 'Ej: 2024',
                                prefixIcon: const Icon(Icons.calendar_today, color: Colors.indigo),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.indigo.shade700, width: 2),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Botones de acción
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext, null),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Guardar Equipo', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade700,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final vehiculoRepo = inject<VehiculoRepository>();
                          final vehiculo = Vehiculo(
                            clienteId: cliente.id!,
                            marca: toTitleCase(marcaController.text.trim()),
                            modelo: toTitleCase(modeloController.text.trim()),
                            anio: int.tryParse(anioController.text) ?? DateTime.now().year,
                            placa: placaController.text.trim().toUpperCase(),
                          );
                          final id = await vehiculoRepo.create(vehiculo);
                          final nuevoVehiculo = vehiculo.copyWith(id: id);
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext, nuevoVehiculo);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.indigo.shade700, size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.indigo.shade700, width: 2),
        ),
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final effectiveFormatters = inputFormatters ??
        ((keyboardType == TextInputType.phone ||
                label.toLowerCase().contains('teléfono') ||
                label.toLowerCase().contains('telefono'))
            ? [createPhoneMaskFormatter()]
            : null);

    return TextFormField(
      controller: controller,
      inputFormatters: effectiveFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.indigo.shade700, size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.indigo.shade700, width: 2),
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.words,
      validator: validator,
    );
  }
}
