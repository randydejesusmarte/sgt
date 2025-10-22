import 'package:flutter_bloc/flutter_bloc.dart';
import 'models.dart';
import 'repositories.dart';

// Estados
abstract class EmpleadoState {}

class EmpleadoInitial extends EmpleadoState {}

class EmpleadoLoading extends EmpleadoState {}

class EmpleadosLoaded extends EmpleadoState {
  final List<Empleado> empleados;
  EmpleadosLoaded(this.empleados);
}

class EmpleadoError extends EmpleadoState {
  final String message;
  EmpleadoError(this.message);
}

// Eventos
abstract class EmpleadoEvent {}

class LoadEmpleados extends EmpleadoEvent {}

class CreateEmpleado extends EmpleadoEvent {
  final Empleado empleado;
  CreateEmpleado(this.empleado);
}

class UpdateEmpleado extends EmpleadoEvent {
  final Empleado empleado;
  UpdateEmpleado(this.empleado);
}

class DeleteEmpleado extends EmpleadoEvent {
  final int id;
  DeleteEmpleado(this.id);
}

// BLoC
class EmpleadoBloc extends Bloc<EmpleadoEvent, EmpleadoState> {
  final EmpleadoRepository _repository;

  EmpleadoBloc(this._repository) : super(EmpleadoInitial()) {
    on<LoadEmpleados>(_onLoadEmpleados);
    on<CreateEmpleado>(_onCreateEmpleado);
    on<UpdateEmpleado>(_onUpdateEmpleado);
    on<DeleteEmpleado>(_onDeleteEmpleado);
  }

  Future<void> _onLoadEmpleados(LoadEmpleados event, Emitter<EmpleadoState> emit) async {
    try {
      emit(EmpleadoLoading());
      final empleados = await _repository.getAll();
      emit(EmpleadosLoaded(empleados));
    } catch (e) {
      emit(EmpleadoError(e.toString()));
    }
  }

  Future<void> _onCreateEmpleado(CreateEmpleado event, Emitter<EmpleadoState> emit) async {
    try {
      emit(EmpleadoLoading());
      await _repository.create(event.empleado);
      final empleados = await _repository.getAll();
      emit(EmpleadosLoaded(empleados));
    } catch (e) {
      emit(EmpleadoError(e.toString()));
    }
  }

  Future<void> _onUpdateEmpleado(UpdateEmpleado event, Emitter<EmpleadoState> emit) async {
    try {
      emit(EmpleadoLoading());
      await _repository.update(event.empleado);
      final empleados = await _repository.getAll();
      emit(EmpleadosLoaded(empleados));
    } catch (e) {
      emit(EmpleadoError(e.toString()));
    }
  }

  Future<void> _onDeleteEmpleado(DeleteEmpleado event, Emitter<EmpleadoState> emit) async {
    try {
      emit(EmpleadoLoading());
      await _repository.delete(event.id);
      final empleados = await _repository.getAll();
      emit(EmpleadosLoaded(empleados));
    } catch (e) {
      emit(EmpleadoError(e.toString()));
    }
  }
}