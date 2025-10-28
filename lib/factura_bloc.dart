import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'models.dart';
import 'repositories.dart';

// Events
abstract class FacturaEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadFacturas extends FacturaEvent {}

class LoadFacturasByCliente extends FacturaEvent {
  final int clienteId;
  LoadFacturasByCliente(this.clienteId);
  @override
  List<Object?> get props => [clienteId];
}

class AddFactura extends FacturaEvent {
  final Factura factura;
  final List<DetalleFactura> detalles;
  AddFactura(this.factura, this.detalles);
  @override
  List<Object?> get props => [factura, detalles];
}

class UpdateFacturaEstado extends FacturaEvent {
  final int id;
  final String estado;
  UpdateFacturaEstado(this.id, this.estado);
  @override
  List<Object?> get props => [id, estado];
}

class DeleteFactura extends FacturaEvent {
  final int id;
  DeleteFactura(this.id);
  @override
  List<Object?> get props => [id];
}

// States
abstract class FacturaState extends Equatable {
  @override
  List<Object?> get props => [];
}

class FacturaInitial extends FacturaState {}

class FacturaLoading extends FacturaState {}

class FacturaLoaded extends FacturaState {
  final List<Factura> facturas;
  FacturaLoaded(this.facturas);
  @override
  List<Object?> get props => [facturas];
}

class FacturaError extends FacturaState {
  final String message;
  FacturaError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class FacturaBloc extends Bloc<FacturaEvent, FacturaState> {
  final FacturaRepository facturaRepository;
  final DetalleFacturaRepository detalleRepository;

  FacturaBloc(this.facturaRepository, this.detalleRepository) : super(FacturaInitial()) {
    on<LoadFacturas>(_onLoadFacturas);
    on<LoadFacturasByCliente>(_onLoadFacturasByCliente);
    on<AddFactura>(_onAddFactura);
    on<UpdateFacturaEstado>(_onUpdateFacturaEstado);
    on<DeleteFactura>(_onDeleteFactura);
  }

  Future<void> _onLoadFacturas(LoadFacturas event, Emitter<FacturaState> emit) async {
    emit(FacturaLoading());
    try {
      final facturas = await facturaRepository.getAll();
      emit(FacturaLoaded(facturas));
    } catch (e) {
      emit(FacturaError(e.toString()));
    }
  }

  Future<void> _onLoadFacturasByCliente(LoadFacturasByCliente event, Emitter<FacturaState> emit) async {
    emit(FacturaLoading());
    try {
      final facturas = await facturaRepository.getByClienteId(event.clienteId);
      emit(FacturaLoaded(facturas));
    } catch (e) {
      emit(FacturaError(e.toString()));
    }
  }

  Future<void> _onAddFactura(AddFactura event, Emitter<FacturaState> emit) async {
    try {
      // NO emitir loading aquí para no bloquear la UI
      
      // Crear la factura
      final facturaId = await facturaRepository.create(event.factura);
      
      if (facturaId <= 0) {
        emit(FacturaError('Error al crear la factura'));
        return;
      }

      // Crear los detalles
      for (var detalle in event.detalles) {
        final detalleToCreate = DetalleFactura(
          facturaId: facturaId,
          servicioId: detalle.servicioId,
          descripcion: detalle.descripcion,
          cantidad: detalle.cantidad,
          precioUnitario: detalle.precioUnitario,
          total: detalle.total,
        );
        
        final detalleId = await detalleRepository.create(detalleToCreate);
        
        if (detalleId <= 0) {
          // Si falla la creación de un detalle, eliminar la factura y sus detalles
          await detalleRepository.deleteByFacturaId(facturaId);
          await facturaRepository.delete(facturaId);
          emit(FacturaError('Error al crear los detalles de la factura'));
          return;
        }
      }

      // Cargar la lista actualizada de facturas
      final facturas = await facturaRepository.getAll();
      emit(FacturaLoaded(facturas));
      
    } catch (e) {
      emit(FacturaError('Error al guardar la factura: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateFacturaEstado(UpdateFacturaEstado event, Emitter<FacturaState> emit) async {
    try {
      final factura = await facturaRepository.getById(event.id);
      if (factura != null) {
        final updated = Factura(
          id: factura.id,
          clienteId: factura.clienteId,
          numeroFactura: factura.numeroFactura,
          fecha: factura.fecha,
          subtotal: factura.subtotal,
          impuesto: factura.impuesto,
          descuento: factura.descuento,
          total: factura.total,
          estado: event.estado,
          notas: factura.notas,
        );
        await facturaRepository.update(updated);
        add(LoadFacturas());
      }
    } catch (e) {
      emit(FacturaError(e.toString()));
    }
  }

  Future<void> _onDeleteFactura(DeleteFactura event, Emitter<FacturaState> emit) async {
    try {
      await detalleRepository.deleteByFacturaId(event.id);
      await facturaRepository.delete(event.id);
      add(LoadFacturas());
    } catch (e) {
      emit(FacturaError(e.toString()));
    }
  }
}