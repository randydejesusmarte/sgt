import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('taller.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // INCREMENTAR VERSIÓN PARA MIGRACIÓN
      onCreate: _createDB,
      onUpgrade: _onUpgrade, // AGREGAR MIGRACIÓN
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE clientes (
  id $idType,
  nombre $textType,
  telefono $textType,
  email TEXT,
  direccion TEXT,
  created_at $textType
)
''');

    await db.execute('''
CREATE TABLE vehiculos (
  id $idType,
  cliente_id $intType,
  marca $textType,
  modelo $textType,
  anio $intType,
  placa $textType,
  FOREIGN KEY (cliente_id) REFERENCES clientes (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE servicios (
  id $idType,
  vehiculo_id $intType,
  empleado_id INTEGER,
  descripcion $textType,
  costo $realType,
  fecha $textType,
  estado $textType,
  notas TEXT,
  FOREIGN KEY (vehiculo_id) REFERENCES vehiculos (id) ON DELETE CASCADE,
  FOREIGN KEY (empleado_id) REFERENCES empleados (id) ON DELETE SET NULL
)
''');

    await db.execute('''
CREATE TABLE empleados (
  id $idType,
  nombre $textType,
  telefono $textType,
  especialidad TEXT,
  activo $intType,
  created_at $textType
)
''');

    await db.execute('''
CREATE TABLE compras (
  id $idType,
  servicio_id $intType,
  item $textType,
  cantidad $intType,
  precio_unitario $realType,
  total $realType,
  fecha $textType,
  FOREIGN KEY (servicio_id) REFERENCES servicios (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE facturas (
  id $idType,
  cliente_id $intType,
  numero_factura $textType,
  fecha $textType,
  subtotal $realType,
  impuesto $realType,
  descuento $realType,
  total $realType,
  estado $textType,
  notas TEXT,
  FOREIGN KEY (cliente_id) REFERENCES clientes (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE detalle_factura (
  id $idType,
  factura_id $intType,
  servicio_id INTEGER,
  descripcion $textType,
  cantidad $intType,
  precio_unitario $realType,
  total $realType,
  FOREIGN KEY (factura_id) REFERENCES facturas (id) ON DELETE CASCADE,
  FOREIGN KEY (servicio_id) REFERENCES servicios (id) ON DELETE SET NULL
)
''');

    // TABLAS DE INVENTARIO
    await db.execute('''
CREATE TABLE inventario (
  id $idType,
  codigo $textType,
  nombre $textType,
  descripcion TEXT,
  cantidad_disponible $intType,
  precio_compra $realType,
  precio_venta $realType,
  categoria TEXT,
  created_at $textType
)
''');

    await db.execute('''
CREATE TABLE movimientos_inventario (
  id $idType,
  inventario_id $intType,
  tipo $textType,
  cantidad $intType,
  referencia TEXT,
  motivo TEXT,
  fecha $textType,
  FOREIGN KEY (inventario_id) REFERENCES inventario (id) ON DELETE CASCADE
)
''');
  }

  // MIGRACIÓN DE VERSIÓN 1 A VERSIÓN 2
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
      const textType = 'TEXT NOT NULL';
      const realType = 'REAL NOT NULL';
      const intType = 'INTEGER NOT NULL';

      // Crear tablas de inventario
      await db.execute('''
CREATE TABLE inventario (
  id $idType,
  codigo $textType,
  nombre $textType,
  descripcion TEXT,
  cantidad_disponible $intType,
  precio_compra $realType,
  precio_venta $realType,
  categoria TEXT,
  created_at $textType
)
''');

      await db.execute('''
CREATE TABLE movimientos_inventario (
  id $idType,
  inventario_id $intType,
  tipo $textType,
  cantidad $intType,
  referencia TEXT,
  motivo TEXT,
  fecha $textType,
  FOREIGN KEY (inventario_id) REFERENCES inventario (id) ON DELETE CASCADE
)
''');
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}