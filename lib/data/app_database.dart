import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/enums.dart';
import 'datos_ejemplo.dart';
import 'tablas.dart';

// Este archivo lo genera Drift con: dart run build_runner build
part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Clientes,
    Equipos,
    Tecnicos,
    Repuestos,
    Ordenes,
    Trabajos,
    RepuestosUsados,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Sin argumentos abre la base de datos real, un archivo SQLite en el
  /// teléfono: funciona sin internet y conserva los datos al cerrar la app.
  AppDatabase([QueryExecutor? ejecutor])
      : super(ejecutor ?? driftDatabase(name: 'tu_solution'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrador) async {
          await migrador.createAll();
          // Primera vez que se abre la app: se cargan los tres técnicos y
          // unos datos de ejemplo para poder probarla de inmediato.
          await sembrarDatos(this);
        },
        beforeOpen: (detalles) async {
          // Hace que SQLite respete las claves foráneas.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
