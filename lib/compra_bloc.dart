import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'models.dart';
import 'repositories.dart';

// Events
abstract class CompraEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadCompras extends CompraEvent {}

class LoadComprasByServicio extends CompraEvent {
  final int servicioId;
  LoadComprasByServicio(this.servicioId);
  @override
  List<Object?> get props => [servicioId];
}

class AddCompra extends CompraEvent {
  final Compra compra;
  AddCompra(this.compra);
  @override
  List<Object?> get props => [compra];
}

class DeleteCompra extends CompraEvent {
  final int id;
  DeleteCompra(this.id);
  @override
  List<Object?> get props => [id];
}

// States
abstract class CompraState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CompraInitial extends CompraState {}

class CompraLoading extends CompraState {}

class CompraLoaded extends CompraState {
  final List<Compra> compras;
  CompraLoaded(this.compras);
  @override
  List<Object?> get props => [compras];
}

class CompraError extends CompraState {
  final String message;
  CompraError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class CompraBloc extends Bloc<CompraEvent, CompraState> {
  final CompraRepository repository;

  CompraBloc(this.repository) : super(CompraInitial()) {
    on<LoadCompras>(_onLoadCompras);
    on<LoadComprasByServicio>(_onLoadComprasByServicio);
    on<AddCompra>(_onAddCompra);
    on<DeleteCompra>(_onDeleteCompra);
  }

  Future<void> _onLoadCompras(LoadCompras event, Emitter<CompraState> emit) async {
    emit(CompraLoading());
    try {
      final compras = await repository.getAll();
      emit(CompraLoaded(compras));
    } catch (e) {
      emit(CompraError(e.toString()));
    }
  }

  Future<void> _onLoadComprasByServicio(LoadComprasByServicio event, Emitter<CompraState> emit) async {
    emit(CompraLoading());
    try {
      final compras = await repository.getByServicioId(event.servicioId);
      emit(CompraLoaded(compras));
    } catch (e) {
      emit(CompraError(e.toString()));
    }
  }

  Future<void> _onAddCompra(AddCompra event, Emitter<CompraState> emit) async {
    try {
      await repository.create(event.compra);
      add(LoadCompras());
    } catch (e) {
      emit(CompraError(e.toString()));
    }
  }

  Future<void> _onDeleteCompra(DeleteCompra event, Emitter<CompraState> emit) async {
    try {
      await repository.delete(event.id);
      add(LoadCompras());
    } catch (e) {
      emit(CompraError(e.toString()));
    }
  }
}