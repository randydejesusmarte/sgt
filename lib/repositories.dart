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
    return await db.update('clientes', cliente.toMap(),
        where: 'id = ?', whereArgs: [cliente.id]);
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
    final result = await db
        .query('vehiculos', where: 'cliente_id = ?', whereArgs: [clienteId]);
    return result.map((map) => Vehiculo.fromMap(map)).toList();
  }

  Future<Vehiculo?> getById(int id) async {
    final db = await _db.database;
    final result =
        await db.query('vehiculos', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Vehiculo.fromMap(result.first);
  }

  Future<int> update(Vehiculo vehiculo) async {
    final db = await _db.database;
    return await db.update('vehiculos', vehiculo.toMap(),
        where: 'id = ?', whereArgs: [vehiculo.id]);
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
        where: 'activo = ?', whereArgs: [1], orderBy: 'nombre ASC');
    return result.map((map) => Empleado.fromMap(map)).toList();
  }

  Future<Empleado?> getById(int id) async {
    final db = await _db.database;
    final result =
        await db.query('empleados', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Empleado.fromMap(result.first);
  }

  Future<int> update(Empleado empleado) async {
    final db = await _db.database;
    return await db.update('empleados', empleado.toMap(),
        where: 'id = ?', whereArgs: [empleado.id]);
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
    final result = await db.query('servicios',
        where: 'vehiculo_id = ?',
        whereArgs: [vehiculoId],
        orderBy: 'fecha DESC');
    return result.map((map) => Servicio.fromMap(map)).toList();
  }

  Future<Servicio?> getById(int id) async {
    final db = await _db.database;
    final result =
        await db.query('servicios', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Servicio.fromMap(result.first);
  }

  Future<int> update(Servicio servicio) async {
    final db = await _db.database;
    return await db.update('servicios', servicio.toMap(),
        where: 'id = ?', whereArgs: [servicio.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete('servicios', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getServiciosConDetalles() async {
    final db = await _db.database;
    return await db.rawQuery('''
      SELECT 
        s.id as s_id, s.vehiculo_id as s_vehiculo_id, s.empleado_id as s_empleado_id, 
        s.descripcion as s_descripcion, s.costo as s_costo, s.fecha as s_fecha, 
        s.estado as s_estado, s.notas as s_notas,
        v.id as v_id, v.cliente_id as v_cliente_id, v.marca as v_marca, v.modelo as v_modelo, 
        v.anio as v_anio, v.placa as v_placa,
        c.id as c_id, c.nombre as c_nombre, c.telefono as c_telefono, c.email as c_email, 
        c.direccion as c_direccion, c.created_at as c_created_at,
        e.id as e_id, e.nombre as e_nombre, e.telefono as e_telefono, 
        e.especialidad as e_especialidad, e.activo as e_activo, e.created_at as e_created_at
      FROM servicios s
      INNER JOIN vehiculos v ON s.vehiculo_id = v.id
      INNER JOIN clientes c ON v.cliente_id = c.id
      LEFT JOIN empleados e ON s.empleado_id = e.id
      ORDER BY s.fecha DESC
    ''');
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
    final result = await db
        .query('compras', where: 'servicio_id = ?', whereArgs: [servicioId]);
    return result.map((map) => Compra.fromMap(map)).toList();
  }

  Future<int> update(Compra compra) async {
    final db = await _db.database;
    return await db.update('compras', compra.toMap(),
        where: 'id = ?', whereArgs: [compra.id]);
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

  Future<int> createConDetalles(Factura factura, List<DetalleFactura> detalles) async {
    final db = await _db.database;
    return await db.transaction((txn) async {
      final facturaId = await txn.insert('facturas', factura.toMap());
      for (var detalle in detalles) {
        final detalleToCreate = DetalleFactura(
          facturaId: facturaId,
          servicioId: detalle.servicioId,
          descripcion: detalle.descripcion,
          cantidad: detalle.cantidad,
          precioUnitario: detalle.precioUnitario,
          total: detalle.total,
        );
        await txn.insert('detalle_factura', detalleToCreate.toMap());
      }
      return facturaId;
    });
  }

  Future<List<Factura>> getAll() async {
    final db = await _db.database;
    final result = await db.query('facturas', orderBy: 'fecha DESC');
    return result.map((map) => Factura.fromMap(map)).toList();
  }

  Future<List<Factura>> getByClienteId(int clienteId) async {
    final db = await _db.database;
    final result = await db.query('facturas',
        where: 'cliente_id = ?', whereArgs: [clienteId], orderBy: 'fecha DESC');
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
    return await db.update('facturas', factura.toMap(),
        where: 'id = ?', whereArgs: [factura.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete('facturas', where: 'id = ?', whereArgs: [id]);
  }

  Future<String> getNextNumeroFactura() async {
    final db = await _db.database;
    final result = await db.rawQuery(
        "SELECT MAX(CAST(SUBSTR(numero_factura, 5) AS INTEGER)) as max_num FROM facturas WHERE numero_factura LIKE 'FAC-%'");
    final maxNum =
        result.isNotEmpty ? (result.first['max_num'] as int? ?? 0) : 0;
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
    final result = await db.query('detalle_factura',
        where: 'factura_id = ?', whereArgs: [facturaId]);
    return result.map((map) => DetalleFactura.fromMap(map)).toList();
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete('detalle_factura', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteByFacturaId(int facturaId) async {
    final db = await _db.database;
    return await db.delete('detalle_factura',
        where: 'factura_id = ?', whereArgs: [facturaId]);
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
    final result =
        await db.query('inventario', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Inventario.fromMap(result.first);
  }

  Future<Inventario?> getByCodigo(String codigo) async {
    final db = await _db.database;
    final result =
        await db.query('inventario', where: 'codigo = ?', whereArgs: [codigo]);
    if (result.isEmpty) return null;
    return Inventario.fromMap(result.first);
  }

  Future<int> update(Inventario item) async {
    final db = await _db.database;
    return await db.update('inventario', item.toMap(),
        where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete('inventario', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> ajustarCantidad(int id, int cantidad, String tipo,
      {String? referencia, String? motivo}) async {
    final db = await _db.database;

    // IMPORTANTE: Obtener el item ANTES de la transacción
    final result =
        await db.query('inventario', where: 'id = ?', whereArgs: [id]);

    if (result.isEmpty) {
      throw Exception('Item de inventario no encontrado');
    }

    final item = Inventario.fromMap(result.first);

    await db.transaction((txn) async {
      // Calcular nueva cantidad
      int nuevaCantidad = item.cantidadDisponible;
      if (tipo == 'entrada') {
        nuevaCantidad += cantidad;
      } else if (tipo == 'salida') {
        nuevaCantidad -= cantidad;
        if (nuevaCantidad < 0) {
          throw Exception('Cantidad insuficiente en inventario');
        }
      }

      // Actualizar cantidad en inventario usando la transacción
      await txn.update(
        'inventario',
        {'cantidad_disponible': nuevaCantidad},
        where: 'id = ?',
        whereArgs: [id],
      );

      // Registrar movimiento usando la transacción
      await txn.insert('movimientos_inventario', {
        'inventario_id': id,
        'tipo': tipo,
        'cantidad': cantidad,
        'referencia': referencia,
        'motivo': motivo,
        'fecha': DateTime.now().toIso8601String(),
      });
    });

    print('   ✅ Inventario actualizado correctamente');
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
    final result =
        await db.query('movimientos_inventario', orderBy: 'fecha DESC');
    return result.map((map) => MovimientoInventario.fromMap(map)).toList();
  }

  Future<List<MovimientoInventario>> getByFecha(
      DateTime desde, DateTime hasta) async {
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

// ========== REPOSITORIO DE SERVICIOS PREDEFINIDOS ==========

class ServicioPredefinidoRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> create(ServicioPredefinido servicio) async {
    final db = await _db.database;
    return await db.insert('servicios_predefinidos', servicio.toMap());
  }

  Future<List<ServicioPredefinido>> getAll() async {
    final db = await _db.database;
    final result =
        await db.query('servicios_predefinidos', orderBy: 'nombre ASC');
    return result.map((map) => ServicioPredefinido.fromMap(map)).toList();
  }

  Future<List<ServicioPredefinido>> getActivos() async {
    final db = await _db.database;
    final result = await db.query(
      'servicios_predefinidos',
      where: 'activo = ?',
      whereArgs: [1],
      orderBy: 'nombre ASC',
    );
    return result.map((map) => ServicioPredefinido.fromMap(map)).toList();
  }

  Future<List<ServicioPredefinido>> getByCategoria(String categoria) async {
    final db = await _db.database;
    final result = await db.query(
      'servicios_predefinidos',
      where: 'categoria = ? AND activo = ?',
      whereArgs: [categoria, 1],
      orderBy: 'nombre ASC',
    );
    return result.map((map) => ServicioPredefinido.fromMap(map)).toList();
  }

  Future<ServicioPredefinido?> getById(int id) async {
    final db = await _db.database;
    final result = await db
        .query('servicios_predefinidos', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return ServicioPredefinido.fromMap(result.first);
  }

  Future<ServicioPredefinido?> getByCodigo(String codigo) async {
    final db = await _db.database;
    final result = await db.query('servicios_predefinidos',
        where: 'codigo = ?', whereArgs: [codigo]);
    if (result.isEmpty) return null;
    return ServicioPredefinido.fromMap(result.first);
  }

  Future<int> update(ServicioPredefinido servicio) async {
    final db = await _db.database;
    return await db.update('servicios_predefinidos', servicio.toMap(),
        where: 'id = ?', whereArgs: [servicio.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db
        .delete('servicios_predefinidos', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<String>> getCategorias() async {
    final db = await _db.database;
    final result = await db.rawQuery(
        'SELECT DISTINCT categoria FROM servicios_predefinidos WHERE categoria IS NOT NULL ORDER BY categoria');
    return result.map((row) => row['categoria'] as String).toList();
  }

  Future<List<ServicioPredefinido>> buscar(String query) async {
    final db = await _db.database;
    final result = await db.query(
      'servicios_predefinidos',
      where: 'nombre LIKE ? OR codigo LIKE ? OR descripcion LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'nombre ASC',
    );
    return result.map((map) => ServicioPredefinido.fromMap(map)).toList();
  }
}

// ========== REPOSITORIOS PARA SISTEMA DE ORDENES ==========

class MarcaRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> create(Marca marca) async {
    final db = await _db.database;
    return await db.insert('marcas', marca.toMap());
  }

  Future<List<Marca>> getAll() async {
    final db = await _db.database;
    final result = await db.query('marcas', orderBy: 'nombre ASC');
    return result.map((map) => Marca.fromMap(map)).toList();
  }

  Future<Marca?> getById(int id) async {
    final db = await _db.database;
    final result = await db.query('marcas', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Marca.fromMap(result.first);
  }

  Future<List<Marca>> search(String query) async {
    final db = await _db.database;
    final result = await db.query('marcas',
        where: 'nombre LIKE ?', whereArgs: ['%$query%'], orderBy: 'nombre ASC');
    return result.map((map) => Marca.fromMap(map)).toList();
  }

  Future<int> update(Marca marca) async {
    final db = await _db.database;
    return await db.update('marcas', marca.toMap(),
        where: 'id = ?', whereArgs: [marca.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete('marcas', where: 'id = ?', whereArgs: [id]);
  }
}

class ModeloRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> create(Modelo modelo) async {
    final db = await _db.database;
    return await db.insert('modelos', modelo.toMap());
  }

  Future<List<Modelo>> getByMarcaId(int marcaId) async {
    final db = await _db.database;
    final result = await db.query('modelos',
        where: 'marca_id = ?', whereArgs: [marcaId], orderBy: 'nombre ASC');
    return result.map((map) => Modelo.fromMap(map)).toList();
  }

  Future<Modelo?> getById(int id) async {
    final db = await _db.database;
    final result = await db.query('modelos', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Modelo.fromMap(result.first);
  }

  Future<int> update(Modelo modelo) async {
    final db = await _db.database;
    return await db.update('modelos', modelo.toMap(),
        where: 'id = ?', whereArgs: [modelo.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete('modelos', where: 'id = ?', whereArgs: [id]);
  }
}

class PiezaRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> create(Pieza pieza) async {
    final db = await _db.database;
    return await db.insert('piezas', pieza.toMap());
  }

  Future<List<Pieza>> getByModeloId(int modeloId) async {
    final db = await _db.database;
    final result = await db.query('piezas',
        where: 'modelo_id = ?', whereArgs: [modeloId], orderBy: 'nombre ASC');
    return result.map((map) => Pieza.fromMap(map)).toList();
  }

  Future<List<Pieza>> search(String query, {int? modeloId}) async {
    final db = await _db.database;
    String whereClause = 'nombre LIKE ? OR codigo LIKE ?';
    List<dynamic> args = ['%$query%', '%$query%'];

    if (modeloId != null) {
      whereClause = '($whereClause) AND modelo_id = ?';
      args.add(modeloId);
    }

    final result = await db.query('piezas',
        where: whereClause, whereArgs: args, orderBy: 'nombre ASC');
    return result.map((map) => Pieza.fromMap(map)).toList();
  }

  Future<int> update(Pieza pieza) async {
    final db = await _db.database;
    return await db.update('piezas', pieza.toMap(),
        where: 'id = ?', whereArgs: [pieza.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete('piezas', where: 'id = ?', whereArgs: [id]);
  }
}
