import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../models.dart';
import '../servicio_predefinido_bloc.dart';

class ServiciosPredefinidosPage extends StatefulWidget {
  const ServiciosPredefinidosPage({super.key});

  @override
  State<ServiciosPredefinidosPage> createState() => _ServiciosPredefinidosPageState();
}

class _ServiciosPredefinidosPageState extends State<ServiciosPredefinidosPage> {
  late final ServicioPredefinidoBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = Modular.get<ServicioPredefinidoBloc>();
    _bloc.add(LoadServiciosPredefinidos());
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
        title: const Text('Servicios Predefinidos'),
        backgroundColor: Colors.deepPurple.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _bloc.add(LoadServiciosPredefinidos()),
          ),
        ],
      ),
      body: BlocBuilder<ServicioPredefinidoBloc, ServicioPredefinidoState>(
        bloc: _bloc,
        builder: (context, state) {
          if (state is ServicioPredefinidoLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ServicioPredefinidoError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _bloc.add(LoadServiciosPredefinidos()),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (state is ServiciosPredefinidosLoaded) {
            if (state.servicios.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.build_outlined, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No hay servicios predefinidos',
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Presiona el botón + para agregar',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              );
            }

            // Agrupar por categoría
            final Map<String, List<ServicioPredefinido>> porCategoria = {};
            for (var servicio in state.servicios) {
              final categoria = servicio.categoria ?? 'Sin Categoría';
              porCategoria.putIfAbsent(categoria, () => []);
              porCategoria[categoria]!.add(servicio);
            }

            return ListView.builder(
              itemCount: porCategoria.length,
              padding: EdgeInsets.all(screenWidth * 0.03),
              itemBuilder: (context, index) {
                final categoria = porCategoria.keys.elementAt(index);
                final servicios = porCategoria[categoria]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Text(
                        categoria.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                    ),
                    ...servicios.map((servicio) => _buildServicioCard(servicio, isMobile)),
                    const SizedBox(height: 16),
                  ],
                );
              },
            );
          }

          return const Center(child: Text('Estado desconocido'));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddServicioDialog,
        backgroundColor: Colors.deepPurple.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          isMobile ? '' : 'Nuevo Servicio',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildServicioCard(ServicioPredefinido servicio, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: servicio.activo
                  ? Colors.deepPurple.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.build_circle,
              color: servicio.activo ? Colors.deepPurple.shade700 : Colors.grey,
            ),
          ),
          title: Text(
            servicio.nombre,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (servicio.descripcion != null)
                Text(
                  servicio.descripcion!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: servicio.activo ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      servicio.activo ? 'ACTIVO' : 'INACTIVO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Código: ${servicio.codigo}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '\$${servicio.precio.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade700,
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          servicio.activo ? Icons.pause_circle : Icons.play_circle,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(servicio.activo ? 'Desactivar' : 'Activar'),
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
                  if (value == 'edit') {
                    _showAddServicioDialog(servicio: servicio);
                  } else if (value == 'toggle') {
                    _bloc.add(UpdateServicioPredefinido(
                      servicio.copyWith(activo: !servicio.activo),
                    ));
                  } else if (value == 'delete') {
                    _showDeleteDialog(servicio.id!);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddServicioDialog({ServicioPredefinido? servicio}) {
    final isEdit = servicio != null;
    final codigoController = TextEditingController(text: servicio?.codigo ?? '');
    final nombreController = TextEditingController(text: servicio?.nombre ?? '');
    final descripcionController = TextEditingController(text: servicio?.descripcion ?? '');
    final precioController = TextEditingController(
      text: servicio?.precio.toStringAsFixed(2) ?? '',
    );
    final categoriaController = TextEditingController(text: servicio?.categoria ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Editar Servicio' : 'Nuevo Servicio Predefinido'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codigoController,
                  decoration: const InputDecoration(
                    labelText: 'Código *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.qr_code),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                  enabled: !isEdit,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Servicio *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.build),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: precioController,
                  decoration: const InputDecoration(
                    labelText: 'Precio *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: categoriaController,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                    hintText: 'Ej: Mantenimiento, Reparación, Cambio de aceite',
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
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final nuevoServicio = ServicioPredefinido(
                  id: servicio?.id,
                  codigo: codigoController.text,
                  nombre: nombreController.text,
                  descripcion: descripcionController.text.isEmpty
                      ? null
                      : descripcionController.text,
                  precio: double.parse(precioController.text),
                  categoria: categoriaController.text.isEmpty
                      ? null
                      : categoriaController.text,
                  activo: servicio?.activo ?? true,
                  createdAt: servicio?.createdAt ?? DateTime.now(),
                );

                if (isEdit) {
                  _bloc.add(UpdateServicioPredefinido(nuevoServicio));
                } else {
                  _bloc.add(CreateServicioPredefinido(nuevoServicio));
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEdit ? 'Servicio actualizado' : 'Servicio agregado',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple.shade700,
              foregroundColor: Colors.white,
            ),
            child: Text(isEdit ? 'Actualizar' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text(
          '¿Estás seguro de eliminar este servicio predefinido?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              _bloc.add(DeleteServicioPredefinido(id));
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
}