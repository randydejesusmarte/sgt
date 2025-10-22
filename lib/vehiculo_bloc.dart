import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'models.dart';
import 'repositories.dart';

// Events
abstract class VehiculoEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadVehiculosByCliente extends VehiculoEvent {
  final int clienteId;
  LoadVehiculosByCliente(this.clienteId);
  @override
  List<Object?> get props => [clienteId];
}

class AddVehiculo extends VehiculoEvent {
  final Vehiculo vehiculo;
  AddVehiculo(this.vehiculo);
  @override
  List<Object?> get props => [vehiculo];
}

class UpdateVehiculo extends VehiculoEvent {
  final Vehiculo vehiculo;
  UpdateVehiculo(this.vehiculo);
  @override
  List<Object?> get props => [vehiculo];
}

class DeleteVehiculo extends VehiculoEvent {
  final int id;
  DeleteVehiculo(this.id);
  @override
  List<Object?> get props => [id];
}

// States
abstract class VehiculoState extends Equatable {
  @override
  List<Object?> get props => [];
}

class VehiculoInitial extends VehiculoState {}

class VehiculoLoading extends VehiculoState {}

class VehiculoLoaded extends VehiculoState {
  final List<Vehiculo> vehiculos;
  VehiculoLoaded(this.vehiculos);
  @override
  List<Object?> get props => [vehiculos];
}

class VehiculoError extends VehiculoState {
  final String message;
  VehiculoError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class VehiculoBloc extends Bloc<VehiculoEvent, VehiculoState> {
  final VehiculoRepository repository;

  VehiculoBloc(this.repository) : super(VehiculoInitial()) {
    on<LoadVehiculosByCliente>(_onLoadVehiculosByCliente);
    on<AddVehiculo>(_onAddVehiculo);
    on<UpdateVehiculo>(_onUpdateVehiculo);
    on<DeleteVehiculo>(_onDeleteVehiculo);
  }

  Future<void> _onLoadVehiculosByCliente(LoadVehiculosByCliente event, Emitter<VehiculoState> emit) async {
    emit(VehiculoLoading());
    try {
      final vehiculos = await repository.getByClienteId(event.clienteId);
      emit(VehiculoLoaded(vehiculos));
    } catch (e) {
      emit(VehiculoError(e.toString()));
    }
  }

  Future<void> _onAddVehiculo(AddVehiculo event, Emitter<VehiculoState> emit) async {
    try {
      await repository.create(event.vehiculo);
      add(LoadVehiculosByCliente(event.vehiculo.clienteId));
    } catch (e) {
      emit(VehiculoError(e.toString()));
    }
  }

  Future<void> _onUpdateVehiculo(UpdateVehiculo event, Emitter<VehiculoState> emit) async {
    try {
      await repository.update(event.vehiculo);
      add(LoadVehiculosByCliente(event.vehiculo.clienteId));
    } catch (e) {
      emit(VehiculoError(e.toString()));
    }
  }

  Future<void> _onDeleteVehiculo(DeleteVehiculo event, Emitter<VehiculoState> emit) async {
    try {
      await repository.delete(event.id);
      // Necesitarás recargar la lista actual
    } catch (e) {
      emit(VehiculoError(e.toString()));
    }
  }
}