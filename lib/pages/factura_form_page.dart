import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../models.dart';
import '../factura_bloc.dart';
import '../repositories.dart';
import '../utils/factura_pdf.dart';

class FacturaFormPage extends StatefulWidget {
  final int? servicioId;
  const FacturaFormPage({super.key, this.servicioId});

  @override
  State<FacturaFormPage> createState() => _FacturaFormPageState();
}

class _FacturaFormPageState extends State<FacturaFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final FacturaBloc _bloc;
  final ClienteRepository _clienteRepo = inject<ClienteRepository>();
  final ServicioRepository _servicioRepo = inject<ServicioRepository>();
  final VehiculoRepository _vehiculoRepo = inject<VehiculoRepository>();
  final InventarioRepository _inventarioRepo =
      inject<InventarioRepository>();
  bool _guardando = false;

  List<Cliente> _clientes = [];
  Cliente? _clienteSeleccionado;
  Servicio? _servicioSeleccionado;
  List<Servicio> _serviciosCliente = [];
  final List<DetalleFactura> _detalles = [];

  final double _tasaImpuesto = 18.0;
  double _descuento = 0.0;
  String _numeroFactura = '';
  String _tipoPago = 'contado'; // 'contado' | 'credito'
  bool _conComprobante = false;
  final TextEditingController _ncfController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('📱 FacturaFormPage: initState');
    _bloc = inject<FacturaBloc>();
    _loadData();
  }

  @override
  void dispose() {
    print('🗑️ FacturaFormPage: dispose');
    _ncfController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    print('📥 Cargando datos iniciales...');
    try {
      _clientes = await _clienteRepo.getAll();
      print('✅ Clientes cargados: ${_clientes.length}');

      final facturaRepo = inject<FacturaRepository>();
      _numeroFactura = await facturaRepo.getNextNumeroFactura();
      print('✅ Número de factura: $_numeroFactura');

      // Pre-cargar si viene de un Servicio específico
      if (widget.servicioId != null) {
        final servicio = await _servicioRepo.getById(widget.servicioId!);
        if (servicio != null) {
          final vehiculo = await _vehiculoRepo.getById(servicio.vehiculoId);
          if (vehiculo != null) {
            final cliente = await _clienteRepo.getById(vehiculo.clienteId);
            if (cliente != null) {
              _clienteSeleccionado = cliente;
              await _cargarServiciosCliente(cliente.id!);
              _servicioSeleccionado = servicio;

              _detalles.add(DetalleFactura(
                facturaId: 0,
                servicioId: servicio.id,
                descripcion:
                    'Servicio: ${servicio.descripcion} (${vehiculo.marca} ${vehiculo.modelo} - ${vehiculo.placa})',
                cantidad: 1,
                precioUnitario: servicio.costo,
                total: servicio.costo,
              ));
            }
          }
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('❌ Error al cargar datos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cargarServiciosCliente(int clienteId) async {
    print('🔍 Cargando servicios del cliente $clienteId');
    try {
      final vehiculos = await _vehiculoRepo.getByClienteId(clienteId);
      print('   Vehículos encontrados: ${vehiculos.length}');

      List<Servicio> servicios = [];
      for (var vehiculo in vehiculos) {
        final serviciosVehiculo =
            await _servicioRepo.getByVehiculoId(vehiculo.id!);
        final completados =
            serviciosVehiculo.where((s) => s.estado == 'completado').toList();
        print(
            '   Vehículo ${vehiculo.id}: ${completados.length} servicios completados');
        servicios.addAll(completados);
      }

      print('✅ Total servicios completados: ${servicios.length}');

      if (mounted) {
        setState(() {
          _serviciosCliente = servicios;
          _servicioSeleccionado = null;
        });
      }
    } catch (e) {
      print('❌ Error al cargar servicios: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar servicios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double get subtotal => _detalles.fold(0, (sum, d) => sum + d.total);
  double get impuesto => subtotal * (_tasaImpuesto / 100);
  double get total => subtotal + impuesto - _descuento;

  void _agregarItemInventario() async {
    print('➕ Agregando item del inventario');
    final inventarioItems = await _inventarioRepo.getDisponibles();
    print('   Items disponibles: ${inventarioItems.length}');

    if (inventarioItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay artículos disponibles en el inventario'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    Inventario? itemSeleccionado;
    final cantidadController = TextEditingController(text: '1');
    final precioController = TextEditingController();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agregar Item del Inventario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Inventario>(
                  decoration: const InputDecoration(
                    labelText: 'Artículo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory_2),
                  ),
                  items: inventarioItems.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item.nombre),
                          Text(
                            'Disponible: ${item.cantidadDisponible} | \$${item.precioVenta.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      itemSeleccionado = value;
                      if (value != null) {
                        precioController.text =
                            value.precioVenta.toStringAsFixed(2);
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cantidadController,
                  decoration: InputDecoration(
                    labelText: 'Cantidad',
                    border: const OutlineInputBorder(),
                    suffixText: itemSeleccionado != null
                        ? 'Disp: ${itemSeleccionado!.cantidadDisponible}'
                        : null,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: precioController,
                  decoration: const InputDecoration(
                    labelText: 'Precio unitario',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (itemSeleccionado != null &&
                    cantidadController.text.isNotEmpty &&
                    precioController.text.isNotEmpty) {
                  final cantidad = int.tryParse(cantidadController.text) ?? 0;
                  final precio = double.tryParse(precioController.text) ?? 0;

                  if (cantidad <= 0 || precio <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Cantidad y precio deben ser mayores a 0'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (cantidad > itemSeleccionado!.cantidadDisponible) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cantidad insuficiente en inventario'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  print(
                      '✅ Item agregado: ${itemSeleccionado!.nombre} x$cantidad');
                  setState(() {
                    _detalles.add(DetalleFactura(
                      facturaId: 0,
                      descripcion:
                          '${itemSeleccionado!.nombre} (Inventario: ${itemSeleccionado!.codigo})',
                      cantidad: cantidad,
                      precioUnitario: precio,
                      total: cantidad * precio,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  void _guardarFactura() async {
    print('\n🚀 ========== INICIANDO GUARDADO DE FACTURA ==========');

    if (_guardando) {
      print('⚠️ Ya se está guardando, ignorando clic');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      print('❌ Formulario no válido');
      return;
    }

    if (_clienteSeleccionado == null) {
      print('❌ No hay cliente seleccionado');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un cliente')),
      );
      return;
    }

    if (_servicioSeleccionado == null) {
      print('❌ No hay servicio seleccionado');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un servicio')),
      );
      return;
    }



    print('✅ Validaciones pasadas');
    print('   Cliente: ${_clienteSeleccionado!.nombre}');
    print('   Servicio: ${_servicioSeleccionado!.descripcion}');
    print('   Items inventario: ${_detalles.length}');

    setState(() => _guardando = true);

    try {
      // 1. Verificar inventario
      print('\n📦 Verificando inventario...');
      for (var i = 0; i < _detalles.length; i++) {
        final detalle = _detalles[i];
        if (detalle.descripcion.contains('Inventario:')) {
          final match =
              RegExp(r'Inventario:\s*([^)]+)').firstMatch(detalle.descripcion);
          if (match != null) {
            final codigo = match.group(1)?.trim();
            print('   Verificando item $i: $codigo');
            if (codigo != null) {
              final item = await _inventarioRepo.getByCodigo(codigo);
              if (item == null) {
                throw Exception('Item no encontrado: $codigo');
              }
              print(
                  '      Disponible: ${item.cantidadDisponible}, Necesario: ${detalle.cantidad}');
              if (item.cantidadDisponible < detalle.cantidad) {
                throw Exception(
                    'Cantidad insuficiente de ${item.nombre}. Disponible: ${item.cantidadDisponible}');
              }
            }
          }
        }
      }
      print('✅ Inventario verificado');

      // 2. Preparar datos
      print('\n📝 Preparando datos de factura...');
      final vehiculo =
          await _vehiculoRepo.getById(_servicioSeleccionado!.vehiculoId);
      print('   Vehículo: ${vehiculo?.marca} ${vehiculo?.modelo}');

      final detallesConServicio = [
        DetalleFactura(
          facturaId: 0,
          servicioId: _servicioSeleccionado!.id,
          descripcion:
              '${_servicioSeleccionado!.descripcion} - ${vehiculo?.marca ?? ''} ${vehiculo?.modelo ?? ''} (${vehiculo?.placa ?? ''})',
          cantidad: 1,
          precioUnitario: _servicioSeleccionado!.costo,
          total: _servicioSeleccionado!.costo,
        ),
        ..._detalles,
      ];

      final subtotalTotal = subtotal + _servicioSeleccionado!.costo;
      final impuestoTotal = subtotalTotal * (_tasaImpuesto / 100);
      final totalFinal = subtotalTotal + impuestoTotal - _descuento;

      print('   Subtotal: \$${subtotalTotal.toStringAsFixed(2)}');
      print('   Impuesto: \$${impuestoTotal.toStringAsFixed(2)}');
      print('   Descuento: \$${_descuento.toStringAsFixed(2)}');
      print('   Total: \$${totalFinal.toStringAsFixed(2)}');
      print('   Detalles totales: ${detallesConServicio.length}');

      final factura = Factura(
        clienteId: _clienteSeleccionado!.id!,
        numeroFactura: _numeroFactura,
        fecha: DateTime.now(),
        subtotal: subtotalTotal,
        impuesto: impuestoTotal,
        descuento: _descuento,
        total: totalFinal,
        estado: _tipoPago == 'credito' ? 'pendiente' : 'pagada',
        tipoPago: _tipoPago,
        conComprobante: _conComprobante,
        ncf: _conComprobante ? _ncfController.text.trim() : null,
      );

      // 3. Actualizar inventario ANTES de guardar
      print('\n📉 Actualizando inventario...');
      for (var i = 0; i < _detalles.length; i++) {
        final detalle = _detalles[i];
        if (detalle.descripcion.contains('Inventario:')) {
          final match =
              RegExp(r'Inventario:\s*([^)]+)').firstMatch(detalle.descripcion);
          if (match != null) {
            final codigo = match.group(1)?.trim();
            if (codigo != null) {
              final item = await _inventarioRepo.getByCodigo(codigo);
              if (item != null) {
                print('   Descontando ${detalle.cantidad} de ${item.nombre}');
                await _inventarioRepo.ajustarCantidad(
                  item.id!,
                  detalle.cantidad,
                  'salida',
                  referencia: 'Factura: $_numeroFactura',
                  motivo:
                      'Venta - Servicio: ${_servicioSeleccionado!.descripcion}',
                );
                print('   ✅ Inventario actualizado');
              }
            }
          }
        }
      }
      print('✅ Todo el inventario actualizado');

      // 4. Guardar factura con BLoC
      print('\n💾 Enviando al BLoC...');
      _bloc.add(AddFactura(factura, detallesConServicio));
      print('✅ Evento AddFactura enviado');
      print('⏳ Esperando respuesta del BLoC...');
    } catch (e, stackTrace) {
      print('\n❌ ERROR EN GUARDADO:');
      print('   Mensaje: $e');
      print('   Stack trace: $stackTrace');

      setState(() => _guardando = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }

    print('========== FIN GUARDADO DE FACTURA ==========\n');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FacturaBloc, FacturaState>(
      bloc: _bloc,
      listener: (context, state) {
        if (state is FacturaLoaded) {
          setState(() => _guardando = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Factura guardada exitosamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          Future.delayed(const Duration(milliseconds: 300), () async {
            if (mounted) {
              final bool? es80mm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Row(
                    children: [
                      Icon(Icons.print, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text('Imprimir Factura'),
                    ],
                  ),
                  content: const Text('¿Desea imprimir la factura generada?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text('No imprimir'),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.insert_drive_file, size: 16),
                      label: const Text('Media Hoja (6x8)'),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.receipt, size: 16),
                      label: const Text('Térmica 80mm'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );

              if (es80mm != null && state.facturas.isNotEmpty) {
                final ultimaFactura = state.facturas.first;
                final vehiculo = await _vehiculoRepo.getById(_servicioSeleccionado?.vehiculoId ?? 0);
                await FacturaPdf.generarFactura(
                  factura: ultimaFactura,
                  cliente: _clienteSeleccionado!,
                  detalles: [
                    DetalleFactura(
                      facturaId: ultimaFactura.id ?? 0,
                      servicioId: _servicioSeleccionado?.id,
                      descripcion: '${_servicioSeleccionado?.descripcion ?? ''} - ${vehiculo?.marca ?? ''} ${vehiculo?.modelo ?? ''}',
                      cantidad: 1,
                      precioUnitario: _servicioSeleccionado?.costo ?? 0,
                      total: _servicioSeleccionado?.costo ?? 0,
                    ),
                    ..._detalles,
                  ],
                  servicio: _servicioSeleccionado,
                  vehiculo: vehiculo,
                  esImpresora80mm: es80mm,
                );
              }

              if (mounted) {
                context.navigate('/facturas');
              }
            }
          });
        } else if (state is FacturaError) {
          setState(() => _guardando = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: ${state.message}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            print('🔙 Volviendo a /facturas');
            context.navigate('/facturas');
          },
        ),
        title: const Text('Nueva Factura'),
        backgroundColor: Colors.purple.shade700,
        elevation: 0,
        centerTitle: true,
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 4,
                        shadowColor: Colors.purple.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                Colors.purple.withValues(alpha: 0.05),
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.purple
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.receipt_long,
                                        color: Colors.purple.shade700,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Factura: $_numeroFactura',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                                          style: TextStyle(
                                              color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Card de Condiciones de Facturación (Pago & NCF)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Condiciones de Facturación',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade900,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Tipo de Pago (Contado / Crédito)
                              Row(
                                children: [
                                  Expanded(
                                    child: SegmentedButton<String>(
                                      segments: const [
                                        ButtonSegment<String>(
                                          value: 'contado',
                                          label: Text('Al Contado'),
                                          icon: Icon(Icons.payments_outlined),
                                        ),
                                        ButtonSegment<String>(
                                          value: 'credito',
                                          label: Text('A Crédito'),
                                          icon: Icon(Icons.credit_score_outlined),
                                        ),
                                      ],
                                      selected: {_tipoPago},
                                      onSelectionChanged: (newSelection) {
                                        setState(() {
                                          _tipoPago = newSelection.first;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              // Comprobante Fiscal Switch & NCF
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Comprobante Fiscal (NCF)',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  _conComprobante
                                      ? 'Factura con Valor Fiscal'
                                      : 'Sin Comprobante Fiscal (Consumidor Final)',
                                  style: TextStyle(
                                    color: _conComprobante
                                        ? Colors.green.shade700
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                value: _conComprobante,
                                activeTrackColor: Colors.purple.shade700,
                                onChanged: (val) {
                                  setState(() {
                                    _conComprobante = val;
                                    if (val && _ncfController.text.trim().isEmpty) {
                                      _ncfController.text =
                                          'B01${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
                                    }
                                  });
                                },
                              ),
                              if (_conComprobante) ...[
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _ncfController,
                                  decoration: InputDecoration(
                                    labelText: 'Número NCF *',
                                    hintText: 'Ej. B0100000001',
                                    prefixIcon: const Icon(Icons.receipt),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator: (val) {
                                    if (_conComprobante &&
                                        (val == null || val.trim().isEmpty)) {
                                      return 'Ingrese el NCF';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Cliente>(
                        decoration: InputDecoration(
                          labelText: 'Cliente *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.purple.shade700, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.person),
                        ),
                        items: _clientes.map((cliente) {
                          return DropdownMenuItem(
                            value: cliente,
                            child: Text(cliente.nombre),
                          );
                        }).toList(),
                        onChanged: (value) {
                          print('Cliente seleccionado: ${value?.nombre}');
                          setState(() {
                            _clienteSeleccionado = value;
                            _servicioSeleccionado = null;
                            _serviciosCliente = [];
                          });
                          if (value != null) {
                            _cargarServiciosCliente(value.id!);
                          }
                        },
                        validator: (value) =>
                            value == null ? 'Selecciona un cliente' : null,
                      ),
                      const SizedBox(height: 16),
                      if (_clienteSeleccionado != null) ...[
                        DropdownButtonFormField<Servicio>(
                          decoration: InputDecoration(
                            labelText: 'Servicio Completado *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.purple.shade700, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.build),
                          ),
                          initialValue: _servicioSeleccionado,
                          items: _serviciosCliente.map((servicio) {
                            return DropdownMenuItem(
                              value: servicio,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(servicio.descripcion),
                                  Text(
                                    '\$${servicio.costo.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            print(
                                'Servicio seleccionado: ${value?.descripcion}');
                            setState(() => _servicioSeleccionado = value);
                          },
                          validator: (value) =>
                              value == null ? 'Selecciona un servicio' : null,
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (_servicioSeleccionado != null) ...[
                        Card(
                          color: Colors.blue.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Servicio Seleccionado:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(_servicioSeleccionado!.descripcion),
                                Text(
                                  'Costo: \$${_servicioSeleccionado!.costo.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Items Utilizados',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _agregarItemInventario,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Agregar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_detalles.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                    'No hay items agregados del inventario'),
                              ),
                            ),
                          )
                        else
                          ..._detalles.asMap().entries.map((entry) {
                            final index = entry.key;
                            final detalle = entry.value;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(detalle.descripcion),
                                subtitle: Text(
                                  'Cant: ${detalle.cantidad} × \$${detalle.precioUnitario.toStringAsFixed(2)}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '\$${detalle.total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () {
                                        print('🗑️ Eliminando item $index');
                                        setState(
                                            () => _detalles.removeAt(index));
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 24),
                        Card(
                          color: Colors.purple.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Servicio:'),
                                    Text(
                                      '\$${_servicioSeleccionado!.costo.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Items:'),
                                    Text(
                                      '\$${subtotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Subtotal:'),
                                    Text(
                                      '\$${(subtotal + _servicioSeleccionado!.costo).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Impuesto ($_tasaImpuesto%):'),
                                    Text(
                                      '\$${((subtotal + _servicioSeleccionado!.costo) * (_tasaImpuesto / 100)).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Descuento:'),
                                    SizedBox(
                                      width: 100,
                                      child: TextField(
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          prefixText: '\$',
                                          isDense: true,
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _descuento =
                                                double.tryParse(value) ?? 0;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'TOTAL:',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '\$${((subtotal + _servicioSeleccionado!.costo) + ((subtotal + _servicioSeleccionado!.costo) * (_tasaImpuesto / 100)) - _descuento).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_servicioSeleccionado != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _guardarFactura,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: Colors.purple.withValues(alpha: 0.4),
                    ),
                    child: _guardando
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Guardando...',
                                style: const TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                            ],
                          )
                        : const Text(
                            'Guardar Factura',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
