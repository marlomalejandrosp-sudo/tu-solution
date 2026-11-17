import 'package:drift/drift.dart';

import '../models/enums.dart';
import '../models/vistas.dart';
import 'app_database.dart';

/// Error por incumplir una regla del taller (por ejemplo, tomar una orden
/// que ya tomó otro técnico). Su mensaje se puede mostrar al usuario.
class ReglaError implements Exception {
  const ReglaError(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Único punto de acceso a la base de datos (patrón Repository). La interfaz
/// y los providers piden datos aquí y no saben que detrás hay Drift.
///
/// - Las lecturas son Streams (`watch`): emiten de nuevo cuando la tabla
///   cambia, así las pantallas se actualizan solas.
/// - Las reglas del taller se comprueban DENTRO de las transacciones, justo
///   antes de escribir: si algo falla, no se guarda nada.
class TallerRepository {
  TallerRepository(this._db);

  final AppDatabase _db;

  // ═════════════════════════ Lecturas (Streams) ═════════════════════════

  Stream<List<Cliente>> watchClientes() => (_db.select(_db.clientes)
        ..orderBy([(c) => OrderingTerm.asc(c.nombre)]))
      .watch();

  Stream<Cliente?> watchCliente(int id) =>
      (_db.select(_db.clientes)..where((c) => c.id.equals(id)))
          .watchSingleOrNull();

  Stream<List<Equipo>> watchEquipos() => (_db.select(_db.equipos)
        ..orderBy([(e) => OrderingTerm.asc(e.marca), (e) => OrderingTerm.asc(e.modelo)]))
      .watch();

  Stream<Equipo?> watchEquipo(int id) =>
      (_db.select(_db.equipos)..where((e) => e.id.equals(id)))
          .watchSingleOrNull();

  Stream<List<Tecnico>> watchTecnicos() => (_db.select(_db.tecnicos)
        ..orderBy([(t) => OrderingTerm.asc(t.id)]))
      .watch();

  Stream<List<Repuesto>> watchRepuestos() => (_db.select(_db.repuestos)
        ..orderBy([(r) => OrderingTerm.asc(r.nombre)]))
      .watch();

  /// Se emite cada vez que cambia cualquier tabla que forma una orden.
  Stream<List<QueryRow>> _cambiosEnOrdenes() => _db.customSelect(
        'SELECT 1',
        readsFrom: {
          _db.ordenes,
          _db.equipos,
          _db.clientes,
          _db.tecnicos,
          _db.trabajos,
          _db.repuestosUsados,
          _db.repuestos,
        },
      ).watch();

  Stream<List<OrdenVista>> watchOrdenes() =>
      _cambiosEnOrdenes().asyncMap((_) => _cargarOrdenes());

  Stream<OrdenVista?> watchOrden(int id) => _cambiosEnOrdenes()
      .asyncMap((_) async => (await _cargarOrdenes(soloId: id)).firstOrNull);

  /// Arma las órdenes con un JOIN (orden + equipo + cliente + técnico) y
  /// añade sus trabajos y repuestos.
  Future<List<OrdenVista>> _cargarOrdenes({int? soloId}) async {
    final o = _db.ordenes;
    final consulta = _db.select(o).join([
      innerJoin(_db.equipos, _db.equipos.id.equalsExp(o.equipoId)),
      innerJoin(_db.clientes, _db.clientes.id.equalsExp(_db.equipos.clienteId)),
      leftOuterJoin(_db.tecnicos, _db.tecnicos.id.equalsExp(o.tecnicoId)),
    ]);
    if (soloId != null) consulta.where(o.id.equals(soloId));
    consulta.orderBy([
      OrderingTerm.desc(o.fechaEntrada),
      OrderingTerm.desc(o.id),
    ]);
    final filas = await consulta.get();
    if (filas.isEmpty) return const [];

    final ids = [for (final f in filas) f.readTable(o).id];

    final trabajos = await (_db.select(_db.trabajos)
          ..where((t) => t.ordenId.isIn(ids))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    final trabajosPorOrden = <int, List<Trabajo>>{};
    for (final t in trabajos) {
      (trabajosPorOrden[t.ordenId] ??= []).add(t);
    }

    final usos = _db.repuestosUsados;
    final filasUsos = await (_db.select(usos).join([
      innerJoin(_db.repuestos, _db.repuestos.id.equalsExp(usos.repuestoId)),
    ])
          ..where(usos.ordenId.isIn(ids))
          ..orderBy([OrderingTerm.asc(usos.id)]))
        .get();
    final repuestosPorOrden = <int, List<LineaRepuesto>>{};
    for (final f in filasUsos) {
      final uso = f.readTable(usos);
      (repuestosPorOrden[uso.ordenId] ??= []).add(
        LineaRepuesto(uso: uso, repuesto: f.readTable(_db.repuestos)),
      );
    }

    return [
      for (final f in filas)
        OrdenVista(
          orden: f.readTable(o),
          equipo: f.readTable(_db.equipos),
          cliente: f.readTable(_db.clientes),
          tecnico: f.readTableOrNull(_db.tecnicos),
          trabajos: trabajosPorOrden[f.readTable(o).id] ?? const [],
          repuestos: repuestosPorOrden[f.readTable(o).id] ?? const [],
        ),
    ];
  }

  // ═════════════════════════ Clientes ═════════════════════════

  Future<int> insertarCliente({
    required String nombre,
    required String telefono,
  }) {
    return _db.into(_db.clientes).insert(
        ClientesCompanion.insert(nombre: nombre, telefono: telefono));
  }

  Future<void> actualizarCliente(Cliente cliente) async {
    await _db.update(_db.clientes).replace(cliente);
  }

  Future<void> eliminarCliente(int id) {
    return _db.transaction(() async {
      final equipos = await (_db.select(_db.equipos)
            ..where((e) => e.clienteId.equals(id)))
          .get();
      if (equipos.isNotEmpty) {
        throw const ReglaError(
            'No se puede eliminar: el cliente tiene equipos registrados.');
      }
      await (_db.delete(_db.clientes)..where((c) => c.id.equals(id))).go();
    });
  }

  // ═════════════════════════ Equipos ═════════════════════════

  Future<void> _exigirSerieLibre(String serie, {int? excluirId}) async {
    final existente = await (_db.select(_db.equipos)
          ..where((e) => e.serie.equals(serie)))
        .getSingleOrNull();
    if (existente != null && existente.id != excluirId) {
      throw const ReglaError('Ya hay un equipo registrado con esa serie.');
    }
  }

  Future<int> insertarEquipo({
    required int clienteId,
    required TipoEquipo tipo,
    required String marca,
    required String modelo,
    required String serie,
  }) {
    return _db.transaction(() async {
      await _exigirSerieLibre(serie);
      return _db.into(_db.equipos).insert(EquiposCompanion.insert(
            clienteId: clienteId,
            tipo: tipo,
            marca: marca,
            modelo: modelo,
            serie: serie,
          ));
    });
  }

  Future<void> actualizarEquipo(Equipo equipo) {
    return _db.transaction(() async {
      await _exigirSerieLibre(equipo.serie, excluirId: equipo.id);
      await _db.update(_db.equipos).replace(equipo);
    });
  }

  Future<void> eliminarEquipo(int id) {
    return _db.transaction(() async {
      final ordenes = await (_db.select(_db.ordenes)
            ..where((o) => o.equipoId.equals(id)))
          .get();
      if (ordenes.isNotEmpty) {
        throw const ReglaError(
            'No se puede eliminar: el equipo tiene órdenes de reparación.');
      }
      await (_db.delete(_db.equipos)..where((e) => e.id.equals(id))).go();
    });
  }

  // ═════════════════════════ Inventario ═════════════════════════

  Future<void> _exigirCodigoLibre(String codigo, {int? excluirId}) async {
    final existente = await (_db.select(_db.repuestos)
          ..where((r) => r.codigo.equals(codigo)))
        .getSingleOrNull();
    if (existente != null && existente.id != excluirId) {
      throw const ReglaError('Ya hay un repuesto con ese código.');
    }
  }

  Future<int> insertarRepuesto({
    required String nombre,
    required String codigo,
    required int precio,
    required int existencias,
    required int minimo,
  }) {
    return _db.transaction(() async {
      await _exigirCodigoLibre(codigo);
      return _db.into(_db.repuestos).insert(RepuestosCompanion.insert(
            nombre: nombre,
            codigo: codigo,
            precio: precio,
            existencias: existencias,
            minimo: Value(minimo),
          ));
    });
  }

  Future<void> actualizarRepuesto(Repuesto repuesto) {
    return _db.transaction(() async {
      await _exigirCodigoLibre(repuesto.codigo, excluirId: repuesto.id);
      await _db.update(_db.repuestos).replace(repuesto);
    });
  }

  Future<void> eliminarRepuesto(int id) {
    return _db.transaction(() async {
      final usos = await (_db.select(_db.repuestosUsados)
            ..where((u) => u.repuestoId.equals(id)))
          .get();
      if (usos.isNotEmpty) {
        throw const ReglaError(
            'No se puede eliminar: el repuesto ya se usó en órdenes.');
      }
      await (_db.delete(_db.repuestos)..where((r) => r.id.equals(id))).go();
    });
  }

  /// Suma unidades al inventario (llegó una compra).
  Future<void> reponerExistencias(int repuestoId, int cantidad) {
    return _db.transaction(() async {
      final r = await _repuesto(repuestoId);
      await (_db.update(_db.repuestos)..where((t) => t.id.equals(repuestoId)))
          .write(RepuestosCompanion(existencias: Value(r.existencias + cantidad)));
    });
  }

  Future<Repuesto> _repuesto(int id) async {
    final r = await (_db.select(_db.repuestos)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (r == null) throw const ReglaError('El repuesto ya no existe.');
    return r;
  }

  // ═════════════════════════ Órdenes ═════════════════════════

  Future<Orden> _orden(int id) async {
    final o = await (_db.select(_db.ordenes)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (o == null) throw const ReglaError('La orden ya no existe.');
    return o;
  }

  Future<void> _cambiar(int ordenId, OrdenesCompanion cambios) async {
    await (_db.update(_db.ordenes)..where((o) => o.id.equals(ordenId)))
        .write(cambios);
  }

  /// Crea la orden en estado "recibida" y sin responsable. Un equipo no
  /// puede tener dos órdenes abiertas a la vez.
  Future<int> crearOrden({
    required int equipoId,
    required String falla,
    required DateTime fecha,
  }) {
    return _db.transaction(() async {
      final equipo = await (_db.select(_db.equipos)
            ..where((e) => e.id.equals(equipoId)))
          .getSingleOrNull();
      if (equipo == null) throw const ReglaError('El equipo ya no existe.');

      final deEquipo = await (_db.select(_db.ordenes)
            ..where((o) => o.equipoId.equals(equipoId)))
          .get();
      final abierta = deEquipo.where((o) => o.estado.abierta).firstOrNull;
      if (abierta != null) {
        throw ReglaError(
            'Este equipo ya tiene la orden #${abierta.id} abierta (${abierta.estado.etiqueta}).');
      }
      return _db.into(_db.ordenes).insert(OrdenesCompanion.insert(
            equipoId: equipoId,
            fechaEntrada: fecha,
            falla: falla,
            estado: EstadoOrden.recibida,
          ));
    });
  }

  Future<void> actualizarFalla(int ordenId, String falla) {
    return _db.transaction(() async {
      final o = await _orden(ordenId);
      if (!o.estado.abierta) {
        throw const ReglaError('Una orden cerrada no se puede modificar.');
      }
      await _cambiar(ordenId, OrdenesCompanion(falla: Value(falla)));
    });
  }

  /// Un técnico toma una orden recibida: queda como responsable y la orden
  /// pasa a "en reparación". Si otro técnico ya la tomó, se rechaza.
  Future<void> tomarOrden(int ordenId, int tecnicoId) {
    return _db.transaction(() async {
      final o = await _orden(ordenId);
      if (o.estado != EstadoOrden.recibida) {
        final responsable = o.tecnicoId == null
            ? null
            : await (_db.select(_db.tecnicos)
                  ..where((t) => t.id.equals(o.tecnicoId!)))
                .getSingleOrNull();
        throw ReglaError(responsable == null
            ? 'Esta orden ya no está disponible para tomar.'
            : 'Esta orden ya la tomó ${responsable.nombre}.');
      }
      final tecnico = await (_db.select(_db.tecnicos)
            ..where((t) => t.id.equals(tecnicoId)))
          .getSingleOrNull();
      if (tecnico == null) throw const ReglaError('El técnico ya no existe.');
      await _cambiar(
        ordenId,
        OrdenesCompanion(
          tecnicoId: Value(tecnicoId),
          estado: const Value(EstadoOrden.reparacion),
        ),
      );
    });
  }

  /// El técnico suelta la orden: vuelve a "recibida" y sin responsable.
  Future<void> liberarOrden(int ordenId) {
    return _db.transaction(() async {
      final o = await _orden(ordenId);
      if (o.estado != EstadoOrden.reparacion) {
        throw const ReglaError('Solo se puede liberar una orden en reparación.');
      }
      await _cambiar(
        ordenId,
        const OrdenesCompanion(
          tecnicoId: Value(null),
          estado: Value(EstadoOrden.recibida),
        ),
      );
    });
  }

  Future<void> marcarLista(int ordenId) {
    return _db.transaction(() async {
      final o = await _orden(ordenId);
      if (o.estado != EstadoOrden.reparacion) {
        throw const ReglaError(
            'Solo una orden en reparación puede pasar a lista.');
      }
      final trabajos = await (_db.select(_db.trabajos)
            ..where((t) => t.ordenId.equals(ordenId)))
          .get();
      if (trabajos.isEmpty) {
        throw const ReglaError(
            'Registra al menos un trabajo antes de marcarla lista.');
      }
      await _cambiar(
          ordenId, const OrdenesCompanion(estado: Value(EstadoOrden.lista)));
    });
  }

  Future<void> entregarOrden(int ordenId, DateTime fecha) {
    return _db.transaction(() async {
      final o = await _orden(ordenId);
      if (o.estado != EstadoOrden.lista) {
        throw const ReglaError('Solo una orden lista se puede entregar.');
      }
      await _cambiar(
        ordenId,
        OrdenesCompanion(
          estado: const Value(EstadoOrden.entregada),
          fechaEntrega: Value(fecha),
        ),
      );
    });
  }

  /// Cancela la orden y devuelve al inventario los repuestos que usaba.
  Future<void> cancelarOrden(int ordenId) {
    return _db.transaction(() async {
      final o = await _orden(ordenId);
      if (!o.estado.abierta) {
        throw const ReglaError('Solo se pueden cancelar órdenes abiertas.');
      }
      final usados = await (_db.select(_db.repuestosUsados)
            ..where((u) => u.ordenId.equals(ordenId)))
          .get();
      for (final u in usados) {
        final r = await _repuesto(u.repuestoId);
        await (_db.update(_db.repuestos)..where((t) => t.id.equals(r.id)))
            .write(RepuestosCompanion(
                existencias: Value(r.existencias + u.cantidad)));
      }
      await _cambiar(ordenId,
          const OrdenesCompanion(estado: Value(EstadoOrden.cancelada)));
    });
  }

  // ═════════════════════════ Trabajos y repuestos de una orden ═════════════════════════

  /// Solo el técnico que tiene la orden en reparación anota trabajos y
  /// repuestos.
  Future<void> _exigirEnReparacion(int ordenId) async {
    final o = await _orden(ordenId);
    if (o.estado == EstadoOrden.recibida) {
      throw const ReglaError(
          'Toma la orden para poder registrar trabajos y repuestos.');
    }
    if (o.estado != EstadoOrden.reparacion) {
      throw const ReglaError('Esta orden ya no admite cambios.');
    }
  }

  Future<void> agregarTrabajo({
    required int ordenId,
    required String descripcion,
    required int costo,
  }) {
    return _db.transaction(() async {
      await _exigirEnReparacion(ordenId);
      await _db.into(_db.trabajos).insert(TrabajosCompanion.insert(
          ordenId: ordenId, descripcion: descripcion, costo: costo));
    });
  }

  Future<void> eliminarTrabajo(int trabajoId) {
    return _db.transaction(() async {
      final t = await (_db.select(_db.trabajos)
            ..where((x) => x.id.equals(trabajoId)))
          .getSingleOrNull();
      if (t == null) return;
      await _exigirEnReparacion(t.ordenId);
      await (_db.delete(_db.trabajos)..where((x) => x.id.equals(trabajoId)))
          .go();
    });
  }

  /// Añade repuestos a la orden y BAJA las existencias del inventario, todo
  /// en una transacción. Si no alcanzan las unidades, no se hace nada.
  Future<void> agregarRepuestoAOrden({
    required int ordenId,
    required int repuestoId,
    required int cantidad,
  }) {
    return _db.transaction(() async {
      await _exigirEnReparacion(ordenId);
      final repuesto = await _repuesto(repuestoId);
      if (repuesto.existencias < cantidad) {
        throw ReglaError(
          'Solo quedan ${repuesto.existencias} unidades de "${repuesto.nombre}".',
        );
      }
      final existente = await (_db.select(_db.repuestosUsados)
            ..where((u) =>
                u.ordenId.equals(ordenId) & u.repuestoId.equals(repuestoId)))
          .getSingleOrNull();
      if (existente == null) {
        await _db
            .into(_db.repuestosUsados)
            .insert(RepuestosUsadosCompanion.insert(
              ordenId: ordenId,
              repuestoId: repuestoId,
              cantidad: cantidad,
              precioUnitario: repuesto.precio,
            ));
      } else {
        await (_db.update(_db.repuestosUsados)
              ..where((u) => u.id.equals(existente.id)))
            .write(RepuestosUsadosCompanion(
                cantidad: Value(existente.cantidad + cantidad)));
      }
      await (_db.update(_db.repuestos)..where((r) => r.id.equals(repuestoId)))
          .write(RepuestosCompanion(
              existencias: Value(repuesto.existencias - cantidad)));
    });
  }

  /// Quita el repuesto de la orden y devuelve las unidades al inventario.
  Future<void> quitarRepuestoDeOrden(int usoId) {
    return _db.transaction(() async {
      final uso = await (_db.select(_db.repuestosUsados)
            ..where((u) => u.id.equals(usoId)))
          .getSingleOrNull();
      if (uso == null) return;
      await _exigirEnReparacion(uso.ordenId);
      final repuesto = await _repuesto(uso.repuestoId);
      await (_db.delete(_db.repuestosUsados)..where((u) => u.id.equals(usoId)))
          .go();
      await (_db.update(_db.repuestos)..where((r) => r.id.equals(repuesto.id)))
          .write(RepuestosCompanion(
              existencias: Value(repuesto.existencias + uso.cantidad)));
    });
  }
}
