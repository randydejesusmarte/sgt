import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:taller_autos/marca_bloc.dart';
import 'package:taller_autos/modelo_bloc.dart';
import 'package:taller_autos/models.dart';

class ConfigMarcasPage extends StatefulWidget {
  const ConfigMarcasPage({super.key});

  @override
  State<ConfigMarcasPage> createState() => _ConfigMarcasPageState();
}

class _ConfigMarcasPageState extends State<ConfigMarcasPage> {
  final _marcaBloc = inject<MarcaBloc>();

  @override
  void initState() {
    super.initState();
    _marcaBloc.loadMarcas();
  }

  void _showAddMarcaDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Marca'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nombre de la Marca'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _marcaBloc.addMarca(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showModelosDialog(Marca marca) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ModelosManager(marca: marca),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Marcas'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.navigate('/'),
        ),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: _marcaBloc,
        builder: (context, _) {
          if (_marcaBloc.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_marcaBloc.error != null) {
            return Center(child: Text('Error: ${_marcaBloc.error}'));
          }
          if (_marcaBloc.marcas.isEmpty) {
            return const Center(child: Text('No hay marcas registradas'));
          }

          return ListView.builder(
            itemCount: _marcaBloc.marcas.length,
            itemBuilder: (context, index) {
              final marca = _marcaBloc.marcas[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(marca.nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.list, color: Colors.blue),
                        onPressed: () => _showModelosDialog(marca),
                        tooltip: 'Ver Modelos',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(marca),
                      ),
                    ],
                  ),
                  onTap: () => _showModelosDialog(marca),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMarcaDialog,
        backgroundColor: Colors.blue.shade800,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(Marca marca) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Marca'),
        content: Text(
            '¿Seguro que desea eliminar "${marca.nombre}"? Se borrarán todos sus modelos y piezas.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              _marcaBloc.deleteMarca(marca.id!);
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class ModelosManager extends StatefulWidget {
  final Marca marca;
  const ModelosManager({super.key, required this.marca});

  @override
  State<ModelosManager> createState() => _ModelosManagerState();
}

class _ModelosManagerState extends State<ModelosManager> {
  final _modeloBloc = inject<ModeloBloc>();

  @override
  void initState() {
    super.initState();
    _modeloBloc.loadModelos(widget.marca.id!);
  }

  void _showAddModeloDialog() {
    final nombreCtrl = TextEditingController();
    final anioCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nuevo Modelo para ${widget.marca.nombre}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre del Modelo'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: anioCtrl,
              decoration: const InputDecoration(labelText: 'Año'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (nombreCtrl.text.isNotEmpty && anioCtrl.text.isNotEmpty) {
                _modeloBloc.addModelo(widget.marca.id!, nombreCtrl.text,
                    int.tryParse(anioCtrl.text) ?? 0);
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.maxFinite,
      height: 500, // Fixed height for dialog
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text('Modelos de ${widget.marca.nombre}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold))),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),
          Expanded(
            child: AnimatedBuilder(
              animation: _modeloBloc,
              builder: (context, _) {
                if (_modeloBloc.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_modeloBloc.modelos.isEmpty) {
                  return const Center(
                      child: Text('No hay modelos registrados'));
                }
                return ListView.builder(
                  itemCount: _modeloBloc.modelos.length,
                  itemBuilder: (context, index) {
                    final modelo = _modeloBloc.modelos[index];
                    return ListTile(
                      title: Text(modelo.nombre),
                      subtitle: Text('Año: ${modelo.anio}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _modeloBloc.deleteModelo(
                            modelo.id!, widget.marca.id!),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _showAddModeloDialog,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Modelo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ],
      ),
    );
  }
}
