import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/acciones.dart';
import '../../core/estado_colores.dart';
import '../../core/formato.dart';
import '../../core/navegacion.dart';
import '../../data/app_database.dart';
import '../../models/vistas.dart';
import '../../providers/base_providers.dart';
import '../../providers/vistas_providers.dart';
import '../../viewmodels/taller_viewmodel.dart';
import '../../widgets/dialogo_confirmacion.dart';
import '../../widgets/estado_orden_chip.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/form_cliente.dart';
import '../../widgets/form_equipo.dart';
import '../../widgets/seccion_titulo.dart';
import '../../widgets/tarjeta_orden.dart';
import '../../widgets/valor_asincrono.dart';

/// Ficha de un cliente: sus equipos y todo su historial de órdenes.
class ClienteDetalleScreen extends ConsumerWidget {
  const ClienteDetalleScreen({super.key, required this.clienteId});

  final int clienteId;

  Future<void> _eliminar(
      BuildContext context, WidgetRef ref, Cliente cliente) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar cliente',
      mensaje:
          'Se elimina a ${cliente.nombre}. Solo es posible si no tiene equipos '
          'registrados.',
      textoConfirmar: 'Eliminar',
      destructivo: true,
    );
    if (!ok || !context.mounted) return;
    final bien = await avisarResultado(
      context,
      ref.read(tallerViewModelProvider).eliminarCliente(cliente.id),
      exito: 'Cliente eliminado',
    );
    if (bien && context.mounted) volver(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final clienteAsync = ref.watch(clienteProvider(clienteId));
    final equipos = ref.watch(equiposDeClienteProvider(clienteId));
    final historial = ref.watch(historialClienteProvider(clienteId));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => volver(context)),
        title: const Text('Cliente'),
        actions: [
          if (clienteAsync.value != null)
            PopupMenuButton<String>(
              onSelected: (v) {
                final c = clienteAsync.value!;
                if (v == 'editar') mostrarFormCliente(context, cliente: c);
                if (v == 'eliminar') _eliminar(context, ref, c);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'editar', child: Text('Editar')),
                PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
              ],
            ),
        ],
      ),
      body: ValorAsincrono<Cliente?>(
        valor: clienteAsync,
        builder: (cliente) {
          if (cliente == null) {
            return const EstadoVacio(
              icono: Icons.search_off,
              titulo: 'Cliente no encontrado',
              mensaje: 'Puede que ya no exista.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: tema.colorScheme.primaryContainer,
                        child: Icon(Icons.person,
                            color: tema.colorScheme.onPrimaryContainer),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cliente.nombre,
                                style: tema.textTheme.titleLarge),
                            Text(Formato.telefono(cliente.telefono),
                                style: tema.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SeccionTitulo(
                'Equipos',
                lateral: TextButton.icon(
                  onPressed: () =>
                      mostrarFormEquipo(context, clienteId: cliente.id),
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir'),
                ),
              ),
              ValorAsincrono<List<EquipoVista>>(
                valor: equipos,
                builder: (lista) {
                  if (lista.isEmpty) {
                    return const EstadoVacio(
                      icono: Icons.devices_other_outlined,
                      titulo: 'Sin equipos',
                      mensaje: 'Este cliente todavía no tiene equipos.',
                    );
                  }
                  return Column(
                    children: [
                      for (final v in lista)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              onTap: () =>
                                  context.push('/equipo/${v.equipo.id}'),
                              leading: Icon(v.equipo.tipo.icono,
                                  color: tema.colorScheme.primary),
                              title: Text(
                                  '${v.equipo.marca} ${v.equipo.modelo}'),
                              subtitle: Text('Serie ${v.equipo.serie}'),
                              trailing: v.ordenAbierta == null
                                  ? null
                                  : EstadoOrdenChip(v.ordenAbierta!.estado),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              SeccionTitulo(
                  'Historial de órdenes (${historial.value?.length ?? 0})'),
              ValorAsincrono<List<OrdenVista>>(
                valor: historial,
                builder: (lista) {
                  if (lista.isEmpty) {
                    return const EstadoVacio(
                      icono: Icons.history,
                      titulo: 'Sin órdenes',
                      mensaje: 'Este cliente todavía no ha dejado equipos.',
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
