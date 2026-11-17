import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../views/cliente_detalle/cliente_detalle_screen.dart';
import '../views/clientes/clientes_screen.dart';
import '../views/equipo_detalle/equipo_detalle_screen.dart';
import '../views/equipos/equipos_screen.dart';
import '../views/inicio/inicio_screen.dart';
import '../views/inventario/inventario_screen.dart';
import '../views/orden_detalle/orden_detalle_screen.dart';
import '../views/orden_form/orden_form_screen.dart';
import '../views/ordenes/ordenes_screen.dart';
import '../views/shell/shell_screen.dart';

final _raiz = GlobalKey<NavigatorState>(debugLabel: 'raiz');

/// Rutas de la app. Las cinco pestañas viven dentro del "shell" (con la
/// barra inferior); las pantallas de detalle se abren por encima.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _raiz,
    initialLocation: '/inicio',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ShellScreen(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/inicio',
              builder: (context, state) => const InicioScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/ordenes',
              builder: (context, state) => const OrdenesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/equipos',
              builder: (context, state) => const EquiposScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/clientes',
              builder: (context, state) => const ClientesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/inventario',
              builder: (context, state) => const InventarioScreen(),
            ),
          ]),
        ],
      ),
      // "nueva" va ANTES que ":id", si no go_router la leería como un id.
      GoRoute(
        parentNavigatorKey: _raiz,
        path: '/orden/nueva',
        builder: (context, state) => OrdenFormScreen(
          equipoId: int.tryParse(state.uri.queryParameters['equipo'] ?? ''),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _raiz,
        path: '/orden/:id',
        builder: (context, state) => OrdenDetalleScreen(
          ordenId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _raiz,
        path: '/equipo/:id',
        builder: (context, state) => EquipoDetalleScreen(
          equipoId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _raiz,
        path: '/cliente/:id',
        builder: (context, state) => ClienteDetalleScreen(
          clienteId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
    ],
  );
});
