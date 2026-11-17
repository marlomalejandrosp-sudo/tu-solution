import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/estado_colores.dart';
import '../../models/vistas.dart';
import '../../providers/vistas_providers.dart';
import '../../viewmodels/filtros_viewmodel.dart';
import '../../widgets/boton_tema.dart';
import '../../widgets/campo_busqueda.dart';
import '../../widgets/estado_orden_chip.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/form_equipo.dart';
import '../../widgets/valor_asincrono.dart';

/// Todos los equipos que han pasado por el taller.
class EquiposScreen extends ConsumerStatefulWidget {
  const EquiposScreen({super.key});

  @override
  ConsumerState<EquiposScreen> createState() => _EquiposScreenState();
}

class _EquiposScreenState extends ConsumerState<EquiposScreen> {
  final _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final equipos = ref.watch(equiposFiltradosProvider);
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipos'),
        actions: const [BotonTema()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => mostrarFormEquipo(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo equipo'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: CampoBusqueda(
              controlador: _busqueda,
              sugerencia: 'Buscar por marca, modelo, serie o dueño',
              onChanged: ref.read(busquedaEquiposProvider.notifier).cambiar,
            ),
          ),
          Expanded(
            child: ValorAsincrono<List<EquipoVista>>(
              valor: equipos,
              builder: (lista) {
                if (lista.isEmpty) {
                  return const EstadoVacio(
                    icono: Icons.devices_other_outlined,
                    titulo: 'No hay equipos',
                    mensaje: 'Registra un equipo o cambia la búsqueda.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  itemCount: lista.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final v = lista[i];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        onTap: () => context.push('/equipo/${v.equipo.id}'),
                        leading: Icon(v.equipo.tipo.icono,
                            color: tema.colorScheme.primary),
                        title: Text('${v.equipo.marca} ${v.equipo.modelo}'),
                        subtitle: Text(
                            '${v.cliente.nombre} · ${v.totalOrdenes} '
                            '${v.totalOrdenes == 1 ? 'visita' : 'visitas'}'),
                        trailing: v.ordenAbierta == null
                            ? null
                            : EstadoOrdenChip(v.ordenAbierta!.estado),
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
