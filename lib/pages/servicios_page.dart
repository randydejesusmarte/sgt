import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../servicio_bloc.dart';
import '../repositories.dart';
import '../utils/volante_servicio_pdf.dart';

class ServiciosPage extends StatefulWidget {
  const ServiciosPage({super.key});

  @override
  State<ServiciosPage> createState() => _ServiciosPageState();
}

class _ServiciosPageState extends State<ServiciosPage> {
  late final ServicioBloc _servicioBloc;

  @override
  void initState() {
    super.initState();
    _servicioBloc = Modular.get<ServicioBloc>();
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
          onPressed: () => Modular.to.navigate('/'),
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

                return ListView.builder(
                  itemCount: state.servicios.length,
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final servicio = state.servicios[index];
                    final vehiculo = state.vehiculos[servicio.vehiculoId];
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
                                  DateFormat('dd/MM/yyyy').format(servicio.fecha),
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
                    servicio.descripcion,
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
                          await VolanteServicioPdf.generarVolante(
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
                  await VolanteServicioPdf.generarVolante(
                    cliente: cliente,
                    vehiculo: vehiculo,
                    servicio: servicio,
                    empleado: empleado,
                  );
                }
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
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar Servicio'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(servicio.id!);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEstadoDialog(Servicio servicio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEstadoRadio('Pendiente', 'pendiente', servicio),
            _buildEstadoRadio('En Proceso', 'en_proceso', servicio),
            _buildEstadoRadio('Completado', 'completado', servicio),
            _buildEstadoRadio('Cancelado', 'cancelado', servicio),
          ],
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

  Widget _buildEstadoRadio(String label, String value, Servicio servicio) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
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
              content: Text('Estado actualizado a: $label'),
              backgroundColor: Colors.green,
            ),
          );
        };
      },
    );
  }

  void _showDeleteDialog(int id) {
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
  }

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
    final clientes = await Modular.get<ClienteRepository>().getAll();
    if (clientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Primero debes registrar un cliente y vehículo'),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    Cliente? clienteSeleccionado;
    Vehiculo? vehiculoSeleccionado;
    Empleado? empleadoSeleccionado;
    List<Vehiculo> vehiculos = [];
    final empleados = await Modular.get<EmpleadoRepository>().getActivos();

    final descripcionController = TextEditingController();
    final costoController = TextEditingController();
    final notasController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String estadoSeleccionado = 'pendiente';

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
              const Text('Nuevo Servicio'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                        vehiculos = await Modular.get<VehiculoRepository>()
                            .getByClienteId(value.id!);
                        setDialogState(() {});
                      }
                    },
                    validator: (v) => v == null ? 'Selecciona un cliente' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField<Vehiculo?>(
                    value: vehiculoSeleccionado,
                    label: 'Vehículo',
                    icon: Icons.directions_car,
                    items: vehiculos.map((vehiculo) {
                      return DropdownMenuItem(
                        value: vehiculo,
                        child: Text('${vehiculo.marca} ${vehiculo.modelo} - ${vehiculo.placa}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => vehiculoSeleccionado = value);
                    },
                    validator: (v) => v == null ? 'Selecciona un vehículo' : null,
                  ),
                  const SizedBox(height: 16),
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
                          child: Text('${empleado.nombre}${empleado.especialidad != null ? ' - ${empleado.especialidad}' : ''}'),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setDialogState(() => empleadoSeleccionado = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: descripcionController,
                    label: 'Descripción del servicio',
                    icon: Icons.description,
                    maxLines: 2,
                    validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: costoController,
                    label: 'Costo estimado',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField<String>(
                    value: estadoSeleccionado,
                    label: 'Estado',
                    icon: Icons.flag,
                    items: const [
                      DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                      DropdownMenuItem(value: 'en_proceso', child: Text('En Proceso')),
                      DropdownMenuItem(value: 'completado', child: Text('Completado')),
                      DropdownMenuItem(value: 'cancelado', child: Text('Cancelado')),
                    ],
                    onChanged: (value) {
                      setDialogState(() => estadoSeleccionado = value ?? 'pendiente');
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
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final servicio = Servicio(
                    id: null,
                    vehiculoId: vehiculoSeleccionado!.id!,
                    empleadoId: empleadoSeleccionado?.id,
                    descripcion: descripcionController.text,
                    costo: double.parse(costoController.text),
                    fecha: DateTime.now(),
                    estado: estadoSeleccionado,
                    notas: notasController.text.isEmpty ? null : notasController.text,
                  );
                  _servicioBloc.add(CreateServicio(servicio));
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Servicio creado exitosamente'),
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

  Widget _buildDropdownField<T>({
    required T value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
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
      validator: validator,
    );
  }
}