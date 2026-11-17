import 'package:drift/drift.dart';

import '../models/enums.dart';

// Definición de las tablas de la base de datos (Drift).
// Cada clase genera una tabla SQLite; @DataClassName fija el nombre de la
// clase de Dart que representa una fila.

/// Dueño de uno o varios equipos.
@DataClassName('Cliente')
class Clientes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text().withLength(min: 1, max: 80)();
  TextColumn get telefono => text().withLength(min: 1, max: 20)();
}

/// Equipo que se repara. Un cliente puede tener varios, y un mismo equipo
/// puede volver muchas veces (cada visita es una orden).
@DataClassName('Equipo')
class Equipos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get clienteId => integer().references(Clientes, #id)();
  IntColumn get tipo => intEnum<TipoEquipo>()();
  TextColumn get marca => text()();
  TextColumn get modelo => text()();
  // Identifica al equipo de forma única, aunque cambie de dueño.
  TextColumn get serie => text().unique()();
}

@DataClassName('Tecnico')
class Tecnicos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text()();
}

@DataClassName('Repuesto')
class Repuestos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text()();
  TextColumn get codigo => text().unique()();
  // Precio en pesos enteros.
  IntColumn get precio => integer()();
  IntColumn get existencias => integer()();
  // Con esta cantidad o menos, el repuesto se considera "por agotarse".
  IntColumn get minimo => integer().withDefault(const Constant(3))();
}

/// Orden de reparación: una visita de un equipo al taller.
@DataClassName('Orden')
class Ordenes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get equipoId => integer().references(Equipos, #id)();
  // Técnico responsable. Es null mientras nadie ha tomado la orden.
  IntColumn get tecnicoId => integer().nullable().references(Tecnicos, #id)();
  DateTimeColumn get fechaEntrada => dateTime()();
  // Se llena al entregar el equipo.
  DateTimeColumn get fechaEntrega => dateTime().nullable()();
  TextColumn get falla => text()();
  IntColumn get estado => intEnum<EstadoOrden>()();
}

/// Trabajo realizado en una orden, con su costo de mano de obra.
@DataClassName('Trabajo')
class Trabajos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ordenId => integer().references(Ordenes, #id)();
  TextColumn get descripcion => text()();
  IntColumn get costo => integer()();
}

/// Repuesto usado en una orden. Guarda el precio del momento, para que un
/// cambio posterior en el inventario no altere órdenes ya hechas.
@DataClassName('RepuestoUsado')
class RepuestosUsados extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ordenId => integer().references(Ordenes, #id)();
  IntColumn get repuestoId => integer().references(Repuestos, #id)();
  IntColumn get cantidad => integer()();
  IntColumn get precioUnitario => integer()();
}
