import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/acciones.dart';
import '../../core/formato.dart';
import '../../core/navegacion.dart';
import '../../models/enums.dart';
import '../../models/vistas.dart';
import '../../providers/base_providers.dart';
import '../../providers/vistas_providers.dart';
import '../../viewmodels/taller_viewmodel.dart';
import '../../widgets/dialogo_confirmacion.dart';
import '../../widgets/estado_orden_chip.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/form_orden.dart';
import '../../widgets/seccion_titulo.dart';
import '../../widgets/selectores.dart';
import '../../widgets/valor_asincrono.dart';

/// Una orden de reparación: quién la tiene, trabajos, repuestos, total y
/// las acciones que permite su estado actual.
class OrdenDetalleScreen extends ConsumerWidget {
  const OrdenDetalleScreen({super.key, required this.ordenId});

  final int ordenId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orden = ref.watch(ordenProvider(ordenId));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => volver(context)),
        title: Text('Orden #$ordenId'),
      ),
      body: ValorAsincrono<OrdenVista?>(
        valor: orden,
        builder: (o) {
          if (o == null) {
            return const EstadoVacio(
              icono: Icons.search_off,
              titulo: 'Orden no encontrada',
              mensaje: 'Puede que ya no exista.',
            );
          }
          return _Contenido(orden: o);
        },
      ),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.orden});

  final OrdenVista orden;

  TallerViewModel _vm(WidgetRef ref) => ref.read(tallerViewModelProvider);

  Future<void> _tomar(BuildContext context, WidgetRef ref) async {
    final carga = ref.read(cargaTecnicosProvider).value ?? const <CargaTecnico>[];
    final id = await elegirTecnico(context, carga,
        titulo: '¿Quién toma esta orden?');
    if (id == null || !context.mounted) return;
    await avisarResultado(
      context,
      _vm(ref).tomarOrden(orden.id, id),
      exito: 'Orden tomada. Ya está en reparación.',
    );
  }

  Future<void> _liberar(BuildContext context, WidgetRef ref) async {
    final ok = await confirmar(
      context,
      titulo: 'Liberar orden',
      mensaje:
          '${orden.tecnico?.nombre ?? 'El técnico'} deja la orden y vuelve a '
          '"Recibida" para que otro la tome. Los trabajos y repuestos ya '
          'anotados se conservan.',
      textoConfirmar: 'Liberar',
    );
    if (!ok || !context.mounted) return;
    await avisarResultado(context, _vm(ref).liberarOrden(orden.id),
        exito: 'Orden liberada');
  }

  Future<void> _lista(BuildContext context, WidgetRef ref) async {
    await avisarResultado(context, _vm(ref).marcarLista(orden.id),
        exito: 'Orden marcada como lista');
  }

  Future<void> _entregar(BuildContext context, WidgetRef ref) async {
    final ok = await confirmar(
      context,
      titulo: 'Entregar al cliente',
      mensaje:
          'Se entrega ${orden.equipo.marca} ${orden.equipo.modelo} a '
          '${orden.cliente.nombre} y se cobran ${Formato.dinero(orden.total)}.',
      textoConfirmar: 'Entregar',
    );
    if (!ok || !context.mounted) return;
    await avisarResultado(context, _vm(ref).entregarOrden(orden.id),
        exito: 'Orden entregada');
  }

  Future<void> _cancelar(BuildContext context, WidgetRef ref) async {
    final ok = await confirmar(
      context,
      titulo: 'Cancelar orden',
      mensaje: orden.repuestos.isEmpty
          ? 'La orden se marca como cancelada.'
          : 'La orden se cancela y los repuestos usados vuelven al inventario.',
      textoConfirmar: 'Cancelar orden',
      textoCancelar: 'Volver',
      destructivo: true,
    );
    if (!ok || !context.mounted) return;
    await avisarResultado(context, _vm(ref).cancelarOrden(orden.id),
        exito: 'Orden cancelada');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final equipo = orden.equipo;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        // ── Equipo y estado ──
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('${equipo.marca} ${equipo.modelo}',
                          style: tema.textTheme.titleLarge),
                    ),
                    EstadoOrdenChip(orden.estado),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Serie ${equipo.serie} · ${equipo.tipo.etiqueta}',
                    style: tema.textTheme.bodyMedium),
                const Divider(height: 24),
                _Dato(
                  icono: Icons.person_outline,
                  texto: orden.cliente.nombre,
                  detalle: Formato.telefono(orden.cliente.telefono),
                  onTap: () => context.push('/cliente/${orden.cliente.id}'),
                ),
                const SizedBox(height: 10),
                _Dato(
                  icono: orden.sinResponsable
                      ? Icons.person_off_outlined
                      : Icons.engineering_outlined,
                  texto: orden.tecnico?.nombre ??
                      (orden.abierta ? 'Sin responsable' : 'Sin técnico'),
                  detalle: orden.sinResponsable && orden.abierta
                      ? 'Nadie la ha tomado todavía'
                      : 'Responsable de la reparación',
                  alerta: orden.sinResponsable && orden.abierta,
                ),
                const SizedBox(height: 10),
                _Dato(
                  icono: Icons.devices_other_outlined,
                  texto: 'Ver ficha del equipo',
                  detalle: 'Historial de reparaciones',
                  onTap: () => context.push('/equipo/${equipo.id}'),
                ),
                const SizedBox(height: 10),
                _Dato(
                  icono: Icons.event_outlined,
                  texto: 'Entró el ${Formato.fechaHora(orden.orden.fechaEntrada)}',
                  detalle: orden.orden.fechaEntrega == null
                      ? null
                      : 'Entregada el ${Formato.fechaHora(orden.orden.fechaEntrega!)}',
                ),
              ],
            ),
          ),
        ),

        // ── Falla ──
        SeccionTitulo(
          'Falla reportada',
          lateral: orden.abierta
              ? IconButton(
                  tooltip: 'Editar falla',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () =>
                      mostrarEditarFalla(context, orden.id, orden.orden.falla),
                )
              : null,
        ),
        Text(orden.orden.falla, style: tema.textTheme.bodyMedium),

        // ── Trabajos ──
        SeccionTitulo(
          'Trabajos',
          lateral: orden.editable
              ? TextButton.icon(
                  onPressed: () => mostrarFormTrabajo(context, orden.id),
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir'),
                )
              : null,
        ),
        if (orden.trabajos.isEmpty)
          Text(
            orden.estado == EstadoOrden.recibida
                ? 'Toma la orden para registrar el trabajo.'
                : 'Todavía no hay trabajos registrados.',
            style: tema.textTheme.bodyMedium,
          )
        else
          for (final t in orden.trabajos)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.build_outlined),
              title: Text(t.descripcion),
              subtitle: const Text('Mano de obra'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(Formato.dinero(t.costo), style: tema.textTheme.titleMedium),
                  if (orden.editable)
                    IconButton(
                      tooltip: 'Quitar trabajo',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => avisarResultado(
                          context, _vm(ref).eliminarTrabajo(t.id)),
                    ),
                ],
              ),
            ),

        // ── Repuestos ──
        SeccionTitulo(
          'Repuestos usados',
          lateral: orden.editable
              ? TextButton.icon(
                  onPressed: () => mostrarFormUsarRepuesto(context, orden.id),
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir'),
                )
              : null,
        ),
        if (orden.repuestos.isEmpty)
          Text('No se han usado repuestos.', style: tema.textTheme.bodyMedium)
        else
          for (final l in orden.repuestos)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.memory_outlined),
              title: Text(l.repuesto.nombre),
              subtitle: Text(
                  '${l.uso.cantidad} × ${Formato.dinero(l.uso.precioUnitario)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(Formato.dinero(l.subtotal),
                      style: tema.textTheme.titleMedium),
                  if (orden.editable)
                    IconButton(
                      tooltip: 'Quitar repuesto',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => avisarResultado(
                        context,
                        _vm(ref).quitarRepuesto(l.uso.id),
                        exito: 'Repuesto devuelto al inventario',
                      ),
                    ),
                ],
              ),
            ),

        // ── Total ──
        const SizedBox(height: 16),
        Card(
          color: colores.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _FilaTotal('Mano de obra', orden.manoObra, tema,
                    colores.onPrimaryContainer),
                const SizedBox(height: 4),
                _FilaTotal('Repuestos', orden.totalRepuestos, tema,
                    colores.onPrimaryContainer),
                Divider(color: colores.onPrimaryContainer.withValues(alpha: 0.3)),
                _FilaTotal('Total', orden.total, tema, colores.onPrimaryContainer,
                    destacado: true),
              ],
            ),
          ),
        ),

        // ── Acciones según el estado ──
        const SizedBox(height: 20),
        ..._acciones(context, ref),
      ],
    );
  }

  List<Widget> _acciones(BuildContext context, WidgetRef ref) {
    final colores = Theme.of(context).colorScheme;
    const espacio = SizedBox(height: 10);
    final cancelar = TextButton.icon(
      onPressed: () => _cancelar(context, ref),
      icon: Icon(Icons.cancel_outlined, color: colores.error),
      label: Text('Cancelar orden', style: TextStyle(color: colores.error)),
    );

    switch (orden.estado) {
      case EstadoOrden.recibida:
        return [
          FilledButton.icon(
            onPressed: () => _tomar(context, ref),
            icon: const Icon(Icons.front_hand_outlined),
            label: const Text('Tomar orden'),
          ),
          espacio,
          cancelar,
        ];
      case EstadoOrden.reparacion:
        return [
          FilledButton.icon(
            onPressed: () => _lista(context, ref),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Marcar como lista'),
          ),
          espacio,
          OutlinedButton.icon(
            onPressed: () => _liberar(context, ref),
            icon: const Icon(Icons.undo),
            label: const Text('Liberar orden'),
          ),
          espacio,
          cancelar,
        ];
      case EstadoOrden.lista:
        return [
          FilledButton.icon(
            onPressed: () => _entregar(context, ref),
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Entregar al cliente'),
          ),
          espacio,
          cancelar,
        ];
      case EstadoOrden.entregada:
      case EstadoOrden.cancelada:
        return const [];
    }
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.icono,
    required this.texto,
    this.detalle,
    this.onTap,
    this.alerta = false,
  });

  final IconData icono;
  final String texto;
  final String? detalle;
  final VoidCallback? onTap;
  final bool alerta;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final color = alerta ? tema.colorScheme.error : tema.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Icon(icono, size: 20, color: alerta ? color : tema.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(texto,
                    style: tema.textTheme.titleMedium?.copyWith(color: color)),
                if (detalle != null)
                  Text(detalle!, style: tema.textTheme.bodyMedium),
              ],
            ),
          ),
          if (onTap != null) const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _FilaTotal extends StatelessWidget {
  const _FilaTotal(this.etiqueta, this.valor, this.tema, this.color,
      {this.destacado = false});

  final String etiqueta;
  final int valor;
  final ThemeData tema;
  final Color color;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final estilo = (destacado ? tema.textTheme.titleLarge : tema.textTheme.bodyMedium)
        ?.copyWith(color: color);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(etiqueta, style: estilo),
        Text(Formato.dinero(valor), style: estilo),
      ],
    );
  }
}
