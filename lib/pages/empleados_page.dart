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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Modular.to.navigate('/'),
        ),
        title: const Text('Empleados'),
        backgroundColor: Colors.teal.shade700,
      ),
      body: BlocBuilder<EmpleadoBloc, EmpleadoState>(
        bloc: _empleadoBloc,
        builder: (context, state) {
          if (state is EmpleadoLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is EmpleadosLoaded) {
            if (state.empleados.isEmpty) {
              return const Center(child: Text('No hay empleados registrados'));
            }
            return ListView.builder(
              itemCount: state.empleados.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final empleado = state.empleados[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: empleado.activo
                          ? Colors.teal.shade700
                          : Colors.grey,
                      child: Text(
                        empleado.nombre[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      empleado.nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tel: ${empleado.telefono}'),
                        if (empleado.especialidad != null)
                          Text('Especialidad: ${empleado.especialidad}'),
                        Chip(
                          label: Text(
                            empleado.activo ? 'ACTIVO' : 'INACTIVO',
                            style: const TextStyle(fontSize: 10, color: Colors.white),
                          ),
                          backgroundColor: empleado.activo ? Colors.green : Colors.grey,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(empleado.activo
                                  ? Icons.pause_circle
                                  : Icons.play_circle),
                              const SizedBox(width: 8),
                              Text(empleado.activo ? 'Desactivar' : 'Activar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Eliminar', style: TextStyle(color: Colors.red)),
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
                  ),
                );
              },
            );
          } else if (state is EmpleadoError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const Center(child: Text('Estado no manejado'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEmpleadoDialog(),
        backgroundColor: Colors.teal.shade700,
        child: const Icon(Icons.add),
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
        title: const Text('Agregar Empleado'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: especialidadController,
                  decoration: const InputDecoration(
                    labelText: 'Especialidad (opcional)',
                    border: OutlineInputBorder(),
                  ),
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
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}