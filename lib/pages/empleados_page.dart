import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../empleado_bloc.dart';
import '../utils/formatters.dart';

class EmpleadosPage extends StatefulWidget {
  const EmpleadosPage({super.key});

  @override
  State<EmpleadosPage> createState() => _EmpleadosPageState();
}

class _EmpleadosPageState extends State<EmpleadosPage> {
  late final EmpleadoBloc _empleadoBloc;

  @override
  void initState() {
    super.initState();
    _empleadoBloc = inject<EmpleadoBloc>();
    _empleadoBloc.add(LoadEmpleados());
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
        title: const Text('Empleados'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.shade700.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: BlocBuilder<EmpleadoBloc, EmpleadoState>(
            bloc: _empleadoBloc,
            builder: (context, state) {
              if (state is EmpleadoLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.teal.shade700,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Cargando empleados...',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              } else if (state is EmpleadosLoaded) {
                if (state.empleados.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay empleados registrados',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: state.empleados.length,
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final empleado = state.empleados[index];
                    return _buildEmpleadoCard(context, empleado, isMobile);
                  },
                );
              } else if (state is EmpleadoError) {
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
                          'Error: ${state.message}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
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
        onPressed: () => _showEmpleadoFormDialog(),
        backgroundColor: Colors.teal.shade700,
        icon: const Icon(Icons.add),
        label:
            isMobile ? const SizedBox.shrink() : const Text('Nuevo Empleado'),
      ),
    );
  }

  Widget _buildEmpleadoCard(
    BuildContext context,
    Empleado empleado,
    bool isMobile,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.teal.withValues(alpha: 0.2),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showEmpleadoFormDialog(empleado: empleado),
          splashColor: Colors.teal.withValues(alpha: 0.1),
          highlightColor: Colors.teal.withValues(alpha: 0.05),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.teal.withValues(alpha: 0.02),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: isMobile ? 56 : 64,
                    height: isMobile ? 56 : 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          empleado.activo ? Colors.teal.shade700 : Colors.grey,
                          empleado.activo
                              ? Colors.teal.shade900
                              : Colors.grey.shade700,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (empleado.activo ? Colors.teal : Colors.grey)
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        empleado.nombre.isNotEmpty
                            ? empleado.nombre[0].toUpperCase()
                            : 'E',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 24 : 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          empleado.nombre,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 16 : 18,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: isMobile ? 14 : 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formatTelefono(empleado.telefono),
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 15,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        if (empleado.especialidad != null &&
                            empleado.especialidad!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.work,
                                size: isMobile ? 14 : 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                empleado.especialidad!,
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 15,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (empleado.fechaNacimiento != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.cake,
                                size: isMobile ? 14 : 16,
                                color: Colors.pink.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Cumpleaños: ${DateFormat('dd/MM/yyyy').format(empleado.fechaNacimiento!)}',
                                style: TextStyle(
                                  fontSize: isMobile ? 13 : 14,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: (empleado.activo ? Colors.teal : Colors.grey)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                empleado.activo ? 'ACTIVO' : 'INACTIVO',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      empleado.activo ? Colors.teal : Colors.grey,
                                ),
                              ),
                            ),
                            if (empleado.cobraPorcentaje) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.percent,
                                        size: 12, color: Colors.amber.shade800),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Comisión ${empleado.porcentajeComision.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.grey.shade600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 12),
                            Text('Editar Datos'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              empleado.activo
                                  ? Icons.pause_circle
                                  : Icons.play_circle,
                              color: empleado.activo
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                            const SizedBox(width: 12),
                            Text(empleado.activo ? 'Desactivar' : 'Activar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            const SizedBox(width: 12),
                            Text('Eliminar',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEmpleadoFormDialog(empleado: empleado);
                      } else if (value == 'toggle') {
                        final updated = empleado.copyWith(
                          activo: !empleado.activo,
                        );
                        _empleadoBloc.add(UpdateEmpleado(updated));
                      } else if (value == 'delete') {
                        _empleadoBloc.add(DeleteEmpleado(empleado.id!));
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEmpleadoFormDialog({Empleado? empleado}) {
    final isEditing = empleado != null;
    final nombreController = TextEditingController(text: empleado?.nombre ?? '');
    final phoneFormatter = createPhoneMaskFormatter(initialText: empleado?.telefono);
    final telefonoController = TextEditingController(text: phoneFormatter.getMaskedText());
    final especialidadController =
        TextEditingController(text: empleado?.especialidad ?? '');
    DateTime? fechaNacimiento = empleado?.fechaNacimiento;
    bool activo = empleado?.activo ?? true;
    bool cobraPorcentaje = empleado?.cobraPorcentaje ?? false;
    final porcentajeController = TextEditingController(
      text: empleado != null && empleado.cobraPorcentaje
          ? empleado.porcentajeComision.toStringAsFixed(0)
          : '50',
    );
    final formKey = GlobalKey<FormState>();

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
                      Colors.teal.shade700,
                      Colors.teal.shade900,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isEditing ? Icons.edit : Icons.person_add,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(isEditing ? 'Editar Empleado' : 'Nuevo Empleado'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre completo *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: telefonoController,
                    decoration: InputDecoration(
                      labelText: 'Teléfono *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [phoneFormatter],
                    validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: especialidadController,
                    decoration: InputDecoration(
                      labelText: 'Especialidad (opcional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.work),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CAMPO FECHA DE CUMPLEAÑOS
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: fechaNacimiento ?? DateTime(1995, 1, 1),
                        firstDate: DateTime(1940),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: Colors.teal.shade700,
                                onPrimary: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setDialogState(() {
                          fechaNacimiento = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Fecha de Cumpleaños (opcional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(
                          Icons.cake,
                          color: fechaNacimiento != null
                              ? Colors.pink.shade400
                              : Colors.grey,
                        ),
                        suffixIcon: fechaNacimiento != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setDialogState(() {
                                    fechaNacimiento = null;
                                  });
                                },
                              )
                            : null,
                      ),
                      child: Text(
                        fechaNacimiento != null
                            ? DateFormat('dd/MM/yyyy').format(fechaNacimiento!)
                            : 'Seleccionar fecha...',
                        style: TextStyle(
                          color: fechaNacimiento != null
                              ? Colors.black87
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),

                  // CONFIGURACIÓN DE PAGO POR PORCENTAJE
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Cobro por Porcentaje / Comisión',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      cobraPorcentaje
                          ? 'El empleado gana un % por cada trabajo realizado'
                          : 'Sueldo o tarifa fija estándar',
                      style: TextStyle(
                        color: cobraPorcentaje
                            ? Colors.teal.shade700
                            : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    activeTrackColor: Colors.teal.shade700,
                    value: cobraPorcentaje,
                    onChanged: (val) {
                      setDialogState(() {
                        cobraPorcentaje = val;
                      });
                    },
                  ),
                  if (cobraPorcentaje) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: porcentajeController,
                      decoration: InputDecoration(
                        labelText: 'Porcentaje de Comisión (%) *',
                        hintText: 'Ej. 50',
                        suffixText: '%',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.percent),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        if (!cobraPorcentaje) return null;
                        if (v == null || v.trim().isEmpty) {
                          return 'Ingrese el porcentaje';
                        }
                        final numVal = double.tryParse(v.trim());
                        if (numVal == null || numVal < 0 || numVal > 100) {
                          return 'Ingrese un porcentaje válido (0 - 100)';
                        }
                        return null;
                      },
                    ),
                  ],

                  if (isEditing) ...[
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Empleado Activo',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      activeTrackColor: Colors.teal.shade700,
                      value: activo,
                      onChanged: (val) {
                        setDialogState(() {
                          activo = val;
                        });
                      },
                    ),
                  ],
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
                  final esp = especialidadController.text.trim();
                  final pct = cobraPorcentaje
                      ? (double.tryParse(porcentajeController.text.trim()) ?? 0.0)
                      : 0.0;

                  if (isEditing) {
                    final updated = empleado.copyWith(
                      nombre: nombreController.text.trim(),
                      telefono: telefonoController.text.trim(),
                      especialidad: esp.isEmpty ? null : esp,
                      fechaNacimiento: fechaNacimiento,
                      activo: activo,
                      cobraPorcentaje: cobraPorcentaje,
                      porcentajeComision: pct,
                    );
                    _empleadoBloc.add(UpdateEmpleado(updated));
                  } else {
                    final newEmp = Empleado(
                      nombre: nombreController.text.trim(),
                      telefono: telefonoController.text.trim(),
                      especialidad: esp.isEmpty ? null : esp,
                      fechaNacimiento: fechaNacimiento,
                      activo: true,
                      cobraPorcentaje: cobraPorcentaje,
                      porcentajeComision: pct,
                      createdAt: DateTime.now(),
                    );
                    _empleadoBloc.add(CreateEmpleado(newEmp));
                  }
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(isEditing ? 'Actualizar' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
