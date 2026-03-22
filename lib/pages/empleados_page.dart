import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models.dart';
import '../empleado_bloc.dart';

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
    _empleadoBloc = Modular.get<EmpleadoBloc>();
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
          onPressed: () => Modular.to.navigate('/'),
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
        onPressed: () => _showAddEmpleadoDialog(),
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
                        empleado.nombre[0].toUpperCase(),
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
                              empleado.telefono,
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 15,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        if (empleado.especialidad != null) ...[
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
                        const SizedBox(height: 8),
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
                      if (value == 'toggle') {
                        final updated = Empleado(
                          id: empleado.id,
                          nombre: empleado.nombre,
                          telefono: empleado.telefono,
                          especialidad: empleado.especialidad,
                          activo: !empleado.activo,
                          createdAt: empleado.createdAt,
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

  void _showAddEmpleadoDialog() {
    final nombreController = TextEditingController();
    final telefonoController = TextEditingController();
    final especialidadController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              child: const Icon(
                Icons.person_add,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Nuevo Empleado'),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                final empleado = Empleado(
                  nombre: nombreController.text,
                  telefono: telefonoController.text,
                  especialidad: especialidadController.text.isEmpty
                      ? null
                      : especialidadController.text,
                  activo: true,
                  createdAt: DateTime.now(),
                );
                _empleadoBloc.add(CreateEmpleado(empleado));
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
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
