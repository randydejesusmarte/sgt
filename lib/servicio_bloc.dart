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
  final VehiculoRepository _vehiculoRepo;
  final ClienteRepository _clienteRepo;
  final EmpleadoRepository _empleadoRepo;

  ServicioBloc({
    required ServicioRepository servicioRepo,
    required VehiculoRepository vehiculoRepo,
    required ClienteRepository clienteRepo,
    required EmpleadoRepository empleadoRepo,
  }) : _servicioRepo = servicioRepo,
       _vehiculoRepo = vehiculoRepo,
       _clienteRepo = clienteRepo,
       _empleadoRepo = empleadoRepo,
       super(ServicioInitial()) {
    on<LoadServicios>(_onLoadServicios);
    on<CreateServicio>(_onCreateServicio);
    on<UpdateServicio>(_onUpdateServicio);
    on<DeleteServicio>(_onDeleteServicio);
  }

  Future<void> _onLoadServicios(LoadServicios event, Emitter<ServicioState> emit) async {
    try {
      emit(ServicioLoading());
      
      final servicios = await _servicioRepo.getAll();
      final Map<int, Vehiculo> vehiculosMap = {};
      final Map<int, Cliente> clientesMap = {};
      final Map<int, Empleado> empleadosMap = {};

      // Cargar vehículos y clientes
      for (var servicio in servicios) {
        if (!vehiculosMap.containsKey(servicio.vehiculoId)) {
          final vehiculo = await _vehiculoRepo.getById(servicio.vehiculoId);
          if (vehiculo != null) {
            vehiculosMap[servicio.vehiculoId] = vehiculo;

            // Cargar cliente del vehículo
            if (!clientesMap.containsKey(vehiculo.clienteId)) {
              final cliente = await _clienteRepo.getById(vehiculo.clienteId);
              if (cliente != null) {
                clientesMap[vehiculo.clienteId] = cliente;
              }
            }
          }
        }

        // Cargar empleado si existe
        if (servicio.empleadoId != null &&
            !empleadosMap.containsKey(servicio.empleadoId)) {
          final empleado = await _empleadoRepo.getById(servicio.empleadoId!);
          if (empleado != null) {
            empleadosMap[servicio.empleadoId!] = empleado;
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