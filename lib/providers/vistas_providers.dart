import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/texto_utils.dart';
import '../data/app_database.dart';
import '../models/enums.dart';
import '../models/filtros.dart';
import '../models/vistas.dart';
import '../viewmodels/filtros_viewmodel.dart';
import 'base_providers.dart';
import 'combinar.dart';

/// Datos DERIVADOS: se calculan a partir de los streams base. Son lo que
/// pide el enunciado (órdenes abiertas, carga por técnico, historiales,
/// repuestos por agotarse...). Si cambia la base, se recalculan solos.

// ───────────────────────── Órdenes ─────────────────────────

final ordenesAbiertasProvider = Provider<AsyncValue<List<OrdenVista>>>((ref) {
  return ref
      .watch(ordenesProvider)
      .whenData((l) => l.where((o) => o.abierta).toList());
});

final ordenesSinResponsableProvider =
    Provider<AsyncValue<List<OrdenVista>>>((ref) {
  return ref
      .watch(ordenesProvider)
      .whenData((l) => l.where((o) => o.abierta && o.sinResponsable).toList());
});

/// Cuántas órdenes hay en cada estado.
final conteoPorEstadoProvider =
    Provider<AsyncValue<Map<EstadoOrden, int>>>((ref) {
  return ref.watch(ordenesProvider).whenData((l) {
    final conteo = {for (final e in EstadoOrden.values) e: 0};
    for (final o in l) {
      conteo[o.estado] = conteo[o.estado]! + 1;
    }
    return conteo;
  });
});

/// Órdenes según los filtros elegidos en pantalla.
final ordenesFiltradasProvider = Provider<AsyncValue<List<OrdenVista>>>((ref) {
  final f = ref.watch(filtrosOrdenesProvider);
  return ref.watch(ordenesProvider).whenData((lista) {
    final texto = normalizar(f.busqueda.trim());
    return lista.where((o) {
      if (!f.filtro.acepta(o.estado, !o.sinResponsable)) return false;
      if (f.tecnicoId != null && o.orden.tecnicoId != f.tecnicoId) {
        return false;
      }
      if (texto.isEmpty) return true;
      final pajar = normalizar(
        '#${o.id} ${o.equipo.marca} ${o.equipo.modelo} ${o.equipo.serie} '
        '${o.cliente.nombre} ${o.orden.falla} ${o.tecnico?.nombre ?? ''}',
      );
      return pajar.contains(texto);
    }).toList();
  });
});

// ───────────────────────── Técnicos ─────────────────────────

/// Carga de trabajo de cada técnico (órdenes abiertas que tiene).
final cargaTecnicosProvider = Provider<AsyncValue<List<CargaTecnico>>>((ref) {
  return combinar2<List<Tecnico>, List<OrdenVista>, List<CargaTecnico>>(
    ref.watch(tecnicosProvider),
    ref.watch(ordenesProvider),
    (tecnicos, ordenes) => [
      for (final t in tecnicos)
        CargaTecnico(
          tecnico: t,
          enReparacion: ordenes
              .where((o) =>
                  o.orden.tecnicoId == t.id &&
                  o.estado == EstadoOrden.reparacion)
              .length,
          listas: ordenes
              .where((o) =>
                  o.orden.tecnicoId == t.id && o.estado == EstadoOrden.lista)
              .length,
        ),
    ],
  );
});

// ───────────────────────── Equipos y clientes ─────────────────────────

final equiposVistaProvider = Provider<AsyncValue<List<EquipoVista>>>((ref) {
  return combinar3<List<Equipo>, List<Cliente>, List<OrdenVista>,
      List<EquipoVista>>(
    ref.watch(equiposProvider),
    ref.watch(clientesProvider),
    ref.watch(ordenesProvider),
    (equipos, clientes, ordenes) {
      final porCliente = {for (final c in clientes) c.id: c};
      return [
        for (final e in equipos)
          if (porCliente[e.clienteId] != null)
            EquipoVista(
              equipo: e,
              cliente: porCliente[e.clienteId]!,
              ordenAbierta: ordenes
                  .where((o) => o.equipo.id == e.id && o.abierta)
                  .firstOrNull,
              totalOrdenes: ordenes.where((o) => o.equipo.id == e.id).length,
            ),
      ];
    },
  );
});

final equiposFiltradosProvider = Provider<AsyncValue<List<EquipoVista>>>((ref) {
  final texto = normalizar(ref.watch(busquedaEquiposProvider).trim());
  return ref.watch(equiposVistaProvider).whenData((lista) {
    if (texto.isEmpty) return lista;
    return lista
        .where((v) => normalizar(
              '${v.equipo.marca} ${v.equipo.modelo} ${v.equipo.serie} '
              '${v.equipo.tipo.etiqueta} ${v.cliente.nombre}',
            ).contains(texto))
        .toList();
  });
});

final clientesVistaProvider = Provider<AsyncValue<List<ClienteVista>>>((ref) {
  return combinar3<List<Cliente>, List<Equipo>, List<OrdenVista>,
      List<ClienteVista>>(
    ref.watch(clientesProvider),
    ref.watch(equiposProvider),
    ref.watch(ordenesProvider),
    (clientes, equipos, ordenes) => [
      for (final c in clientes)
        ClienteVista(
          cliente: c,
          equipos: equipos.where((e) => e.clienteId == c.id).length,
          ordenesAbiertas: ordenes
              .where((o) => o.cliente.id == c.id && o.abierta)
              .length,
          totalOrdenes: ordenes.where((o) => o.cliente.id == c.id).length,
        ),
    ],
  );
});

final clientesFiltradosProvider =
    Provider<AsyncValue<List<ClienteVista>>>((ref) {
  final texto = normalizar(ref.watch(busquedaClientesProvider).trim());
  return ref.watch(clientesVistaProvider).whenData((lista) {
    if (texto.isEmpty) return lista;
    return lista
        .where((v) => normalizar('${v.cliente.nombre} ${v.cliente.telefono}')
            .contains(texto))
        .toList();
  });
});

/// Equipos de un cliente.
final equiposDeClienteProvider =
    Provider.family<AsyncValue<List<EquipoVista>>, int>((ref, clienteId) {
  return ref
      .watch(equiposVistaProvider)
      .whenData((l) => l.where((v) => v.cliente.id == clienteId).toList());
});

// ───────────────────────── Historiales ─────────────────────────

/// Historial de reparaciones de un equipo (más reciente primero).
final historialEquipoProvider =
    Provider.family<AsyncValue<List<OrdenVista>>, int>((ref, equipoId) {
  return ref
      .watch(ordenesProvider)
      .whenData((l) => l.where((o) => o.equipo.id == equipoId).toList());
});

/// Historial de todas las órdenes de un cliente.
final historialClienteProvider =
    Provider.family<AsyncValue<List<OrdenVista>>, int>((ref, clienteId) {
  return ref
      .watch(ordenesProvider)
      .whenData((l) => l.where((o) => o.cliente.id == clienteId).toList());
});

// ───────────────────────── Inventario ─────────────────────────

/// Repuestos con existencias iguales o menores al mínimo (alerta).
final repuestosPorAgotarseProvider =
    Provider<AsyncValue<List<Repuesto>>>((ref) {
  return ref.watch(repuestosProvider).whenData((l) {
    final lista = l.where((r) => r.porAgotarse).toList()
      ..sort((a, b) => a.existencias.compareTo(b.existencias));
    return lista;
  });
});

final repuestosFiltradosProvider = Provider<AsyncValue<List<Repuesto>>>((ref) {
  final f = ref.watch(filtrosInventarioProvider);
  final texto = normalizar(f.busqueda.trim());
  return ref.watch(repuestosProvider).whenData((lista) {
    return lista.where((r) {
      final pasa = switch (f.filtro) {
        FiltroInventario.todos => true,
        FiltroInventario.porAgotarse => r.porAgotarse,
        FiltroInventario.agotados => r.agotado,
      };
      if (!pasa) return false;
      if (texto.isEmpty) return true;
      return normalizar('${r.nombre} ${r.codigo}').contains(texto);
    }).toList();
  });
});
