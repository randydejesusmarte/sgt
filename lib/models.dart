import 'package:equatable/equatable.dart';

class Cliente extends Equatable {
  final int? id;
  final String nombre;
  final String telefono;
  final String? email;
  final String? direccion;
  final DateTime createdAt;

  const Cliente({
    this.id,
    required this.nombre,
    required this.telefono,
    this.email,
    this.direccion,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      telefono: map['telefono'] as String,
      email: map['email'] as String?,
      direccion: map['direccion'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, nombre, telefono, email, direccion, createdAt];
}


class Vehiculo extends Equatable {
  final int? id;
  final int clienteId;
  final String marca;
  final String modelo;
  final int anio;
  final String placa;

  const Vehiculo({
    this.id,
    required this.clienteId,
    required this.marca,
    required this.modelo,
    required this.anio,
    required this.placa,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'marca': marca,
      'modelo': modelo,
      'anio': anio,
      'placa': placa,
    };
  }

  factory Vehiculo.fromMap(Map<String, dynamic> map) {
    return Vehiculo(
      id: map['id'] as int?,
      clienteId: map['cliente_id'] as int,
      marca: map['marca'] as String,
      modelo: map['modelo'] as String,
      anio: map['anio'] as int,
      placa: map['placa'] as String,
    );
  }

  @override
  List<Object?> get props => [id, clienteId, marca, modelo, anio, placa];
}


class Servicio extends Equatable {
  final int? id;
  final int vehiculoId;
  final int? empleadoId;
  final String descripcion;
  final double costo;
  final DateTime fecha;
  final String estado;
  final String? notas;

  const Servicio({
    this.id,
    required this.vehiculoId,
    this.empleadoId,
    required this.descripcion,
    required this.costo,
    required this.fecha,
    required this.estado,
    this.notas,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehiculo_id': vehiculoId,
      'empleado_id': empleadoId,
      'descripcion': descripcion,
      'costo': costo,
      'fecha': fecha.toIso8601String(),
      'estado': estado,
      'notas': notas,
    };
  }

  factory Servicio.fromMap(Map<String, dynamic> map) {
    return Servicio(
      id: map['id'] as int?,
      vehiculoId: map['vehiculo_id'] as int,
      empleadoId: map['empleado_id'] as int?,
      descripcion: map['descripcion'] as String,
      costo: map['costo'] as double,
      fecha: DateTime.parse(map['fecha'] as String),
      estado: map['estado'] as String,
      notas: map['notas'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, vehiculoId, empleadoId, descripcion, costo, fecha, estado, notas];
}


class Empleado extends Equatable {
  final int? id;
  final String nombre;
  final String telefono;
  final String? especialidad;
  final bool activo;
  final DateTime createdAt;

  const Empleado({
    this.id,
    required this.nombre,
    required this.telefono,
    this.especialidad,
    this.activo = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'especialidad': especialidad,
      'activo': activo ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Empleado.fromMap(Map<String, dynamic> map) {
    return Empleado(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      telefono: map['telefono'] as String,
      especialidad: map['especialidad'] as String?,
      activo: (map['activo'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, nombre, telefono, especialidad, activo, createdAt];
}


class Compra extends Equatable {
  final int? id;
  final int servicioId;
  final String item;
  final int cantidad;
  final double precioUnitario;
  final double total;
  final DateTime fecha;

  const Compra({
    this.id,
    required this.servicioId,
    required this.item,
    required this.cantidad,
    required this.precioUnitario,
    required this.total,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'servicio_id': servicioId,
      'item': item,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'total': total,
      'fecha': fecha.toIso8601String(),
    };
  }

  factory Compra.fromMap(Map<String, dynamic> map) {
    return Compra(
      id: map['id'] as int?,
      servicioId: map['servicio_id'] as int,
      item: map['item'] as String,
      cantidad: map['cantidad'] as int,
      precioUnitario: map['precio_unitario'] as double,
      total: map['total'] as double,
      fecha: DateTime.parse(map['fecha'] as String),
    );
  }

  @override
  List<Object?> get props => [id, servicioId, item, cantidad, precioUnitario, total, fecha];
}


class Factura extends Equatable {
  final int? id;
  final int clienteId;
  final String numeroFactura;
  final DateTime fecha;
  final double subtotal;
  final double impuesto;
  final double descuento;
  final double total;
  final String estado;
  final String? notas;

  const Factura({
    this.id,
    required this.clienteId,
    required this.numeroFactura,
    required this.fecha,
    required this.subtotal,
    required this.impuesto,
    required this.descuento,
    required this.total,
    required this.estado,
    this.notas,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'numero_factura': numeroFactura,
      'fecha': fecha.toIso8601String(),
      'subtotal': subtotal,
      'impuesto': impuesto,
      'descuento': descuento,
      'total': total,
      'estado': estado,
      'notas': notas,
    };
  }

  factory Factura.fromMap(Map<String, dynamic> map) {
    return Factura(
      id: map['id'] as int?,
      clienteId: map['cliente_id'] as int,
      numeroFactura: map['numero_factura'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
      subtotal: map['subtotal'] as double,
      impuesto: map['impuesto'] as double,
      descuento: map['descuento'] as double,
      total: map['total'] as double,
      estado: map['estado'] as String,
      notas: map['notas'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, clienteId, numeroFactura, fecha, subtotal, impuesto, descuento, total, estado, notas];
}


class DetalleFactura extends Equatable {
  final int? id;
  final int facturaId;
  final int? servicioId;
  final String descripcion;
  final int cantidad;
  final double precioUnitario;
  final double total;

  const DetalleFactura({
    this.id,
    required this.facturaId,
    this.servicioId,
    required this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'factura_id': facturaId,
      'servicio_id': servicioId,
      'descripcion': descripcion,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'total': total,
    };
  }

  factory DetalleFactura.fromMap(Map<String, dynamic> map) {
    return DetalleFactura(
      id: map['id'] as int?,
      facturaId: map['factura_id'] as int,
      servicioId: map['servicio_id'] as int?,
      descripcion: map['descripcion'] as String,
      cantidad: map['cantidad'] as int,
      precioUnitario: map['precio_unitario'] as double,
      total: map['total'] as double,
    );
  }

  @override
  List<Object?> get props => [id, facturaId, servicioId, descripcion, cantidad, precioUnitario, total];
}


// ========== NUEVOS MODELOS PARA INVENTARIO ==========

class Inventario extends Equatable {
  final int? id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final int cantidadDisponible;
  final double precioCompra;
  final double precioVenta;
  final String? categoria;
  final DateTime createdAt;

  const Inventario({
    this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.cantidadDisponible,
    required this.precioCompra,
    required this.precioVenta,
    this.categoria,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'cantidad_disponible': cantidadDisponible,
      'precio_compra': precioCompra,
      'precio_venta': precioVenta,
      'categoria': categoria,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Inventario.fromMap(Map<String, dynamic> map) {
    return Inventario(
      id: map['id'] as int?,
      codigo: map['codigo'] as String,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      cantidadDisponible: map['cantidad_disponible'] as int,
      precioCompra: map['precio_compra'] as double,
      precioVenta: map['precio_venta'] as double,
      categoria: map['categoria'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Inventario copyWith({
    int? id,
    String? codigo,
    String? nombre,
    String? descripcion,
    int? cantidadDisponible,
    double? precioCompra,
    double? precioVenta,
    String? categoria,
    DateTime? createdAt,
  }) {
    return Inventario(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      cantidadDisponible: cantidadDisponible ?? this.cantidadDisponible,
      precioCompra: precioCompra ?? this.precioCompra,
      precioVenta: precioVenta ?? this.precioVenta,
      categoria: categoria ?? this.categoria,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        codigo,
        nombre,
        descripcion,
        cantidadDisponible,
        precioCompra,
        precioVenta,
        categoria,
        createdAt
      ];
}


class MovimientoInventario extends Equatable {
  final int? id;
  final int inventarioId;
  final String tipo; // 'entrada' o 'salida'
  final int cantidad;
  final String? referencia; // Puede ser ID de factura, compra, etc.
  final String? motivo;
  final DateTime fecha;

  const MovimientoInventario({
    this.id,
    required this.inventarioId,
    required this.tipo,
    required this.cantidad,
    this.referencia,
    this.motivo,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inventario_id': inventarioId,
      'tipo': tipo,
      'cantidad': cantidad,
      'referencia': referencia,
      'motivo': motivo,
      'fecha': fecha.toIso8601String(),
    };
  }

  factory MovimientoInventario.fromMap(Map<String, dynamic> map) {
    return MovimientoInventario(
      id: map['id'] as int?,
      inventarioId: map['inventario_id'] as int,
      tipo: map['tipo'] as String,
      cantidad: map['cantidad'] as int,
      referencia: map['referencia'] as String?,
      motivo: map['motivo'] as String?,
      fecha: DateTime.parse(map['fecha'] as String),
    );
  }

  @override
  List<Object?> get props => [id, inventarioId, tipo, cantidad, referencia, motivo, fecha];
}