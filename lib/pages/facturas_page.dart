import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';
import '../factura_bloc.dart';
import '../repositories.dart';
import '../utils/factura_pdf.dart';

class FacturasPage extends StatefulWidget {
  const FacturasPage({super.key});

  @override
  State<FacturasPage> createState() => _FacturasPageState();
}

class _FacturasPageState extends State<FacturasPage> {
  final FacturaBloc _bloc = Modular.get<FacturaBloc>();
  String _filtroEstado = 'todas';

  @override
  void initState() {
    super.initState();
    _bloc.add(LoadFacturas());
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pagada':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _imprimirFactura(dynamic factura) async {
    try {
      final clienteRepo = Modular.get<ClienteRepository>();
      final detalleRepo = Modular.get<DetalleFacturaRepository>();
      final servicioRepo = Modular.get<ServicioRepository>();
      final vehiculoRepo = Modular.get<VehiculoRepository>();

      final cliente = await clienteRepo.getById(factura.clienteId);
      final detalles = await detalleRepo.getByFacturaId(factura.id);
      
      if (cliente == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontró información del cliente'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Buscar el servicio en los detalles
      dynamic servicio;
      dynamic vehiculo;
      
      for (var detalle in detalles) {
        if (detalle.servicioId != null) {
          servicio = await servicioRepo.getById(detalle.servicioId!);
          if (servicio != null) {
            vehiculo = await vehiculoRepo.getById(servicio.vehiculoId);
            break;
          }
        }
      }

      await FacturaPdf.generarFactura(
        factura: factura,
        cliente: cliente,
        detalles: detalles,
        servicio: servicio,
        vehiculo: vehiculo,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar factura: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Modular.to.navigate('/'),
        ),
        title: const Text('Facturas'),
        backgroundColor: Colors.purple.shade700,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _filtroEstado = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'todas', child: Text('Todas')),
              const PopupMenuItem(value: 'pendiente', child: Text('Pendientes')),
              const PopupMenuItem(value: 'pagada', child: Text('Pagadas')),
              const PopupMenuItem(value: 'cancelada', child: Text('Canceladas')),
            ],
          ),
        ],
      ),
      body: BlocBuilder<FacturaBloc, FacturaState>(
        bloc: _bloc,
        builder: (context, state) {
          if (state is FacturaLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is FacturaError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _bloc.add(LoadFacturas()),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (state is FacturaLoaded) {
            var facturasFiltradas = state.facturas;
            if (_filtroEstado != 'todas') {
              facturasFiltradas = facturasFiltradas
                  .where((f) => f.estado == _filtroEstado)
                  .toList();
            }

            if (facturasFiltradas.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(_filtroEstado == 'todas' 
                        ? 'No hay facturas registradas'
                        : 'No hay facturas con estado: $_filtroEstado'),
                  ],
                ),
              );
            }

            final totalFacturado = facturasFiltradas
                .where((f) => f.estado == 'pagada')
                .fold<double>(0, (sum, f) => sum + f.total);
            
            final totalPendiente = facturasFiltradas
                .where((f) => f.estado == 'pendiente')
                .fold<double>(0, (sum, f) => sum + f.total);

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.purple.shade50,
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
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(_filtroEstado == 'todas' 
                          ? 'Todas (${facturasFiltradas.length})'
                          : '${_filtroEstado.toUpperCase()} (${facturasFiltradas.length})'),
                        backgroundColor: Colors.purple.shade100,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: facturasFiltradas.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final factura = facturasFiltradas[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getEstadoColor(factura.estado),
                            child: const Icon(Icons.receipt, color: Colors.white),
                          ),
                          title: Text(
                            factura.numeroFactura,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Cliente ID: ${factura.clienteId}'),
                              Text(DateFormat('dd/MM/yyyy').format(factura.fecha)),
                              Chip(
                                label: Text(
                                  factura.estado.toUpperCase(),
                                  style: const TextStyle(fontSize: 10, color: Colors.white),
                                ),
                                backgroundColor: _getEstadoColor(factura.estado),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${factura.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _showFacturaMenu(context, factura),
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
        onPressed: () => Modular.to.navigate('/facturas/nueva'),
        backgroundColor: Colors.purple.shade700,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFacturaMenu(BuildContext context, factura) {
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
              leading: const Icon(Icons.print, color: Colors.blue),
              title: const Text('Imprimir Factura'),
              onTap: () {
                Navigator.pop(context);
                _imprimirFactura(factura);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Marcar como pagada'),
              onTap: () {
                _bloc.add(UpdateFacturaEstado(factura.id!, 'pagada'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.pending, color: Colors.orange),
              title: const Text('Marcar como pendiente'),
              onTap: () {
                _bloc.add(UpdateFacturaEstado(factura.id!, 'pendiente'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Cancelar factura'),
              onTap: () {
                _bloc.add(UpdateFacturaEstado(factura.id!, 'cancelada'));
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context, factura.id!);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de eliminar esta factura?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _bloc.add(DeleteFactura(id));
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}