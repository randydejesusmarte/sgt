// Crear archivo lib/pages/inventario_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../models.dart';
import '../repositories.dart';

class InventarioPage extends StatefulWidget {
  const InventarioPage({super.key});

  @override
  State<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  final InventarioRepository _repository = Modular.get<InventarioRepository>();
  final MovimientoInventarioRepository _movimientoRepo = Modular.get<MovimientoInventarioRepository>();
  List<Inventario> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInventario();
  }

  Future<void> _loadInventario() async {
    setState(() => _isLoading = true);
    _items = await _repository.getAll();
    setState(() => _isLoading = false);
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
        title: const Text('Inventario'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInventario,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay artículos en el inventario',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _items.length,
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final stockBajo = item.cantidadDisponible <= 5;

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: stockBajo
                                ? Colors.red.withValues(alpha: 0.1)
                                : Colors.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.inventory_2,
                            color: stockBajo ? Colors.red : Colors.teal.shade700,
                          ),
                        ),
                        title: Text(
                          item.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Código: ${item.codigo}'),
                            if (item.categoria != null)
                              Text('Categoría: ${item.categoria}'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: stockBajo
                                        ? Colors.red
                                        : Colors.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Stock: ${item.cantidadDisponible}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (stockBajo) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.warning,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Stock Bajo',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${item.precioVenta.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.teal.shade700,
                              ),
                            ),
                            Text(
                              'Costo: \$${item.precioCompra.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _showItemMenu(item),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        backgroundColor: Colors.teal.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          isMobile ? '' : 'Agregar',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _showItemMenu(Inventario item) {
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
              leading: const Icon(Icons.add_circle, color: Colors.green),
              title: const Text('Entrada de Stock'),
              onTap: () {
                Navigator.pop(context);
                _showAjustarStockDialog(item, 'entrada');
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle, color: Colors.red),
              title: const Text('Salida de Stock'),
              onTap: () {
                Navigator.pop(context);
                _showAjustarStockDialog(item, 'salida');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                _showAddItemDialog(item: item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.blue),
              title: const Text('Ver Movimientos'),
              onTap: () {
                Navigator.pop(context);
                _showMovimientos(item);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(item.id!);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAjustarStockDialog(Inventario item, String tipo) {
    final cantidadController = TextEditingController();
    final motivoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tipo == 'entrada' ? 'Entrada de Stock' : 'Salida de Stock'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${item.nombre}\nStock actual: ${item.cantidadDisponible}',
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cantidadController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: motivoController,
                decoration: const InputDecoration(
                  labelText: 'Motivo (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (cantidadController.text.isNotEmpty) {
                final cantidad = int.parse(cantidadController.text);
                try {
                  await _repository.ajustarCantidad(
                    item.id!,
                    cantidad,
                    tipo,
                    motivo: motivoController.text.isEmpty
                        ? null
                        : motivoController.text,
                  );
                  Navigator.pop(context);
                  _loadInventario();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Stock actualizado: ${tipo == 'entrada' ? '+' : '-'}$cantidad'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: tipo == 'entrada' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog({Inventario? item}) {
    final isEdit = item != null;
    final codigoController = TextEditingController(text: item?.codigo ?? '');
    final nombreController = TextEditingController(text: item?.nombre ?? '');
    final descripcionController = TextEditingController(text: item?.descripcion ?? '');
    final cantidadController = TextEditingController(
      text: item?.cantidadDisponible.toString() ?? '0',
    );
    final precioCompraController = TextEditingController(
      text: item?.precioCompra.toStringAsFixed(2) ?? '',
    );
    final precioVentaController = TextEditingController(
      text: item?.precioVenta.toStringAsFixed(2) ?? '',
    );
    final categoriaController = TextEditingController(text: item?.categoria ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Editar Artículo' : 'Nuevo Artículo'),
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
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                  enabled: !isEdit, // No permitir cambiar código en edición
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: cantidadController,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad Inicial',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: precioCompraController,
                  decoration: const InputDecoration(
                    labelText: 'Precio de Compra *',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: precioVentaController,
                  decoration: const InputDecoration(
                    labelText: 'Precio de Venta *',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final inventarioItem = Inventario(
                  id: item?.id,
                  codigo: codigoController.text,
                  nombre: nombreController.text,
                  descripcion: descripcionController.text.isEmpty
                      ? null
                      : descripcionController.text,
                  cantidadDisponible: int.parse(cantidadController.text),
                  precioCompra: double.parse(precioCompraController.text),
                  precioVenta: double.parse(precioVentaController.text),
                  categoria: categoriaController.text.isEmpty
                      ? null
                      : categoriaController.text,
                  createdAt: item?.createdAt ?? DateTime.now(),
                );

                try {
                  if (isEdit) {
                    await _repository.update(inventarioItem);
                  } else {
                    await _repository.create(inventarioItem);
                  }
                  Navigator.pop(context);
                  _loadInventario();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit
                          ? 'Artículo actualizado'
                          : 'Artículo agregado al inventario'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
            ),
            child: Text(isEdit ? 'Actualizar' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  void _showMovimientos(Inventario item) async {
    final movimientos = await _movimientoRepo.getByInventarioId(item.id!);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Movimientos: ${item.nombre}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: movimientos.isEmpty
              ? const Center(child: Text('No hay movimientos registrados'))
              : ListView.builder(
                  itemCount: movimientos.length,
                  itemBuilder: (context, index) {
                    final mov = movimientos[index];
                    final isEntrada = mov.tipo == 'entrada';
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          isEntrada ? Icons.add_circle : Icons.remove_circle,
                          color: isEntrada ? Colors.green : Colors.red,
                        ),
                        title: Text(
                          '${isEntrada ? '+' : '-'}${mov.cantidad}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isEntrada ? Colors.green : Colors.red,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mov.tipo.toUpperCase()),
                            if (mov.referencia != null)
                              Text('Ref: ${mov.referencia}'),
                            if (mov.motivo != null) Text('Motivo: ${mov.motivo}'),
                            Text(
                              '${mov.fecha.day}/${mov.fecha.month}/${mov.fecha.year} ${mov.fecha.hour}:${mov.fecha.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
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
        content: const Text('¿Estás seguro de eliminar este artículo del inventario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _repository.delete(id);
              Navigator.pop(context);
              _loadInventario();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Artículo eliminado'),
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