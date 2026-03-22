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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Modular.to.navigate('/'),
        ),
        title: const Text('Facturas'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _filtroEstado = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'todas', child: Text('Todas')),
              const PopupMenuItem(
                  value: 'pendiente', child: Text('Pendientes')),
              const PopupMenuItem(value: 'pagada', child: Text('Pagadas')),
              const PopupMenuItem(
                  value: 'cancelada', child: Text('Canceladas')),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade700.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: BlocBuilder<FacturaBloc, FacturaState>(
            bloc: _bloc,
            builder: (context, state) {
              if (state is FacturaLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.purple.shade700,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Cargando facturas...',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (state is FacturaError) {
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
                          onPressed: () => _bloc.add(LoadFacturas()),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade700,
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

              if (state is FacturaLoaded) {
                var facturasFiltradas = state.facturas;
                if (_filtroEstado != 'todas') {
                  facturasFiltradas = facturasFiltradas
                      .where((f) => f.estado == _filtroEstado)
                      .toList();
                }

                if (facturasFiltradas.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _filtroEstado == 'todas'
                                ? 'No hay facturas registradas'
                                : 'No hay facturas con estado: $_filtroEstado',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
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
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.purple.shade700,
                            Colors.purple.shade900,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Pagado',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.purple.shade100,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${totalFacturado.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 40,
                                width: 1,
                                color: Colors.purple.shade500,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Pendiente',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.purple.shade100,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${totalPendiente.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _filtroEstado == 'todas'
                                  ? 'Todas (${facturasFiltradas.length})'
                                  : '${_filtroEstado.toUpperCase()} (${facturasFiltradas.length})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: facturasFiltradas.length,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: 8,
                        ),
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final factura = facturasFiltradas[index];
                          return _buildFacturaCard(context, factura, isMobile);
                        },
                      ),
                    ),
                  ],
                );
              }

              return const Center(child: Text('Estado desconocido'));
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Modular.to.navigate('/facturas/nueva'),
        backgroundColor: Colors.purple.shade700,
        icon: const Icon(Icons.add),
        label: isMobile ? const SizedBox.shrink() : const Text('Nueva Factura'),
      ),
    );
  }

  Widget _buildFacturaCard(
    BuildContext context,
    dynamic factura,
    bool isMobile,
  ) {
    final estadoColor = _getEstadoColor(factura.estado);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: estadoColor.withValues(alpha: 0.2),
        child: InkWell(
          onTap: () => _showFacturaMenu(context, factura),
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
                  estadoColor.withValues(alpha: 0.02),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: isMobile ? 50 : 60,
                    height: isMobile ? 50 : 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          estadoColor,
                          estadoColor.withValues(alpha: 0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: estadoColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.receipt,
                        color: Colors.white,
                        size: isMobile ? 24 : 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          factura.numeroFactura,
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
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd/MM/yyyy').format(factura.fecha),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: estadoColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            factura.estado.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: estadoColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${factura.total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.print, color: Colors.blue),
              ),
              title: const Text('Imprimir Factura'),
              onTap: () {
                Navigator.pop(context);
                _imprimirFactura(factura);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle, color: Colors.green),
              ),
              title: const Text('Marcar como pagada'),
              onTap: () {
                _bloc.add(UpdateFacturaEstado(factura.id!, 'pagada'));
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.pending, color: Colors.orange),
              ),
              title: const Text('Marcar como pendiente'),
              onTap: () {
                _bloc.add(UpdateFacturaEstado(factura.id!, 'pendiente'));
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cancel, color: Colors.red),
              ),
              title: const Text('Cancelar factura'),
              onTap: () {
                _bloc.add(UpdateFacturaEstado(factura.id!, 'cancelada'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
