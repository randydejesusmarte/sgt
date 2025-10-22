import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'models.dart';
import 'repositories.dart';

// Events
abstract class ClienteEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadClientes extends ClienteEvent {}

class AddCliente extends ClienteEvent {
  final Cliente cliente;
  AddCliente(this.cliente);
  @override
  List<Object?> get props => [cliente];
}

class UpdateCliente extends ClienteEvent {
  final Cliente cliente;
  UpdateCliente(this.cliente);
  @override
  List<Object?> get props => [cliente];
}

class DeleteCliente extends ClienteEvent {
  final int id;
  DeleteCliente(this.id);
  @override
  List<Object?> get props => [id];
}

// States
abstract class ClienteState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ClienteInitial extends ClienteState {}

class ClienteLoading extends ClienteState {}

class ClienteLoaded extends ClienteState {
  final List<Cliente> clientes;
  ClienteLoaded(this.clientes);
  @override
  List<Object?> get props => [clientes];
}

class ClienteError extends ClienteState {
  final String message;
  ClienteError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class ClienteBloc extends Bloc<ClienteEvent, ClienteState> {
  final ClienteRepository repository;

  ClienteBloc(this.repository) : super(ClienteInitial()) {
    on<LoadClientes>(_onLoadClientes);
    on<AddCliente>(_onAddCliente);
    on<UpdateCliente>(_onUpdateCliente);
    on<DeleteCliente>(_onDeleteCliente);
  }

  Future<void> _onLoadClientes(LoadClientes event, Emitter<ClienteState> emit) async {
    emit(ClienteLoading());
    try {
      final clientes = await repository.getAll();
      emit(ClienteLoaded(clientes));
    } catch (e) {
      emit(ClienteError(e.toString()));
    }
  }

  Future<void> _onAddCliente(AddCliente event, Emitter<ClienteState> emit) async {
    try {
      await repository.create(event.cliente);
      add(LoadClientes());
    } catch (e) {
      emit(ClienteError(e.toString()));
    }
  }

  Future<void> _onUpdateCliente(UpdateCliente event, Emitter<ClienteState> emit) async {
    try {
      await repository.update(event.cliente);
      add(LoadClientes());
    } catch (e) {
      emit(ClienteError(e.toString()));
    }
  }

  Future<void> _onDeleteCliente(DeleteCliente event, Emitter<ClienteState> emit) async {
    try {
      await repository.delete(event.id);
      add(LoadClientes());
    } catch (e) {
      emit(ClienteError(e.toString()));
    }
  }
}