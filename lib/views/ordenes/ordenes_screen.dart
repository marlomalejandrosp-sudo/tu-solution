import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_database.dart';
import '../../models/filtros.dart';
import '../../models/vistas.dart';
import '../../providers/base_providers.dart';
import '../../providers/vistas_providers.dart';
import '../../viewmodels/filtros_viewmodel.dart';
import '../../widgets/boton_tema.dart';
import '../../widgets/campo_busqueda.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/tarjeta_orden.dart';
import '../../widgets/valor_asincrono.dart';

/// Lista de órdenes con filtros por estado, por técnico y búsqueda.
class OrdenesScreen extends ConsumerStatefulWidget {
  const OrdenesScreen({super.key});

  @override
  ConsumerState<OrdenesScreen> createState() => _OrdenesScreenState();
}

class _OrdenesScreenState extends ConsumerState<OrdenesScreen> {
  final _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtros = ref.watch(filtrosOrdenesProvider);
    final vm = ref.read(filtrosOrdenesProvider.notifier);
    final ordenes = ref.watch(ordenesFiltradasProvider);
    final tecnicos = ref.watch(tecnicosProvider).value ?? const <Tecnico>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Órdenes'),
        actions: const [BotonTema()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/orden/nueva'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva orden'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: CampoBusqueda(
              controlador: _busqueda,
              sugerencia: 'Buscar por equipo, cliente, serie o #',
              onChanged: vm.buscar,
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final f in FiltroOrden.values)
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
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Todos los técnicos'),
                    selected: filtros.tecnicoId == null,
                    onSelected: (_) => vm.elegirTecnico(null),
                  ),
                ),
                for (final t in tecnicos)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: const Icon(Icons.engineering_outlined, size: 16),
                      label: Text(t.nombre),
                      selected: filtros.tecnicoId == t.id,
                      onSelected: (_) => vm.elegirTecnico(
                          filtros.tecnicoId == t.id ? null : t.id),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ValorAsincrono<List<OrdenVista>>(
              valor: ordenes,
              builder: (lista) {
                if (lista.isEmpty) {
                  return const EstadoVacio(
                    icono: Icons.assignment_outlined,
                    titulo: 'No hay órdenes aquí',
                    mensaje:
                        'Cambia los filtros o registra una orden nueva con el botón de abajo.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: lista.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => TarjetaOrden(orden: lista[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
