import 'package:flutter_modular/flutter_modular.dart';
import 'repositories.dart';
import 'cliente_bloc.dart';
import 'compra_bloc.dart';
import 'factura_bloc.dart';
import 'vehiculo_bloc.dart';
import 'empleado_bloc.dart';
import 'servicio_bloc.dart';
import 'servicio_predefinido_bloc.dart';
import 'pages/home_page.dart';
import 'pages/clientes_page.dart';
import 'pages/cliente_form_page.dart';
import 'pages/compras_page.dart';
import 'pages/facturas_page.dart';
import 'pages/factura_form_page.dart';
import 'pages/cliente_detalle_page.dart';
import 'pages/reportes_page.dart';
import 'pages/empleados_page.dart';
import 'pages/servicios_page.dart';
import 'pages/inventario_page.dart';
import 'pages/servicios_predefinidos_page.dart';

class AppModule extends Module {
  @override
  void binds(i) {
    // Repositories
    i.addSingleton(ClienteRepository.new);
    i.addSingleton(VehiculoRepository.new);
    i.addSingleton(ServicioRepository.new);
    i.addSingleton(CompraRepository.new);
    i.addSingleton(FacturaRepository.new);
    i.addSingleton(DetalleFacturaRepository.new);
    i.addSingleton(EmpleadoRepository.new);
    
    // REPOSITORIOS DE INVENTARIO
    i.addSingleton(InventarioRepository.new);
    i.addSingleton(MovimientoInventarioRepository.new);
    
    // REPOSITORIO DE SERVICIOS PREDEFINIDOS
    i.addSingleton(ServicioPredefinidoRepository.new);
    
    // BLoCs
    i.addLazySingleton(() => ClienteBloc(i.get<ClienteRepository>()));
    i.addLazySingleton(() => CompraBloc(i.get<CompraRepository>()));
    i.addLazySingleton(() => FacturaBloc(i.get<FacturaRepository>(), i.get<DetalleFacturaRepository>()));
    i.addLazySingleton(() => VehiculoBloc(i.get<VehiculoRepository>()));
    i.addLazySingleton(() => EmpleadoBloc(i.get<EmpleadoRepository>()));
    i.addLazySingleton(() => ServicioBloc(
      servicioRepo: i.get<ServicioRepository>(),
      vehiculoRepo: i.get<VehiculoRepository>(),
      clienteRepo: i.get<ClienteRepository>(),
      empleadoRepo: i.get<EmpleadoRepository>(),
    ));
    i.addLazySingleton(() => ServicioPredefinidoBloc(i.get<ServicioPredefinidoRepository>()));
  }

  @override
  void routes(r) {
    r.child('/', child: (context) => const HomePage());
    r.child('/clientes', child: (context) => const ClientesPage());
    r.child('/clientes/nuevo', child: (context) => const ClienteFormPage());
    r.child('/clientes/editar/:id', child: (context) => ClienteFormPage(
      clienteId: int.parse(r.args.params['id'] ?? '0'),
    ));
    r.child('/clientes/detalle/:id', child: (context) => ClienteDetallePage(
      clienteId: int.parse(r.args.params['id'] ?? '0'),
    ));
    r.child('/compras', child: (context) => const ComprasPage());
    r.child('/facturas', child: (context) => const FacturasPage());
    r.child('/facturas/nueva', child: (context) => const FacturaFormPage());
    r.child('/reportes', child: (context) => const ReportesPage());
    r.child('/empleados', child: (context) => const EmpleadosPage());
    r.child('/servicios', child: (context) => const ServiciosPage());
    r.child('/inventario', child: (context) => const InventarioPage());
    r.child('/servicios-predefinidos', child: (context) => const ServiciosPredefinidosPage());
  }
}