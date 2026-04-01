import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class MigrationHelper {
  static Future<void> ejecutarMigracionV5() async {
    final db = await DatabaseHelper.instance.database;
    print('🔄 Iniciando migración a versión 5 (Marcas, Modelos, Piezas)...');

    try {
      // 1. Crear tabla MARCAS si no existe
      if (!await _existeTabla(db, 'marcas')) {
        await db.execute('''
          CREATE TABLE marcas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL UNIQUE
          )
        ''');
        print('✅ Tabla marcas creada');
      } else {
        print('ℹ️ Tabla marcas ya existe');
      }

      // 2. Crear tabla MODELOS si no existe
      if (!await _existeTabla(db, 'modelos')) {
        await db.execute('''
          CREATE TABLE modelos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            marca_id INTEGER NOT NULL,
            nombre TEXT NOT NULL,
            anio INTEGER NOT NULL,
            FOREIGN KEY (marca_id) REFERENCES marcas (id) ON DELETE CASCADE
          )
        ''');
        print('✅ Tabla modelos creada');
      } else {
        print('ℹ️ Tabla modelos ya existe');
      }

      // 3. Crear tabla PIEZAS si no existe
      if (!await _existeTabla(db, 'piezas')) {
        await db.execute('''
          CREATE TABLE piezas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            modelo_id INTEGER NOT NULL,
            nombre TEXT NOT NULL,
            medidas TEXT NOT NULL,
            codigo TEXT,
            FOREIGN KEY (modelo_id) REFERENCES modelos (id) ON DELETE CASCADE
          )
        ''');
        print('✅ Tabla piezas creada');
      } else {
        print('ℹ️ Tabla piezas ya existe');
      }

      // 4. Sembrar datos iniciales (opcional, solo si está vacío)
      await _seedMarcas(db);
    } catch (e) {
      print('❌ Error durante la migración V5: $e');
      rethrow;
    }
  }

  static Future<void> ejecutarMigracionV3() async {
    final db = await DatabaseHelper.instance.database;
    print('🔄 Iniciando migración a versión 3...');

    if (await _existeTabla(db, 'servicios_predefinidos')) {
      print('✅ La tabla servicios_predefinidos ya existe');
      return;
    }

    try {
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
      await _insertarServiciosEjemplo(db);
    } catch (e) {
      print('❌ Error al crear la tabla: $e');
      rethrow;
    }
  }

  // --- Utility Methods ---

  static Future<bool> _existeTabla(Database db, String tabla) async {
    final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tabla]);
    return result.isNotEmpty;
  }

  static Future<void> _seedMarcas(Database db) async {
    final count =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM marcas'));
    if (count != null && count > 0) return;

    print('🌱 Sembrando marcas iniciales...');

    final marcas = [
      'Toyota',
      'Honda',
      'Ford',
      'Chevrolet',
      'Nissan',
      'Hyundai',
      'Kia',
      'Volkswagen',
      'BMW',
      'Mercedes-Benz'
    ];

    final batch = db.batch();
    for (var m in marcas) {
      batch.insert('marcas', {'nombre': m});
    }
    await batch.commit(noResult: true);
    print('✅ Marcas iniciales insertadas');
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

    final batch = db.batch();
    for (var servicio in serviciosEjemplo) {
      batch.insert('servicios_predefinidos', servicio);
    }
    await batch.commit(noResult: true);

    print('✅ Insertados ${serviciosEjemplo.length} servicios de ejemplo');
  }
}
