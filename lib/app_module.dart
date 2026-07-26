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
import 'pages/orden_compra_page.dart';
import 'pages/config_marcas_page.dart';
import 'pages/catalogo_piezas_page.dart';
import 'marca_bloc.dart';
import 'modelo_bloc.dart';
import 'pieza_bloc.dart';

final appModule = createModule(
  register: (c) {
    // Repositories
    c.addSingleton(ClienteRepository.new);
    c.addSingleton(VehiculoRepository.new);
    c.addSingleton(ServicioRepository.new);
    c.addSingleton(CompraRepository.new);
    c.addSingleton(FacturaRepository.new);
    c.addSingleton(DetalleFacturaRepository.new);
    c.addSingleton(EmpleadoRepository.new);

    // REPOSITORIOS DE INVENTARIO
    c.addSingleton(InventarioRepository.new);
    c.addSingleton(MovimientoInventarioRepository.new);

    // REPOSITORIO DE SERVICIOS PREDEFINIDOS
    c.addSingleton(ServicioPredefinidoRepository.new);
    c.addSingleton(MarcaRepository.new);
    c.addSingleton(ModeloRepository.new);
    c.addSingleton(PiezaRepository.new);

    // BLoCs
    c.addLazySingleton(() => ClienteBloc(inject<ClienteRepository>()));
    c.addLazySingleton(() => CompraBloc(inject<CompraRepository>()));
    c.addLazySingleton(() => FacturaBloc(
        inject<FacturaRepository>(), inject<DetalleFacturaRepository>()));
    c.addLazySingleton(() => VehiculoBloc(inject<VehiculoRepository>()));
    c.addLazySingleton(() => EmpleadoBloc(inject<EmpleadoRepository>()));
    c.addLazySingleton(() => ServicioBloc(
          servicioRepo: inject<ServicioRepository>(),
          vehiculoRepo: inject<VehiculoRepository>(),
          clienteRepo: inject<ClienteRepository>(),
          empleadoRepo: inject<EmpleadoRepository>(),
        ));
    c.addLazySingleton(
        () => ServicioPredefinidoBloc(inject<ServicioPredefinidoRepository>()));
    c.addLazySingleton(() => MarcaBloc(inject<MarcaRepository>()));
    c.addLazySingleton(() => ModeloBloc(inject<ModeloRepository>()));
    c.addLazySingleton(() => PiezaBloc(inject<PiezaRepository>()));

    // Routes
    c.route('/', child: (context, state) => const HomePage());
    c.route('/clientes', child: (context, state) => const ClientesPage());
    c.route('/clientes/nuevo', child: (context, state) => const ClienteFormPage());
    c.route('/clientes/editar/:id',
        child: (context, state) => ClienteFormPage(
              clienteId: int.parse(state.params['id'] ?? '0'),
            ));
    c.route('/clientes/detalle/:id',
        child: (context, state) => ClienteDetallePage(
              clienteId: int.parse(state.params['id'] ?? '0'),
            ));
    c.route('/compras', child: (context, state) => const ComprasPage());
    c.route('/facturas', child: (context, state) => const FacturasPage());
    c.route('/facturas/nueva', child: (context, state) => const FacturaFormPage());
    c.route('/facturas/nueva/:servicioId',
        child: (context, state) => FacturaFormPage(
              servicioId: int.tryParse(state.params['servicioId'] ?? ''),
            ));
    c.route('/reportes', child: (context, state) => const ReportesPage());
    c.route('/empleados', child: (context, state) => const EmpleadosPage());
    c.route('/servicios', child: (context, state) => const ServiciosPage());
    c.route('/inventario', child: (context, state) => const InventarioPage());
    c.route('/servicios-predefinidos',
        child: (context, state) => const ServiciosPredefinidosPage());
    c.route('/orden-compra', child: (context, state) => const OrdenCompraPage());
    c.route('/configuracion/marcas',
        child: (context, state) => const ConfigMarcasPage());
    c.route('/inventario/piezas',
        child: (context, state) => const CatalogoPiezasPage());
  },
);
