import 'package:flutter_bloc/flutter_bloc.dart';
import 'models.dart';
import 'repositories.dart';

// Estados
abstract class ServicioState {}

class ServicioInitial extends ServicioState {}

class ServicioLoading extends ServicioState {}

class ServiciosLoaded extends ServicioState {
  final List<Servicio> servicios;
  final Map<int, Vehiculo> vehiculos;
  final Map<int, Cliente> clientes;
  final Map<int, Empleado> empleados;

  ServiciosLoaded({
    required this.servicios,
    required this.vehiculos,
    required this.clientes,
    required this.empleados,
  });
}

class ServicioError extends ServicioState {
  final String message;
  ServicioError(this.message);
}

// Eventos
abstract class ServicioEvent {}

class LoadServicios extends ServicioEvent {}

class LoadServiciosByCliente extends ServicioEvent {
  final int clienteId;
  LoadServiciosByCliente(this.clienteId);
}

class CreateServicio extends ServicioEvent {
  final Servicio servicio;
  CreateServicio(this.servicio);
}

class UpdateServicio extends ServicioEvent {
  final Servicio servicio;
  UpdateServicio(this.servicio);
}

class DeleteServicio extends ServicioEvent {
  final int id;
  DeleteServicio(this.id);
}

// BLoC
class ServicioBloc extends Bloc<ServicioEvent, ServicioState> {
  final ServicioRepository _servicioRepo;

  ServicioBloc({
    required ServicioRepository servicioRepo,
    VehiculoRepository? vehiculoRepo,
    ClienteRepository? clienteRepo,
    EmpleadoRepository? empleadoRepo,
  }) : _servicioRepo = servicioRepo,
       super(ServicioInitial()) {
    on<LoadServicios>(_onLoadServicios);
    on<LoadServiciosByCliente>(_onLoadServiciosByCliente);
    on<CreateServicio>(_onCreateServicio);
    on<UpdateServicio>(_onUpdateServicio);
    on<DeleteServicio>(_onDeleteServicio);
  }

  Future<void> _onLoadServiciosByCliente(LoadServiciosByCliente event, Emitter<ServicioState> emit) async {
    try {
      emit(ServicioLoading());
      final rows = await _servicioRepo.getServiciosConDetallesByCliente(event.clienteId);
      final List<Servicio> servicios = [];
      final Map<int, Vehiculo> vehiculosMap = {};
      final Map<int, Cliente> clientesMap = {};
      final Map<int, Empleado> empleadosMap = {};

      for (var row in rows) {
        final servicio = Servicio(
          id: row['s_id'] as int?,
          vehiculoId: row['s_vehiculo_id'] as int,
          empleadoId: row['s_empleado_id'] as int?,
          descripcion: row['s_descripcion'] as String,
          costo: (row['s_costo'] as num).toDouble(),
          fecha: DateTime.parse(row['s_fecha'] as String),
          estado: row['s_estado'] as String,
          notas: row['s_notas'] as String?,
          esGarantia: (row['s_es_garantia'] as int? ?? 0) == 1,
        );
        servicios.add(servicio);

        final vehiculoId = row['v_id'] as int;
        if (!vehiculosMap.containsKey(vehiculoId)) {
          vehiculosMap[vehiculoId] = Vehiculo(
            id: vehiculoId,
            clienteId: row['v_cliente_id'] as int,
            marca: row['v_marca'] as String,
            modelo: row['v_modelo'] as String,
            anio: row['v_anio'] as int,
            placa: row['v_placa'] as String,
          );
        }

        final clienteId = row['c_id'] as int;
        if (!clientesMap.containsKey(clienteId)) {
          clientesMap[clienteId] = Cliente(
            id: clienteId,
            nombre: row['c_nombre'] as String,
            telefono: row['c_telefono'] as String,
            email: row['c_email'] as String?,
            direccion: row['c_direccion'] as String?,
            clasificacion: (row['c_clasificacion'] as String?) ?? 'normal',
            createdAt: DateTime.parse(row['c_created_at'] as String),
          );
        }

        if (row['e_id'] != null) {
          final empleadoId = row['e_id'] as int;
          if (!empleadosMap.containsKey(empleadoId)) {
            empleadosMap[empleadoId] = Empleado(
              id: empleadoId,
              nombre: row['e_nombre'] as String,
              telefono: row['e_telefono'] as String,
              especialidad: row['e_especialidad'] as String?,
              activo: (row['e_activo'] as int) == 1,
              cobraPorcentaje: (row['e_cobra_porcentaje'] as int? ?? 0) == 1,
              porcentajeComision:
                  (row['e_porcentaje_comision'] as num? ?? 0.0).toDouble(),
              createdAt: DateTime.parse(row['e_created_at'] as String),
            );
          }
        }
      }

      emit(ServiciosLoaded(
        servicios: servicios,
        vehiculos: vehiculosMap,
        clientes: clientesMap,
        empleados: empleadosMap,
      ));
    } catch (e) {
      emit(ServicioError(e.toString()));
    }
  }

  Future<void> _onLoadServicios(LoadServicios event, Emitter<ServicioState> emit) async {
    try {
      emit(ServicioLoading());
      
      final rows = await _servicioRepo.getServiciosConDetalles();
      final List<Servicio> servicios = [];
      final Map<int, Vehiculo> vehiculosMap = {};
      final Map<int, Cliente> clientesMap = {};
      final Map<int, Empleado> empleadosMap = {};

      for (var row in rows) {
        final servicio = Servicio(
          id: row['s_id'] as int?,
          vehiculoId: row['s_vehiculo_id'] as int,
          empleadoId: row['s_empleado_id'] as int?,
          descripcion: row['s_descripcion'] as String,
          costo: (row['s_costo'] as num).toDouble(),
          fecha: DateTime.parse(row['s_fecha'] as String),
          estado: row['s_estado'] as String,
          notas: row['s_notas'] as String?,
          esGarantia: (row['s_es_garantia'] as int? ?? 0) == 1,
        );
        servicios.add(servicio);

        final vehiculoId = row['v_id'] as int;
        if (!vehiculosMap.containsKey(vehiculoId)) {
          vehiculosMap[vehiculoId] = Vehiculo(
            id: vehiculoId,
            clienteId: row['v_cliente_id'] as int,
            marca: row['v_marca'] as String,
            modelo: row['v_modelo'] as String,
            anio: row['v_anio'] as int,
            placa: row['v_placa'] as String,
          );
        }

        final clienteId = row['c_id'] as int;
        if (!clientesMap.containsKey(clienteId)) {
          clientesMap[clienteId] = Cliente(
            id: clienteId,
            nombre: row['c_nombre'] as String,
            telefono: row['c_telefono'] as String,
            email: row['c_email'] as String?,
            direccion: row['c_direccion'] as String?,
            clasificacion: (row['c_clasificacion'] as String?) ?? 'normal',
            createdAt: DateTime.parse(row['c_created_at'] as String),
          );
        }

        if (row['e_id'] != null) {
          final empleadoId = row['e_id'] as int;
          if (!empleadosMap.containsKey(empleadoId)) {
            empleadosMap[empleadoId] = Empleado(
              id: empleadoId,
              nombre: row['e_nombre'] as String,
              telefono: row['e_telefono'] as String,
              especialidad: row['e_especialidad'] as String?,
              activo: (row['e_activo'] as int) == 1,
              cobraPorcentaje: (row['e_cobra_porcentaje'] as int? ?? 0) == 1,
              porcentajeComision:
                  (row['e_porcentaje_comision'] as num? ?? 0.0).toDouble(),
              createdAt: DateTime.parse(row['e_created_at'] as String),
            );
          }
        }
      }

      emit(ServiciosLoaded(
        servicios: servicios,
        vehiculos: vehiculosMap,
        clientes: clientesMap,
        empleados: empleadosMap,
      ));
    } catch (e) {
      emit(ServicioError(e.toString()));
    }
  }

  Future<void> _onCreateServicio(CreateServicio event, Emitter<ServicioState> emit) async {
    try {
      await _servicioRepo.create(event.servicio);
      add(LoadServicios()); // Recargar todos los servicios
    } catch (e) {
      emit(ServicioError(e.toString()));
    }
  }

  Future<void> _onUpdateServicio(UpdateServicio event, Emitter<ServicioState> emit) async {
    try {
      await _servicioRepo.update(event.servicio);
      add(LoadServicios()); // Recargar todos los servicios
    } catch (e) {
      emit(ServicioError(e.toString()));
    }
  }

  Future<void> _onDeleteServicio(DeleteServicio event, Emitter<ServicioState> emit) async {
    try {
      await _servicioRepo.delete(event.id);
      add(LoadServicios()); // Recargar todos los servicios
    } catch (e) {
      emit(ServicioError(e.toString()));
    }
  }
}