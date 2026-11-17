import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/acciones.dart';
import '../../core/estado_colores.dart';
import '../../core/navegacion.dart';
import '../../data/app_database.dart';
import '../../models/vistas.dart';
import '../../providers/base_providers.dart';
import '../../providers/vistas_providers.dart';
import '../../viewmodels/taller_viewmodel.dart';
import '../../widgets/dialogo_confirmacion.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/form_equipo.dart';
import '../../widgets/seccion_titulo.dart';
import '../../widgets/tarjeta_orden.dart';
import '../../widgets/valor_asincrono.dart';

/// Ficha de un equipo con su historial de reparaciones.
class EquipoDetalleScreen extends ConsumerWidget {
  const EquipoDetalleScreen({super.key, required this.equipoId});

  final int equipoId;

  Future<void> _eliminar(
      BuildContext context, WidgetRef ref, Equipo equipo) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar equipo',
      mensaje:
          'Se elimina ${equipo.marca} ${equipo.modelo}. Solo es posible si '
          'nunca tuvo órdenes.',
      textoConfirmar: 'Eliminar',
      destructivo: true,
    );
    if (!ok || !context.mounted) return;
    final bien = await avisarResultado(
      context,
      ref.read(tallerViewModelProvider).eliminarEquipo(equipo.id),
      exito: 'Equipo eliminado',
    );
    if (bien && context.mounted) volver(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final equipoAsync = ref.watch(equipoProvider(equipoId));
    final historial = ref.watch(historialEquipoProvider(equipoId));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => volver(context)),
        title: const Text('Equipo'),
        actions: [
          if (equipoAsync.value != null)
            PopupMenuButton<String>(
              onSelected: (v) {
                final e = equipoAsync.value!;
                if (v == 'editar') mostrarFormEquipo(context, equipo: e);
                if (v == 'eliminar') _eliminar(context, ref, e);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'editar', child: Text('Editar')),
                PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
              ],
            ),
        ],
      ),
      body: ValorAsincrono<Equipo?>(
        valor: equipoAsync,
        builder: (equipo) {
          if (equipo == null) {
            return const EstadoVacio(
              icono: Icons.search_off,
              titulo: 'Equipo no encontrado',
              mensaje: 'Puede que ya no exista.',
            );
          }
          final cliente = ref.watch(clienteProvider(equipo.clienteId)).value;
          final ordenes = historial.value ?? const <OrdenVista>[];
          final hayAbierta = ordenes.any((o) => o.abierta);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(equipo.tipo.icono,
                              size: 32, color: tema.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('${equipo.marca} ${equipo.modelo}',
                                style: tema.textTheme.titleLarge),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${equipo.tipo.etiqueta} · Serie ${equipo.serie}',
                          style: tema.textTheme.bodyMedium),
                      if (cliente != null) ...[
                        const Divider(height: 24),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.person_outline),
                          title: Text(cliente.nombre),
                          subtitle: const Text('Dueño'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/cliente/${cliente.id}'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: hayAbierta
                    ? null
                    : () => context.push('/orden/nueva?equipo=${equipo.id}'),
                icon: const Icon(Icons.add),
                label: Text(hayAbierta
                    ? 'Ya tiene una orden abierta'
                    : 'Nueva orden para este equipo'),
              ),
              SeccionTitulo('Historial de reparaciones (${ordenes.length})'),
              ValorAsincrono<List<OrdenVista>>(
                valor: historial,
                builder: (lista) {
                  if (lista.isEmpty) {
                    return const EstadoVacio(
                      icono: Icons.history,
                      titulo: 'Sin reparaciones',
                      mensaje: 'Este equipo todavía no ha tenido órdenes.',
                    );
                  }
                  return Column(
                    children: [
                      for (final o in lista)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TarjetaOrden(orden: o, mostrarCliente: false),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
