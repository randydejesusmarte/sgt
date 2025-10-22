import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';
import '../compra_bloc.dart';
import '../models.dart';

class ComprasPage extends StatefulWidget {
  const ComprasPage({super.key});

  @override
  State<ComprasPage> createState() => _ComprasPageState();
}

class _ComprasPageState extends State<ComprasPage> {
  final CompraBloc _bloc = Modular.get<CompraBloc>();

  @override
  void initState() {
    super.initState();
    _bloc.add(LoadCompras());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Modular.to.navigate('/'),
        ),
        title: const Text('Historial de Compras'),
        backgroundColor: Colors.green.shade700,
      ),
      body: BlocBuilder<CompraBloc, CompraState>(
        bloc: _bloc,
        builder: (context, state) {
          if (state is CompraLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CompraError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is CompraLoaded) {
            if (state.compras.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No hay compras registradas'),
                  ],
                ),
              );
            }

            final totalCompras = state.compras.fold<double>(
              0,
              (sum, compra) => sum + compra.total,
            );

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.green.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total en compras:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${totalCompras.toStringAsFixed(2)}',
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
                  child: ListView.builder(
                    itemCount: state.compras.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final compra = state.compras[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade700,
                            child: const Icon(Icons.shopping_bag, color: Colors.white),
                          ),
                          title: Text(
                            compra.item,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Cantidad: ${compra.cantidad}'),
                              Text('Precio unitario: \$${compra.precioUnitario.toStringAsFixed(2)}'),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(compra.fecha),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${compra.total.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
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

          return const Center(child: Text('Estado desconocido'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCompraDialog(context),
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCompraDialog(BuildContext context) {
    final itemController = TextEditingController();
    final cantidadController = TextEditingController();
    final precioController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Compra'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: itemController,
                  decoration: const InputDecoration(
                    labelText: 'Item',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: cantidadController,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: precioController,
                  decoration: const InputDecoration(
                    labelText: 'Precio unitario',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
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
                final cantidad = int.parse(cantidadController.text);
                final precio = double.parse(precioController.text);
                final compra = Compra(
                  servicioId: 1, // Temporal, en producción vincularlo a un servicio real
                  item: itemController.text,
                  cantidad: cantidad,
                  precioUnitario: precio,
                  total: cantidad * precio,
                  fecha: DateTime.now(),
                );
                _bloc.add(AddCompra(compra));
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