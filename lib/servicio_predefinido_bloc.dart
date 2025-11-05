import 'package:flutter_bloc/flutter_bloc.dart';
import 'models.dart';
import 'repositories.dart';

// Estados
abstract class ServicioPredefinidoState {}

class ServicioPredefinidoInitial extends ServicioPredefinidoState {}

class ServicioPredefinidoLoading extends ServicioPredefinidoState {}

class ServiciosPredefinidosLoaded extends ServicioPredefinidoState {
  final List<ServicioPredefinido> servicios;
  ServiciosPredefinidosLoaded(this.servicios);
}

class ServicioPredefinidoError extends ServicioPredefinidoState {
  final String message;
  ServicioPredefinidoError(this.message);
}

// Eventos
abstract class ServicioPredefinidoEvent {}

class LoadServiciosPredefinidos extends ServicioPredefinidoEvent {}

class LoadServiciosPredefinidosByCategoria extends ServicioPredefinidoEvent {
  final String categoria;
  LoadServiciosPredefinidosByCategoria(this.categoria);
}

class CreateServicioPredefinido extends ServicioPredefinidoEvent {
  final ServicioPredefinido servicio;
  CreateServicioPredefinido(this.servicio);
}

class UpdateServicioPredefinido extends ServicioPredefinidoEvent {
  final ServicioPredefinido servicio;
  UpdateServicioPredefinido(this.servicio);
}

class DeleteServicioPredefinido extends ServicioPredefinidoEvent {
  final int id;
  DeleteServicioPredefinido(this.id);
}

// BLoC
class ServicioPredefinidoBloc extends Bloc<ServicioPredefinidoEvent, ServicioPredefinidoState> {
  final ServicioPredefinidoRepository _repository;

  ServicioPredefinidoBloc(this._repository) : super(ServicioPredefinidoInitial()) {
    on<LoadServiciosPredefinidos>(_onLoadServiciosPredefinidos);
    on<LoadServiciosPredefinidosByCategoria>(_onLoadServiciosPredefinidosByCategoria);
    on<CreateServicioPredefinido>(_onCreateServicioPredefinido);
    on<UpdateServicioPredefinido>(_onUpdateServicioPredefinido);
    on<DeleteServicioPredefinido>(_onDeleteServicioPredefinido);
  }

  Future<void> _onLoadServiciosPredefinidos(
    LoadServiciosPredefinidos event,
    Emitter<ServicioPredefinidoState> emit,
  ) async {
    try {
      emit(ServicioPredefinidoLoading());
      final servicios = await _repository.getAll();
      emit(ServiciosPredefinidosLoaded(servicios));
    } catch (e) {
      emit(ServicioPredefinidoError(e.toString()));
    }
  }

  Future<void> _onLoadServiciosPredefinidosByCategoria(
    LoadServiciosPredefinidosByCategoria event,
    Emitter<ServicioPredefinidoState> emit,
  ) async {
    try {
      emit(ServicioPredefinidoLoading());
      final servicios = await _repository.getByCategoria(event.categoria);
      emit(ServiciosPredefinidosLoaded(servicios));
    } catch (e) {
      emit(ServicioPredefinidoError(e.toString()));
    }
  }

  Future<void> _onCreateServicioPredefinido(
    CreateServicioPredefinido event,
    Emitter<ServicioPredefinidoState> emit,
  ) async {
    try {
      emit(ServicioPredefinidoLoading());
      await _repository.create(event.servicio);
      final servicios = await _repository.getAll();
      emit(ServiciosPredefinidosLoaded(servicios));
    } catch (e) {
      emit(ServicioPredefinidoError(e.toString()));
    }
  }

  Future<void> _onUpdateServicioPredefinido(
    UpdateServicioPredefinido event,
    Emitter<ServicioPredefinidoState> emit,
  ) async {
    try {
      emit(ServicioPredefinidoLoading());
      await _repository.update(event.servicio);
      final servicios = await _repository.getAll();
      emit(ServiciosPredefinidosLoaded(servicios));
    } catch (e) {
      emit(ServicioPredefinidoError(e.toString()));
    }
  }

  Future<void> _onDeleteServicioPredefinido(
    DeleteServicioPredefinido event,
    Emitter<ServicioPredefinidoState> emit,
  ) async {
    try {
      emit(ServicioPredefinidoLoading());
      await _repository.delete(event.id);
      final servicios = await _repository.getAll();
      emit(ServiciosPredefinidosLoaded(servicios));
    } catch (e) {
      emit(ServicioPredefinidoError(e.toString()));
    }
  }
}