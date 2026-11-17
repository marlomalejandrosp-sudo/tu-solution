import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/taller_repository.dart';
import '../models/vistas.dart';

/// Capa de datos: base de datos → repositorio → streams.
///
/// Cada `StreamProvider` envuelve un `watch` de Drift: cuando cambia la
/// tabla, el provider emite el valor nuevo y todas las pantallas que lo
/// observan se redibujan solas.

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final tallerRepositoryProvider = Provider<TallerRepository>(
  (ref) => TallerRepository(ref.watch(databaseProvider)),
);

final clientesProvider = StreamProvider<List<Cliente>>(
  (ref) => ref.watch(tallerRepositoryProvider).watchClientes(),
);

final equiposProvider = StreamProvider<List<Equipo>>(
  (ref) => ref.watch(tallerRepositoryProvider).watchEquipos(),
);

final tecnicosProvider = StreamProvider<List<Tecnico>>(
  (ref) => ref.watch(tallerRepositoryProvider).watchTecnicos(),
);

final repuestosProvider = StreamProvider<List<Repuesto>>(
  (ref) => ref.watch(tallerRepositoryProvider).watchRepuestos(),
);

final ordenesProvider = StreamProvider<List<OrdenVista>>(
  (ref) => ref.watch(tallerRepositoryProvider).watchOrdenes(),
);

/// Una sola orden (pantalla de detalle). Con `family`, cada id tiene su
/// propio stream: el detalle siempre muestra datos frescos de la base.
final ordenProvider = StreamProvider.family<OrdenVista?, int>(
  (ref, id) => ref.watch(tallerRepositoryProvider).watchOrden(id),
);

final equipoProvider = StreamProvider.family<Equipo?, int>(
  (ref, id) => ref.watch(tallerRepositoryProvider).watchEquipo(id),
);

final clienteProvider = StreamProvider.family<Cliente?, int>(
  (ref, id) => ref.watch(tallerRepositoryProvider).watchCliente(id),
);
