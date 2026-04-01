import 'package:flutter/material.dart' show AlertDialog, Alignment, AppBar, BorderRadius, BouncingScrollPhysics, BoxDecoration, BoxShadow, BoxShape, BuildContext, Card, Center, CircularProgressIndicator, Colors, Column, Container, CrossAxisAlignment, EdgeInsets, ElevatedButton, Expanded, FloatingActionButton, FontWeight, Form, FormState, GlobalKey, Icon, IconButton, Icons, InkWell, InputDecoration, LinearGradient, ListView, MainAxisAlignment, MainAxisSize, MediaQuery, Navigator, Offset, OutlineInputBorder, Padding, RoundedRectangleBorder, Row, SafeArea, Scaffold, SingleChildScrollView, SizedBox, State, StatefulWidget, Text, TextAlign, TextButton, TextEditingController, TextFormField, TextInputType, TextStyle, Widget, showDialog;
import 'package:flutter_bloc/flutter_bloc.dart' show BlocBuilder;
import 'package:flutter_modular/flutter_modular.dart' show Modular;
import 'package:intl/intl.dart' show DateFormat;
import 'package:taller_autos/compra_bloc.dart' show AddCompra, CompraBloc, CompraError, CompraLoaded, CompraLoading, CompraState, LoadCompras;
import 'package:taller_autos/models.dart' show Compra;

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Modular.to.navigate('/'),
        ),
        title: const Text('Historial de Compras'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_add),
            tooltip: 'Crear Orden de Compra',
            onPressed: () => Modular.to.pushNamed('/orden-compra'),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade700.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: BlocBuilder<CompraBloc, CompraState>(
            bloc: _bloc,
            builder: (context, state) {
              if (state is CompraLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Cargando compras...',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (state is CompraError) {
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

              if (state is CompraLoaded) {
                if (state.compras.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay compras registradas',
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

                final totalCompras = state.compras.fold<double>(
                  0,
                  (sum, compra) => sum + compra.total,
                );

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
                            Colors.green.shade700,
                            Colors.green.shade900,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total en compras',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '\$${totalCompras.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: state.compras.length,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: 8,
                        ),
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final compra = state.compras[index];
                          return _buildCompraCard(context, compra, isMobile);
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
        onPressed: () => _showAddCompraDialog(context),
        backgroundColor: Colors.green.shade700,
        icon: const Icon(Icons.add),
        label: isMobile ? const SizedBox.shrink() : const Text('Nueva Compra'),
      ),
    );
  }

  Widget _buildCompraCard(
    BuildContext context,
    Compra compra,
    bool isMobile,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.green.withValues(alpha: 0.2),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.green.withValues(alpha: 0.1),
          highlightColor: Colors.green.withValues(alpha: 0.05),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.green.withValues(alpha: 0.02),
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
                          Colors.green.shade700,
                          Colors.green.shade900,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.shopping_bag,
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
                          compra.item,
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
                              DateFormat('dd/MM/yyyy HH:mm')
                                  .format(compra.fecha),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Cant: ${compra.cantidad}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '\$${compra.precioUnitario.toStringAsFixed(2)} c/u',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${compra.total.toStringAsFixed(2)}',
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

  void _showAddCompraDialog(BuildContext context) {
    final itemController = TextEditingController();
    final cantidadController = TextEditingController();
    final precioController = TextEditingController();
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
                    Colors.green.shade700,
                    Colors.green.shade900,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_shopping_cart,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Agregar Compra'),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: itemController,
                  decoration: InputDecoration(
                    labelText: 'Item',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.shopping_bag),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: cantidadController,
                  decoration: InputDecoration(
                    labelText: 'Cantidad',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: precioController,
                  decoration: InputDecoration(
                    labelText: 'Precio unitario',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixText: '\$',
                    prefixIcon: const Icon(Icons.attach_money),
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
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final cantidad = int.parse(cantidadController.text);
                final precio = double.parse(precioController.text);
                final compra = Compra(
                  servicioId:
                      1, // Temporal, en producción vincularlo a un servicio real
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
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
