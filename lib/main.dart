import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app_module.dart';
import 'migration_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar sqflite solo para desktop (Windows, Linux, macOS)
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // EJECUTAR MIGRACIÓN PARA SERVICIOS PREDEFINIDOS
  try {
    await MigrationHelper.ejecutarMigracionV3();
    print('✅ Migración completada exitosamente');
  } catch (e) {
    print('❌ Error en migración: $e');
  }
  
  runApp(ModularApp(module: AppModule(), child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Taller de Autos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),
      routerConfig: Modular.routerConfig,
    );
  }
}