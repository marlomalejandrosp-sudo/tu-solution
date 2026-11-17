import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/acciones.dart';
import '../../core/formato.dart';
import '../../data/app_database.dart';
import '../../models/filtros.dart';
import '../../models/vistas.dart';
import '../../providers/vistas_providers.dart';
import '../../viewmodels/filtros_viewmodel.dart';
import '../../viewmodels/taller_viewmodel.dart';
import '../../widgets/boton_tema.dart';
import '../../widgets/campo_busqueda.dart';
import '../../widgets/dialogo_confirmacion.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/form_repuesto.dart';
import '../../widgets/valor_asincrono.dart';

/// Inventario de repuestos con alerta de existencias bajas.
class InventarioScreen extends ConsumerStatefulWidget {
  const InventarioScreen({super.key});

  @override
  ConsumerState<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends ConsumerState<InventarioScreen> {
  final _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _eliminar(Repuesto r) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar repuesto',
      mensaje:
          'Se elimina "${r.nombre}". Solo es posible si nunca se usó en una orden.',
      textoConfirmar: 'Eliminar',
      destructivo: true,
    );
    if (!ok || !mounted) return;
    await avisarResultado(
      context,
      ref.read(tallerViewModelProvider).eliminarRepuesto(r.id),
      exito: 'Repuesto eliminado',
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final filtros = ref.watch(filtrosInventarioProvider);
    final vm = ref.read(filtrosInventarioProvider.notifier);
    final repuestos = ref.watch(repuestosFiltradosProvider);
    final alertas = ref.watch(repuestosPorAgotarseProvider).value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: const [BotonTema()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => mostrarFormRepuesto(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo repuesto'),
      ),
      body: Column(
        children: [
          if (alertas > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Card(
                color: tema.colorScheme.errorContainer,
                child: ListTile(
                  leading: Icon(Icons.warning_amber_rounded,
                      color: tema.colorScheme.onErrorContainer),
                  title: Text(
                    '${Formato.plural(alertas, 'repuesto', 'repuestos')} por agotarse',
                    style: tema.textTheme.titleMedium
                        ?.copyWith(color: tema.colorScheme.onErrorContainer),
                  ),
                  onTap: () => vm.elegirFiltro(FiltroInventario.porAgotarse),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: CampoBusqueda(
              controlador: _busqueda,
              sugerencia: 'Buscar por nombre o código',
              onChanged: vm.buscar,
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final f in FiltroInventario.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f.etiqueta),
                      selected: filtros.filtro == f,
                      onSelected: (_) => vm.elegirFiltro(f),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ValorAsincrono<List<Repuesto>>(
              valor: repuestos,
              builder: (lista) {
                if (lista.isEmpty) {
                  return const EstadoVacio(
                    icono: Icons.inventory_2_outlined,
                    titulo: 'No hay repuestos aquí',
                    mensaje: 'Cambia el filtro o registra un repuesto nuevo.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: lista.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final r = lista[i];
                    final alerta = r.porAgotarse;
                    final color = alerta
                        ? tema.colorScheme.error
                        : tema.colorScheme.onSurface;
                    return Card(
                      child: ListTile(
                        onTap: () => mostrarFormRepuesto(context, repuesto: r),
                        leading: Icon(
                          r.agotado
                              ? Icons.error_outline
                              : alerta
                                  ? Icons.warning_amber_rounded
                                  : Icons.memory_outlined,
                          color: alerta ? color : tema.colorScheme.primary,
                        ),
                        title: Text(r.nombre),
                        subtitle: Text(
                            '${r.codigo} · ${Formato.dinero(r.precio)} · mínimo ${r.minimo}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${r.existencias}',
                                    style: tema.textTheme.titleLarge
                                        ?.copyWith(color: color)),
                                Text(r.agotado ? 'agotado' : 'en stock',
                                    style: tema.textTheme.labelSmall
                                        ?.copyWith(color: color)),
                              ],
                            ),
                            PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'reponer') mostrarReponer(context, r);
                                if (v == 'editar') {
                                  mostrarFormRepuesto(context, repuesto: r);
                                }
                                if (v == 'eliminar') _eliminar(r);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                    value: 'reponer', child: Text('Reponer')),
                                PopupMenuItem(
                                    value: 'editar', child: Text('Editar')),
                                PopupMenuItem(
                                    value: 'eliminar', child: Text('Eliminar')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
