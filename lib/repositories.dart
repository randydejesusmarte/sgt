import 'database_helper.dart';
import 'models.dart';

// ========== REPOSITORIO DE CLIENTES ==========

class ClienteRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> create(Cliente cliente) async {
    final db = await _db.database;
    return await db.insert('clientes', cliente.toMap());
  }

  Future<List<Cliente>> getAll() async {
    final db = await _db.database;
    final result = await db.query('clientes', orderBy: 'created_at DESC');
    return result.map((map) => Cliente.fromMap(map)).toList();
  }

  Future<Cliente?> getById(int id) async {
    final db = await _db.database;
    final result = await db.query('clientes', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Cliente.fromMap(result.first);
  }

  Future<int> update(Cliente cliente) async {
    final db = await _db.database;
    return await db.update('clientes', cliente.toMap(), where: 'id = ?', whereArgs: [cliente.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete('clientes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> searchClientes(String query) async {
    final db = await _db.database;
    return await db.query(
      'clientes',
      where: 'nombre LIKE ? OR telefono LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
  }
}

// ========== REPOSITORIO DE VEHÍCULOS ==========

class VehiculoRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> create(Vehiculo vehiculo) async {
    final db = await _db.database;
    return await db.insert('vehiculos', vehiculo.toMap());
  }

  Future<List<Vehiculo>> getByClienteId(int clienteId) async {
    final db = await _db.database;
    final result = await db.query('vehiculos', where: 'cliente_id = ?', whereArgs: [clienteId]);
    return result.map((map) => Vehiculo.fromMap(map)).toList();
  }

  Future<Vehiculo?> getById(int id) async {
    final db = await _db.database;
    final result = await db.query('vehiculos', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Vehiculo.fromMap(result.first);
  }

  Future<int> update(Vehiculo vehiculo) async {
    final db = await _db.database;
    return await db.update('vehiculos', vehiculo.toMap(), where: 'id = ?', whereArgs: [vehiculo.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete('vehiculos', where: 'id = ?', whereArgs: [id]);
  }
}

// ========== REPOSITORIO DE EMPLEADOS ==========

class EmpleadoRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> create(Empleado empleado) async {
    final db = await _db.database;
    return await db.insert('empleados', empleado.toMap());
  }

  Future<List<Empleado>> getAll() async {
    final db = await _db.database;
    final result = await db.query('empleados', orderBy: 'nombre ASC');
    return result.map((map) => Empleado.fromMap(map)).toList();
  }

  Future<List<Empleado>> getActivos() async {
    final db = await _db.database;
    final result = await db.query('empleados', 
      where: 'activo = ?', 
      whereArgs: [1], 
      orderBy: 'nombre ASC'
    );
    return result.map((map) => Empleado.fromMap(map)).toList();
  }

  Future<Empleado?> getById(int id) async {
    final db = await _db.database;
    final result = await db.query('empleados', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Empleado.fromMap(result.first);
  }

  Future<int> update(Empleado empleado) async {
    final db = await _db.database;
    return await db.update('empleados', empleado.toMap(), 
      where: 'id = ?', 
      whereArgs: [empleado.id]
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete('empleados', where: 'id = ?', whereArgs: [id]);
  }
}

// ========== REPOSITORIO DE SERVICIOS ==========

class ServicioRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> create(Servicio servicio) async {
    final db = await _db.database;
    return await db.insert('servicios', servicio.toMap());
  }

  Future<List<Servicio>> getAll() async {
    final db = await _db.database;
    final result = await db.query('servicios', orderBy: 'fecha DESC');
    return result.map((map) => Servicio.fromMap(map)).toList();
  }

  Future<List<Servicio>> getByVehiculoId(int vehiculoId) async {
    final db = await _db.database;
    final result = await db.query('servicios', where: 'vehiculo_id = ?', whereArgs: [vehiculoId], orderBy: 'fecha DESC');
    return result.map((map) => Servicio.fromMap(map)).toList();
  }

  Future<Servicio?> getById(int id) async {
    final db = await _db.database;
    final result = await db.query('servicios', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Servicio.fromMap(result.first);
  }

  Future<int> update(Servicio servicio) async {
    final db = await _db.database;
    return await db.update('servicios', servicio.toMap(), where: 'id = ?', whereArgs: [servicio.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete('servicios', where: 'id = ?', whereArgs: [id]);
  }
}

// ========== REPOSITORIO DE COMPRAS ==========

class CompraRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> create(Compra compra) async {
    final db = await _db.database;
    return await db.insert('compras', compra.toMap());
  }

  Future<List<Compra>> getAll() async {
    final db = await _db.database;
    final result = await db.query('compras', orderBy: 'fecha DESC');
    return result.map((map) => Compra.fromMap(map)).toList();
  }

  Future<List<Compra>> getByServicioId(int servicioId) async {
    final db = await _db.database;
    final result = await db.query('compras', where: 'servicio_id = ?', whereArgs: [servicioId]);
    return result.map((map) => Compra.fromMap(map)).toList();
  }

  Future<int> update(Compra compra) async {
    final db = await _db.database;
    return await db.update('compras', compra.toMap(), where: 'id = ?', whereArgs: [compra.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete('compras', where: 'id = ?', whereArgs: [id]);
  }
}

// ========== REPOSITORIO DE FACTURAS ==========

class FacturaRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> create(Factura factura) async {
    final db = await _db.database;
    return await db.insert('facturas', factura.toMap());
  }

  Future<List<Factura>> getAll() async {
    final db = await _db.database;
    final result = await db.query('facturas', orderBy: 'fecha DESC');
    return result.map((map) => Factura.fromMap(map)).toList();
  }

  Future<List<Factura>> getByClienteId(int clienteId) async {
    final db = await _db.database;
    final result = await db.query('facturas', where: 'cliente_id = ?', whereArgs: [clienteId], orderBy: 'fecha DESC');
    return result.map((map) => Factura.fromMap(map)).toList();
  }

  Future<Factura?> getById(int id) async {
    final db = await _db.database;
    final result = await db.query('facturas', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Factura.fromMap(result.first);
  }

  Future<int> update(Factura factura) async {
    final db = await _db.database;
    return await db.update('facturas', factura.toMap(), where: 'id = ?', whereArgs: [factura.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete('facturas', where: 'id = ?', whereArgs: [id]);
  }

  Future<String> getNextNumeroFactura() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT MAX(CAST(SUBSTR(numero_factura, 5) AS INTEGER)) as max_num FROM facturas WHERE numero_factura LIKE "FAC-%"');
    final maxNum = result.first['max_num'] as int? ?? 0;
    return 'FAC-${(maxNum + 1).toString().padLeft(6, '0')}';
  }
}

// ========== REPOSITORIO DE DETALLE DE FACTURAS ==========

class DetalleFacturaRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> create(DetalleFactura detalle) async {
    final db = await _db.database;
    return await db.insert('detalle_factura', detalle.toMap());
  }

  Future<List<DetalleFactura>> getByFacturaId(int facturaId) async {
    final db = await _db.database;
    final result = await db.query('detalle_factura', where: 'factura_id = ?', whereArgs: [facturaId]);
    return result.map((map) => DetalleFactura.fromMap(map)).toList();
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete('detalle_factura', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteByFacturaId(int facturaId) async {
    final db = await _db.database;
    return await db.delete('detalle_factura', where: 'factura_id = ?', whereArgs: [facturaId]);
  }
}

// ========== REPOSITORIO DE INVENTARIO ==========

class InventarioRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> create(Inventario item) async {
    final db = await _db.database;
    return await db.insert('inventario', item.toMap());
  }

  Future<List<Inventario>> getAll() async {
    final db = await _db.database;
    final result = await db.query('inventario', orderBy: 'nombre ASC');
    return result.map((map) => Inventario.fromMap(map)).toList();
  }

  Future<List<Inventario>> getDisponibles() async {
    final db = await _db.database;
    final result = await db.query(
      'inventario',
      where: 'cantidad_disponible > ?',
      whereArgs: [0],
      orderBy: 'nombre ASC',
    );
    return result.map((map) => Inventario.fromMap(map)).toList();
  }

  Future<Inventario?> getById(int id) async {
    final db = await _db.database;
    final result = await db.query('inventario', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Inventario.fromMap(result.first);
  }

  Future<Inventario?> getByCodigo(String codigo) async {
    final db = await _db.database;
    final result = await db.query('inventario', where: 'codigo = ?', whereArgs: [codigo]);
    if (result.isEmpty) return null;
    return Inventario.fromMap(result.first);
  }

  Future<int> update(Inventario item) async {
    final db = await _db.database;
    return await db.update('inventario', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete('inventario', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> ajustarCantidad(int id, int cantidad, String tipo, {String? referencia, String? motivo}) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      // Actualizar cantidad en inventario
      final item = await getById(id);
      if (item != null) {
        int nuevaCantidad = item.cantidadDisponible;
        if (tipo == 'entrada') {
          nuevaCantidad += cantidad;
        } else if (tipo == 'salida') {
          nuevaCantidad -= cantidad;
          if (nuevaCantidad < 0) {
            throw Exception('Cantidad insuficiente en inventario');
          }
        }

        await txn.update(
          'inventario',
          {'cantidad_disponible': nuevaCantidad},
          where: 'id = ?',
          whereArgs: [id],
        );

        // Registrar movimiento
        await txn.insert('movimientos_inventario', {
          'inventario_id': id,
          'tipo': tipo,
          'cantidad': cantidad,
          'referencia': referencia,
          'motivo': motivo,
          'fecha': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> buscar(String query) async {
    final db = await _db.database;
    return await db.query(
      'inventario',
      where: 'nombre LIKE ? OR codigo LIKE ? OR descripcion LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
  }
}

// ========== REPOSITORIO DE MOVIMIENTOS DE INVENTARIO ==========

class MovimientoInventarioRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> create(MovimientoInventario movimiento) async {
    final db = await _db.database;
    return await db.insert('movimientos_inventario', movimiento.toMap());
  }

  Future<List<MovimientoInventario>> getByInventarioId(int inventarioId) async {
    final db = await _db.database;
    final result = await db.query(
      'movimientos_inventario',
      where: 'inventario_id = ?',
      whereArgs: [inventarioId],
      orderBy: 'fecha DESC',
    );
    return result.map((map) => MovimientoInventario.fromMap(map)).toList();
  }

  Future<List<MovimientoInventario>> getAll() async {
    final db = await _db.database;
    final result = await db.query('movimientos_inventario', orderBy: 'fecha DESC');
    return result.map((map) => MovimientoInventario.fromMap(map)).toList();
  }

  Future<List<MovimientoInventario>> getByFecha(DateTime desde, DateTime hasta) async {
    final db = await _db.database;
    final result = await db.query(
      'movimientos_inventario',
      where: 'fecha BETWEEN ? AND ?',
      whereArgs: [desde.toIso8601String(), hasta.toIso8601String()],
      orderBy: 'fecha DESC',
    );
    return result.map((map) => MovimientoInventario.fromMap(map)).toList();
  }

  Future<List<MovimientoInventario>> getByTipo(String tipo) async {
    final db = await _db.database;
    final result = await db.query(
      'movimientos_inventario',
      where: 'tipo = ?',
      whereArgs: [tipo],
      orderBy: 'fecha DESC',
    );
    return result.map((map) => MovimientoInventario.fromMap(map)).toList();
  }
}