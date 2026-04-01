import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:taller_autos/marca_bloc.dart';
import 'package:taller_autos/modelo_bloc.dart';
import 'package:taller_autos/pieza_bloc.dart';
import 'package:taller_autos/models.dart';

class CatalogoPiezasPage extends StatefulWidget {
  const CatalogoPiezasPage({super.key});

  @override
  State<CatalogoPiezasPage> createState() => _CatalogoPiezasPageState();
}

class _CatalogoPiezasPageState extends State<CatalogoPiezasPage> {
  final _marcaBloc = Modular.get<MarcaBloc>();
  final _modeloBloc = Modular.get<ModeloBloc>();
  final _piezaBloc = Modular.get<PiezaBloc>();

  Marca? _selectedMarca;
  Modelo? _selectedModelo;

  @override
  void initState() {
    super.initState();
    _marcaBloc.loadMarcas();
  }

  void _onMarcaChanged(Marca? marca) {
    setState(() {
      _selectedMarca = marca;
      _selectedModelo = null;
      _modeloBloc.modelos.clear(); // Clear previous models
    });
    if (marca != null) {
      _modeloBloc.loadModelos(marca.id!);
    }
  }

  void _onModeloChanged(Modelo? modelo) {
    setState(() {
      _selectedModelo = modelo;
    });
    if (modelo != null) {
      _piezaBloc.loadPiezas(modelo.id!);
    } else {
      // Clear parts if no model selected? Or show empty list
    }
  }

  void _showAddPiezaDialog() {
    if (_selectedModelo == null) return;

    final nombreCtrl = TextEditingController();
    final medidasCtrl = TextEditingController();
    final codigoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nueva Pieza para ${_selectedModelo!.nombre}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration:
                    const InputDecoration(labelText: 'Nombre de la Pieza'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: medidasCtrl,
                decoration:
                    const InputDecoration(labelText: 'Medidas (opcional)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: codigoCtrl,
                decoration:
                    const InputDecoration(labelText: 'Código (opcional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (nombreCtrl.text.isNotEmpty) {
                _piezaBloc.addPieza(
                  _selectedModelo!.id!,
                  nombreCtrl.text,
                  medidasCtrl.text,
                  codigo: codigoCtrl.text.isEmpty ? null : codigoCtrl.text,
                );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Piezas'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Modular.to.navigate('/'),
        ),
      ),
      body: Column(
        children: [
          // FILTROS
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Seleccione Vehículo',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),

                  // Marca Dropdown
                  AnimatedBuilder(
                    animation: _marcaBloc,
                    builder: (context, _) {
                      return DropdownButtonFormField<Marca>(
                        initialValue: _selectedMarca,
                        decoration: const InputDecoration(
                          labelText: 'Marca',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.directions_car),
                        ),
                        items: _marcaBloc.marcas
                            .map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(m.nombre),
                                ))
                            .toList(),
                        onChanged: _onMarcaChanged,
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Modelo Dropdown
                  AnimatedBuilder(
                    animation: _modeloBloc,
                    builder: (context, _) {
                      // Only enable if Brand selected
                      return DropdownButtonFormField<Modelo>(
                        initialValue: _selectedModelo,
                        decoration: const InputDecoration(
                          labelText: 'Modelo',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.settings),
                        ),
                        items: _modeloBloc.modelos
                            .map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text('${m.nombre} (${m.anio})'),
                                ))
                            .toList(),
                        onChanged:
                            _selectedMarca == null ? null : _onModeloChanged,
                        disabledHint:
                            const Text('Seleccione una marca primero'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: _selectedModelo == null
                ? const Center(
                    child: Text('Seleccione Marca y Modelo para ver piezas'))
                : AnimatedBuilder(
                    animation: _piezaBloc,
                    builder: (context, _) {
                      if (_piezaBloc.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (_piezaBloc.piezas.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.inventory_2_outlined,
                                  size: 64, color: Colors.grey),
                              Text(
                                  'No hay piezas registradas para este modelo'),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _piezaBloc.piezas.length,
                        itemBuilder: (context, index) {
                          final pieza = _piezaBloc.piezas[index];
                          return Card(
                            child: ListTile(
                              leading:
                                  const Icon(Icons.build, color: Colors.orange),
                              title: Text(pieza.nombre),
                              subtitle: Text(
                                  'Medidas: ${pieza.medidas} ${pieza.codigo != null ? '\nCódigo: ${pieza.codigo}' : ''}'),
                              isThreeLine: pieza.codigo != null,
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _piezaBloc.deletePieza(
                                      pieza.id!, _selectedModelo!.id!);
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _selectedModelo == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddPiezaDialog,
              icon: const Icon(Icons.add),
              label: const Text('Nueva Pieza'),
              backgroundColor: Colors.blue.shade800,
            ),
    );
  }
}
