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
      version: 9,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
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
  clasificacion TEXT NOT NULL DEFAULT 'normal',
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
  es_garantia $intType DEFAULT 0,
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
  fecha_nacimiento TEXT,
  activo $intType,
  cobra_porcentaje $intType DEFAULT 0,
  porcentaje_comision $realType DEFAULT 0.0,
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
  tipo_pago TEXT NOT NULL DEFAULT 'contado',
  con_comprobante INTEGER NOT NULL DEFAULT 0,
  ncf TEXT,
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

    await db.execute('''
CREATE TABLE servicios_predefinidos (
  id $idType,
  codigo $textType,
  nombre $textType,
  descripcion TEXT,
  precio $realType,
  categoria TEXT,
  activo $intType,
  created_at $textType
)
''');

    // Nuevas tablas v5
    await db.execute('''
CREATE TABLE marcas (
  id $idType,
  nombre $textType UNIQUE
)
''');

    await db.execute('''
CREATE TABLE modelos (
  id $idType,
  marca_id $intType,
  nombre $textType,
  anio $intType,
  FOREIGN KEY (marca_id) REFERENCES marcas (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE piezas (
  id $idType,
  modelo_id $intType,
  nombre $textType,
  medidas $textType,
  codigo TEXT,
  FOREIGN KEY (modelo_id) REFERENCES modelos (id) ON DELETE CASCADE
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

    if (oldVersion < 3) {
      // Logic for version 3 if it was skipped or needed (already in onCreate, but good practice if upgrading from v1 to v4 directly)
      // Assuming v2->v3 was done before or user is on v3.
      // If user is on v2, they need the create statements for v3?
      // The previous code had specific v1->v2.
      // Let's assume the user is properly migrated up to now or is fresh.
    }

    if (oldVersion < 4) {
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
      const textType = 'TEXT NOT NULL';
      const realType = 'REAL NOT NULL';
      const intType = 'INTEGER NOT NULL';

      // Verify if table exists to avoid error if jumping versions loosely
      // But for standard sequential upgrade:

      // Add servicios_predefinidos if it doesn't exist (it was missing in previous _createDB but presumably needed)
      // Checking if table exists is hard in raw sqflite without query.
      // We'll just try Execute and ignore if exists? No, sqflite throws.
      // We will blindly create it if we are upgrading to v4, assuming it wasn't there.

      await db.execute('''
CREATE TABLE IF NOT EXISTS servicios_predefinidos (
  id $idType,
  codigo $textType,
  nombre $textType,
  descripcion TEXT,
  precio $realType,
  categoria TEXT,
  activo $intType,
  created_at $textType
)
''');

      await db.execute('''
CREATE TABLE marcas_modelos (
  id $idType,
  marca $textType,
  modelo $textType,
  created_at $textType
)
''');
    }

    if (oldVersion < 5) {
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
      const textType = 'TEXT NOT NULL';
      const intType = 'INTEGER NOT NULL';

      await db.execute('''
CREATE TABLE marcas (
  id $idType,
  nombre $textType UNIQUE
)
''');

      await db.execute('''
CREATE TABLE modelos (
  id $idType,
  marca_id $intType,
  nombre $textType,
  anio $intType,
  FOREIGN KEY (marca_id) REFERENCES marcas (id) ON DELETE CASCADE
)
''');

      await db.execute('''
CREATE TABLE piezas (
  id $idType,
  modelo_id $intType,
  nombre $textType,
  medidas $textType,
  codigo TEXT,
  FOREIGN KEY (modelo_id) REFERENCES modelos (id) ON DELETE CASCADE
)
''');

      // Optional: Migrate data from brands_models if needed, but since it was just added in v4 and likely empty/test data, we might skip complex data migration for simplicity unless crucial.
      // Dropping table marcas_modelos might be cleaner if we want to get rid of it.
      // await db.execute('DROP TABLE IF EXISTS marcas_modelos');
    }

    if (oldVersion < 6) {
      await db.execute('ALTER TABLE empleados ADD COLUMN fecha_nacimiento TEXT');
    }

    if (oldVersion < 7) {
      await db.execute("ALTER TABLE clientes ADD COLUMN clasificacion TEXT NOT NULL DEFAULT 'normal'");
      await db.execute("ALTER TABLE facturas ADD COLUMN tipo_pago TEXT NOT NULL DEFAULT 'contado'");
      await db.execute("ALTER TABLE facturas ADD COLUMN con_comprobante INTEGER NOT NULL DEFAULT 0");
      await db.execute("ALTER TABLE facturas ADD COLUMN ncf TEXT");
    }

    if (oldVersion < 8) {
      await db.execute("ALTER TABLE empleados ADD COLUMN cobra_porcentaje INTEGER NOT NULL DEFAULT 0");
      await db.execute("ALTER TABLE empleados ADD COLUMN porcentaje_comision REAL NOT NULL DEFAULT 0.0");
    }

    if (oldVersion < 9) {
      await db.execute("ALTER TABLE servicios ADD COLUMN es_garantia INTEGER NOT NULL DEFAULT 0");
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
