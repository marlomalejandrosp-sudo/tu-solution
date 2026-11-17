import 'package:flutter/material.dart';

import '../core/estado_colores.dart';
import '../core/formato.dart';
import '../data/app_database.dart';
import '../models/vistas.dart';
import 'selector_lista.dart';

/// Atajos para elegir cosas de una lista en una hoja inferior.

Future<int?> elegirCliente(
  BuildContext context,
  List<Cliente> clientes, {
  int? seleccionado,
}) {
  return mostrarSelectorLista<int>(
    context,
    titulo: 'Elegir cliente',
    seleccionado: seleccionado,
    vacio: 'Todavía no hay clientes registrados.',
    opciones: [
      for (final c in clientes)
        OpcionLista(
          valor: c.id,
          titulo: c.nombre,
          subtitulo: Formato.telefono(c.telefono),
          icono: Icons.person_outline,
        ),
    ],
  );
}

Future<int?> elegirEquipo(
  BuildContext context,
  List<EquipoVista> equipos, {
  int? seleccionado,
}) {
  return mostrarSelectorLista<int>(
    context,
    titulo: 'Elegir equipo',
    seleccionado: seleccionado,
    vacio: 'Todavía no hay equipos registrados.',
    opciones: [
      for (final v in equipos)
        OpcionLista(
          valor: v.equipo.id,
          titulo: '${v.equipo.marca} ${v.equipo.modelo}',
          subtitulo: '${v.cliente.nombre} · ${v.equipo.serie}'
              '${v.ordenAbierta == null ? '' : ' · orden abierta'}',
          icono: v.equipo.tipo.icono,
        ),
    ],
  );
}

Future<int?> elegirTecnico(
  BuildContext context,
  List<CargaTecnico> tecnicos, {
  String titulo = 'Elegir técnico',
}) {
  return mostrarSelectorLista<int>(
    context,
    titulo: titulo,
    vacio: 'No hay técnicos registrados.',
    opciones: [
      for (final c in tecnicos)
        OpcionLista(
          valor: c.tecnico.id,
          titulo: c.tecnico.nombre,
          subtitulo: c.abiertas == 0
              ? 'Sin órdenes abiertas'
              : Formato.plural(c.abiertas, 'orden abierta', 'órdenes abiertas'),
          icono: Icons.engineering_outlined,
        ),
    ],
  );
}

Future<int?> elegirRepuesto(
  BuildContext context,
  List<Repuesto> repuestos,
) {
  return mostrarSelectorLista<int>(
    context,
    titulo: 'Elegir repuesto',
    vacio: 'El inventario está vacío.',
    opciones: [
      for (final r in repuestos)
        OpcionLista(
          valor: r.id,
          titulo: r.nombre,
          subtitulo: '${r.codigo} · ${Formato.dinero(r.precio)} · '
              '${r.agotado ? 'agotado' : '${r.existencias} disponibles'}',
          icono: Icons.memory_outlined,
        ),
    ],
  );
}
