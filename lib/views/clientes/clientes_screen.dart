import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formato.dart';
import '../../models/vistas.dart';
import '../../providers/vistas_providers.dart';
import '../../viewmodels/filtros_viewmodel.dart';
import '../../widgets/boton_tema.dart';
import '../../widgets/campo_busqueda.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/form_cliente.dart';
import '../../widgets/valor_asincrono.dart';

/// Lista de clientes del taller.
class ClientesScreen extends ConsumerStatefulWidget {
  const ClientesScreen({super.key});

  @override
  ConsumerState<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends ConsumerState<ClientesScreen> {
  final _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientes = ref.watch(clientesFiltradosProvider);
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: const [BotonTema()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => mostrarFormCliente(context),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Nuevo cliente'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: CampoBusqueda(
              controlador: _busqueda,
              sugerencia: 'Buscar por nombre o teléfono',
              onChanged: ref.read(busquedaClientesProvider.notifier).cambiar,
            ),
          ),
          Expanded(
            child: ValorAsincrono<List<ClienteVista>>(
              valor: clientes,
              builder: (lista) {
                if (lista.isEmpty) {
                  return const EstadoVacio(
                    icono: Icons.people_outline,
                    titulo: 'No hay clientes',
                    mensaje: 'Registra un cliente o cambia la búsqueda.',
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
                        onTap: () => context.push('/cliente/${v.cliente.id}'),
                        leading: CircleAvatar(
                          backgroundColor: tema.colorScheme.primaryContainer,
                          child: Text(
                            v.cliente.nombre.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                                color: tema.colorScheme.onPrimaryContainer),
                          ),
                        ),
                        title: Text(v.cliente.nombre),
                        subtitle: Text(
                            '${Formato.telefono(v.cliente.telefono)} · '
                            '${Formato.plural(v.equipos, 'equipo', 'equipos')}'),
                        trailing: v.ordenesAbiertas == 0
                            ? null
                            : Badge(
                                label: Text('${v.ordenesAbiertas}'),
                                child: const Icon(Icons.assignment_outlined),
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
