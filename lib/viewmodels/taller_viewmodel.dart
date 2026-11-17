import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/resultado.dart';
import '../core/validadores.dart';
import '../data/app_database.dart';
import '../data/taller_repository.dart';
import '../models/enums.dart';
import '../providers/base_providers.dart';

/// ViewModel de las ACCIONES del taller (las lecturas viven en los
/// providers). La vista le pasa lo que escribió el usuario; aquí se limpia
/// el texto, se llama al repositorio y se devuelve un [Resultado] listo
/// para mostrar: o salió bien, o trae el mensaje de error.
class TallerViewModel {
  TallerViewModel(this._repo);

  final TallerRepository _repo;

  static const _errorGenerico =
      'No se pudo completar la operación. Inténtalo de nuevo.';

  Future<Resultado<void>> _aplicar(Future<void> Function() accion) async {
    try {
      await accion();
      return Resultado<void>.ok();
    } on ReglaError catch (e) {
      return Resultado<void>.fallo(e.mensaje);
    } catch (_) {
      return Resultado<void>.fallo(_errorGenerico);
    }
  }

  Future<Resultado<int>> _crear(Future<int> Function() accion) async {
    try {
      return Resultado<int>.ok(await accion());
    } on ReglaError catch (e) {
      return Resultado<int>.fallo(e.mensaje);
    } catch (_) {
      return Resultado<int>.fallo(_errorGenerico);
    }
  }

  // ───────────── Clientes ─────────────

  Future<Resultado<int>> guardarCliente({
    Cliente? existente,
    required String nombre,
    required String telefono,
  }) {
    return _crear(() async {
      if (existente == null) {
        return _repo.insertarCliente(
            nombre: nombre.trim(), telefono: telefono.trim());
      }
      await _repo.actualizarCliente(existente.copyWith(
          nombre: nombre.trim(), telefono: telefono.trim()));
      return existente.id;
    });
  }

  Future<Resultado<void>> eliminarCliente(int id) =>
      _aplicar(() => _repo.eliminarCliente(id));

  // ───────────── Equipos ─────────────

  Future<Resultado<int>> guardarEquipo({
    Equipo? existente,
    required int clienteId,
    required TipoEquipo tipo,
    required String marca,
    required String modelo,
    required String serie,
  }) {
    return _crear(() async {
      final serieLimpia = Validadores.normalizarSerie(serie);
      if (existente == null) {
        return _repo.insertarEquipo(
          clienteId: clienteId,
          tipo: tipo,
          marca: marca.trim(),
          modelo: modelo.trim(),
          serie: serieLimpia,
        );
      }
      await _repo.actualizarEquipo(existente.copyWith(
        clienteId: clienteId,
        tipo: tipo,
        marca: marca.trim(),
        modelo: modelo.trim(),
        serie: serieLimpia,
      ));
      return existente.id;
    });
  }

  Future<Resultado<void>> eliminarEquipo(int id) =>
      _aplicar(() => _repo.eliminarEquipo(id));

  // ───────────── Inventario ─────────────

  Future<Resultado<int>> guardarRepuesto({
    Repuesto? existente,
    required String nombre,
    required String codigo,
    required int precio,
    required int existencias,
    required int minimo,
  }) {
    return _crear(() async {
      final codigoLimpio = codigo.trim().toUpperCase();
      if (existente == null) {
        return _repo.insertarRepuesto(
          nombre: nombre.trim(),
          codigo: codigoLimpio,
          precio: precio,
          existencias: existencias,
          minimo: minimo,
        );
      }
      await _repo.actualizarRepuesto(existente.copyWith(
        nombre: nombre.trim(),
        codigo: codigoLimpio,
        precio: precio,
        existencias: existencias,
        minimo: minimo,
      ));
      return existente.id;
    });
  }

  Future<Resultado<void>> eliminarRepuesto(int id) =>
      _aplicar(() => _repo.eliminarRepuesto(id));

  Future<Resultado<void>> reponer(int repuestoId, int cantidad) =>
      _aplicar(() => _repo.reponerExistencias(repuestoId, cantidad));

  // ───────────── Órdenes ─────────────

  Future<Resultado<int>> crearOrden({
    required int equipoId,
    required String falla,
  }) {
    return _crear(() => _repo.crearOrden(
          equipoId: equipoId,
          falla: falla.trim(),
          fecha: DateTime.now(),
        ));
  }

  Future<Resultado<void>> editarFalla(int ordenId, String falla) =>
      _aplicar(() => _repo.actualizarFalla(ordenId, falla.trim()));

  Future<Resultado<void>> tomarOrden(int ordenId, int tecnicoId) =>
      _aplicar(() => _repo.tomarOrden(ordenId, tecnicoId));

  Future<Resultado<void>> liberarOrden(int ordenId) =>
      _aplicar(() => _repo.liberarOrden(ordenId));

  Future<Resultado<void>> marcarLista(int ordenId) =>
      _aplicar(() => _repo.marcarLista(ordenId));

  Future<Resultado<void>> entregarOrden(int ordenId) =>
      _aplicar(() => _repo.entregarOrden(ordenId, DateTime.now()));

  Future<Resultado<void>> cancelarOrden(int ordenId) =>
      _aplicar(() => _repo.cancelarOrden(ordenId));

  // ───────────── Trabajos y repuestos de una orden ─────────────

  Future<Resultado<void>> agregarTrabajo({
    required int ordenId,
    required String descripcion,
    required int costo,
  }) {
    return _aplicar(() => _repo.agregarTrabajo(
          ordenId: ordenId,
          descripcion: descripcion.trim(),
          costo: costo,
        ));
  }

  Future<Resultado<void>> eliminarTrabajo(int trabajoId) =>
      _aplicar(() => _repo.eliminarTrabajo(trabajoId));

  Future<Resultado<void>> agregarRepuesto({
    required int ordenId,
    required int repuestoId,
    required int cantidad,
  }) {
    return _aplicar(() => _repo.agregarRepuestoAOrden(
          ordenId: ordenId,
          repuestoId: repuestoId,
          cantidad: cantidad,
        ));
  }

  Future<Resultado<void>> quitarRepuesto(int usoId) =>
      _aplicar(() => _repo.quitarRepuestoDeOrden(usoId));
}

final tallerViewModelProvider = Provider<TallerViewModel>(
  (ref) => TallerViewModel(ref.watch(tallerRepositoryProvider)),
);
