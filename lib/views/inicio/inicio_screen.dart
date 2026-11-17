import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formato.dart';
import '../../models/enums.dart';
import '../../models/filtros.dart';
import '../../models/vistas.dart';
import '../../providers/vistas_providers.dart';
import '../../viewmodels/filtros_viewmodel.dart';
import '../../widgets/boton_tema.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/seccion_titulo.dart';
import '../../widgets/tarjeta_dato.dart';
import '../../widgets/tarjeta_orden.dart';
import '../../widgets/valor_asincrono.dart';

/// Panel del taller: resumen de órdenes, carga de cada técnico y alertas
/// de inventario.
class InicioScreen extends ConsumerWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final conteo = ref.watch(conteoPorEstadoProvider);
    final sinResponsable = ref.watch(ordenesSinResponsableProvider);
    final alertas = ref.watch(repuestosPorAgotarseProvider);
    final carga = ref.watch(cargaTecnicosProvider);
    final abiertas = ref.watch(ordenesAbiertasProvider);

    void irAOrdenes(FiltroOrden filtro, {int? tecnico}) {
      ref.read(filtrosOrdenesProvider.notifier)
        ..elegirFiltro(filtro)
        ..elegirTecnico(tecnico);
      context.go('/ordenes');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu Solution'),
        actions: const [BotonTema()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text('Taller de reparación de electrónica',
              style: tema.textTheme.bodyMedium),
          const SizedBox(height: 16),
          _FilasTarjetas(
            tarjetas: [
              TarjetaDato(
                icono: Icons.assignment_outlined,
                etiqueta: 'Órdenes abiertas',
                valor: conteo.when(
                  data: (c) => '${c.entries.where((e) => e.key.abierta).fold(0, (s, e) => s + e.value)}',
                  loading: () => '…',
                  error: (_, _) => '—',
                ),
                onTap: () => irAOrdenes(FiltroOrden.abiertas),
              ),
              TarjetaDato(
                icono: Icons.person_off_outlined,
                etiqueta: 'Sin responsable',
                valor: sinResponsable.when(
                  data: (l) => '${l.length}',
                  loading: () => '…',
                  error: (_, _) => '—',
                ),
                resaltar: (sinResponsable.value?.length ?? 0) > 0,
                onTap: () => irAOrdenes(FiltroOrden.sinResponsable),
              ),
              TarjetaDato(
                icono: Icons.check_circle_outline,
                etiqueta: 'Listas para entregar',
                valor: conteo.when(
                  data: (c) => '${c[EstadoOrden.lista]}',
                  loading: () => '…',
                  error: (_, _) => '—',
                ),
                onTap: () => irAOrdenes(FiltroOrden.lista),
              ),
              TarjetaDato(
                icono: Icons.warning_amber_rounded,
                etiqueta: 'Repuestos por agotarse',
                valor: alertas.when(
                  data: (l) => '${l.length}',
                  loading: () => '…',
                  error: (_, _) => '—',
                ),
                resaltar: (alertas.value?.length ?? 0) > 0,
                onTap: () {
                  ref
                      .read(filtrosInventarioProvider.notifier)
                      .elegirFiltro(FiltroInventario.porAgotarse);
                  context.go('/inventario');
                },
              ),
            ],
          ),
          const SeccionTitulo('Carga de trabajo por técnico'),
          ValorAsincrono<List<CargaTecnico>>(
            valor: carga,
            builder: (lista) => Column(
              children: [
                for (final c in lista)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _FilaTecnico(
                      carga: c,
                      onTap: () =>
                          irAOrdenes(FiltroOrden.abiertas, tecnico: c.tecnico.id),
                    ),
                  ),
              ],
            ),
          ),
          SeccionTitulo(
            'Repuestos por agotarse',
            lateral: TextButton(
              onPressed: () {
                ref
                    .read(filtrosInventarioProvider.notifier)
                    .elegirFiltro(FiltroInventario.porAgotarse);
                context.go('/inventario');
              },
              child: const Text('Ver'),
            ),
          ),
          ValorAsincrono(
            valor: alertas,
            builder: (lista) {
              if (lista.isEmpty) {
                return const EstadoVacio(
                  icono: Icons.inventory_2_outlined,
                  titulo: 'Inventario al día',
                  mensaje: 'Ningún repuesto está por debajo de su mínimo.',
                );
              }
              return Column(
                children: [
                  for (final r in lista.take(4))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        r.agotado
                            ? Icons.error_outline
                            : Icons.warning_amber_rounded,
                        color: tema.colorScheme.error,
                      ),
                      title: Text(r.nombre),
                      subtitle: Text(r.codigo),
                      trailing: Text(
                        r.agotado ? 'Agotado' : '${r.existencias} u.',
                        style: tema.textTheme.titleMedium
                            ?.copyWith(color: tema.colorScheme.error),
                      ),
                    ),
                ],
              );
            },
          ),
          SeccionTitulo(
            'Órdenes abiertas',
            lateral: TextButton(
              onPressed: () => irAOrdenes(FiltroOrden.abiertas),
              child: const Text('Ver todas'),
            ),
          ),
          ValorAsincrono<List<OrdenVista>>(
            valor: abiertas,
            builder: (lista) {
              if (lista.isEmpty) {
                return const EstadoVacio(
                  icono: Icons.assignment_turned_in_outlined,
                  titulo: 'Sin órdenes abiertas',
                  mensaje: 'Cuando llegue un equipo, registra su orden.',
                );
              }
              return Column(
                children: [
                  for (final o in lista.take(5))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TarjetaOrden(orden: o),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilaTecnico extends StatelessWidget {
  const _FilaTecnico({required this.carga, required this.onTap});

  final CargaTecnico carga;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: tema.colorScheme.primaryContainer,
                child: Icon(Icons.engineering_outlined,
                    color: tema.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(carga.tecnico.nombre, style: tema.textTheme.titleMedium),
                    Text(
                      '${Formato.plural(carga.enReparacion, 'en reparación', 'en reparación')} · '
                      '${Formato.plural(carga.listas, 'lista', 'listas')}',
                      style: tema.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Text('${carga.abiertas}', style: tema.textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reparte las tarjetas en filas de dos. Cada fila toma la altura de su
/// tarjeta más alta, así el texto nunca se corta (aunque el usuario tenga
/// la letra del sistema grande).
class _FilasTarjetas extends StatelessWidget {
  const _FilasTarjetas({required this.tarjetas});

  final List<Widget> tarjetas;

  @override
  Widget build(BuildContext context) {
    final filas = <Widget>[];
    for (var i = 0; i < tarjetas.length; i += 2) {
      if (i > 0) filas.add(const SizedBox(height: 12));
      filas.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: tarjetas[i]),
              const SizedBox(width: 12),
              Expanded(
                child: i + 1 < tarjetas.length
                    ? tarjetas[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: filas);
  }
}
