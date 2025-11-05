import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class MigrationHelper {
  static Future<void> ejecutarMigracionV3() async {
    final db = await DatabaseHelper.instance.database;
    
    print('🔄 Iniciando migración a versión 3...');
    
    // Verificar si la tabla ya existe
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='servicios_predefinidos'"
    );
    
    if (result.isNotEmpty) {
      print('✅ La tabla servicios_predefinidos ya existe');
      return;
    }
    
    try {
      // Crear la tabla de servicios predefinidos
      await db.execute('''
        CREATE TABLE servicios_predefinidos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          codigo TEXT NOT NULL,
          nombre TEXT NOT NULL,
          descripcion TEXT,
          precio REAL NOT NULL,
          categoria TEXT,
          activo INTEGER NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
      
      print('✅ Tabla servicios_predefinidos creada exitosamente');
      
      // Opcional: Insertar algunos servicios predefinidos de ejemplo
      await _insertarServiciosEjemplo(db);
      
    } catch (e) {
      print('❌ Error al crear la tabla: $e');
      rethrow;
    }
  }
  
  static Future<void> _insertarServiciosEjemplo(Database db) async {
    final serviciosEjemplo = [
      {
        'codigo': 'SRV-001',
        'nombre': 'Cambio de Aceite',
        'descripcion': 'Cambio de aceite de motor y filtro',
        'precio': 1500.0,
        'categoria': 'Mantenimiento',
        'activo': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'codigo': 'SRV-002',
        'nombre': 'Alineación',
        'descripcion': 'Alineación de ruedas completa',
        'precio': 1200.0,
        'categoria': 'Mantenimiento',
        'activo': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'codigo': 'SRV-003',
        'nombre': 'Balanceo',
        'descripcion': 'Balanceo de 4 ruedas',
        'precio': 800.0,
        'categoria': 'Mantenimiento',
        'activo': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'codigo': 'SRV-004',
        'nombre': 'Cambio de Pastillas de Freno',
        'descripcion': 'Cambio de pastillas delanteras o traseras',
        'precio': 2500.0,
        'categoria': 'Reparación',
        'activo': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'codigo': 'SRV-005',
        'nombre': 'Revisión General',
        'descripcion': 'Inspección completa del vehículo',
        'precio': 500.0,
        'categoria': 'Diagnóstico',
        'activo': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
    ];
    
    for (var servicio in serviciosEjemplo) {
      await db.insert('servicios_predefinidos', servicio);
    }
    
    print('✅ Insertados ${serviciosEjemplo.length} servicios de ejemplo');
  }
}