import 'package:drift/drift.dart';

import '../models/enums.dart';
import 'app_database.dart';

/// Datos iniciales que se cargan UNA sola vez, cuando se crea la base de
/// datos. Los tres técnicos son parte del enunciado; el resto son datos de
/// ejemplo para poder probar la app sin tener que escribirlo todo antes.
Future<void> sembrarDatos(AppDatabase db) async {
  final ahora = DateTime.now();
  DateTime hace(int dias, {int horas = 0}) =>
      ahora.subtract(Duration(days: dias, hours: horas));

  // ── Técnicos ──
  Future<int> tecnico(String nombre) =>
      db.into(db.tecnicos).insert(TecnicosCompanion.insert(nombre: nombre));
  final ernesto = await tecnico('Ernesto Valdés');
  final lazaro = await tecnico('Lázaro Pérez');
  final yaneisy = await tecnico('Yaneisy Gómez');

  // ── Repuestos (las existencias ya descuentan lo usado en las órdenes) ──
  Future<int> repuesto(String nombre, String codigo, int precio,
      int existencias, int minimo) {
    return db.into(db.repuestos).insert(RepuestosCompanion.insert(
          nombre: nombre,
          codigo: codigo,
          precio: precio,
          existencias: existencias,
          minimo: Value(minimo),
        ));
  }

  final pantallaA12 =
      await repuesto('Pantalla Samsung A12', 'PAN-A12', 3500, 4, 3);
  final bateriaIphone =
      await repuesto('Batería iPhone 11', 'BAT-I11', 2800, 2, 3);
  final conectorC =
      await repuesto('Conector de carga USB-C', 'CON-USC', 650, 9, 4);
  await repuesto('Módulo de cámara trasera', 'CAM-TRA', 2200, 0, 2);
  await repuesto('Ventilador de laptop', 'VEN-LAP', 1200, 3, 2);
  final pasta = await repuesto('Pasta térmica (tubo)', 'PAS-TER', 300, 10, 3);
  await repuesto('Teclado de laptop', 'TEC-LAP', 2600, 5, 2);
  await repuesto('Disco SSD 240 GB', 'SSD-240', 4200, 1, 2);
  await repuesto('Cargador de tablet 10W', 'CAR-T10', 900, 12, 4);
  await repuesto('Pantalla de tablet 10"', 'PAN-T10', 4800, 2, 2);

  // ── Clientes y equipos ──
  Future<int> cliente(String nombre, String telefono) => db
      .into(db.clientes)
      .insert(ClientesCompanion.insert(nombre: nombre, telefono: telefono));

  Future<int> equipo(int clienteId, TipoEquipo tipo, String marca,
      String modelo, String serie) {
    return db.into(db.equipos).insert(EquiposCompanion.insert(
          clienteId: clienteId,
          tipo: tipo,
          marca: marca,
          modelo: modelo,
          serie: serie,
        ));
  }

  final roberto = await cliente('Roberto Fernández', '52345678');
  final marta = await cliente('Marta Gil', '53456789');
  final luis = await cliente('Luis Alberto Acosta', '54567890');
  final dayana = await cliente('Dayana Ríos', '55678901');

  final a12 = await equipo(roberto, TipoEquipo.celular, 'Samsung', 'Galaxy A12',
      'R58N1234ABC');
  final iphone = await equipo(
      roberto, TipoEquipo.celular, 'Apple', 'iPhone 11', 'F2LDX9876K');
  final lenovo = await equipo(
      marta, TipoEquipo.laptop, 'Lenovo', 'IdeaPad 3', 'PF3K8M21');
  final tablet = await equipo(
      luis, TipoEquipo.tablet, 'Huawei', 'MatePad T10', 'HW10T55021');
  final xiaomi = await equipo(
      dayana, TipoEquipo.celular, 'Xiaomi', 'Redmi Note 10', 'XM10N77310');

  // ── Órdenes ──
  Future<int> orden({
    required int equipo,
    int? tecnico,
    required DateTime entrada,
    DateTime? entrega,
    required String falla,
    required EstadoOrden estado,
  }) {
    return db.into(db.ordenes).insert(OrdenesCompanion.insert(
          equipoId: equipo,
          tecnicoId: Value(tecnico),
          fechaEntrada: entrada,
          fechaEntrega: Value(entrega),
          falla: falla,
          estado: estado,
        ));
  }

  Future<void> trabajo(int ordenId, String descripcion, int costo) async {
    await db.into(db.trabajos).insert(TrabajosCompanion.insert(
        ordenId: ordenId, descripcion: descripcion, costo: costo));
  }

  Future<void> uso(int ordenId, int repuestoId, int cantidad, int precio) async {
    await db.into(db.repuestosUsados).insert(RepuestosUsadosCompanion.insert(
          ordenId: ordenId,
          repuestoId: repuestoId,
          cantidad: cantidad,
          precioUnitario: precio,
        ));
  }

  // 1. Entregada: historial del Samsung.
  final o1 = await orden(
    equipo: a12,
    tecnico: ernesto,
    entrada: hace(30),
    entrega: hace(28),
    falla: 'La pantalla se rompió al caerse',
    estado: EstadoOrden.entregada,
  );
  await trabajo(o1, 'Cambio de pantalla', 800);
  await uso(o1, pantallaA12, 1, 3500);

  // 2. Entregada: la laptop de Marta.
  final o2 = await orden(
    equipo: lenovo,
    tecnico: yaneisy,
    entrada: hace(12),
    entrega: hace(10),
    falla: 'Se calienta y se apaga sola',
    estado: EstadoOrden.entregada,
  );
  await trabajo(o2, 'Limpieza interna y pasta térmica', 600);
  await uso(o2, pasta, 1, 300);

  // 3. En reparación, tomada por Ernesto.
  final o3 = await orden(
    equipo: iphone,
    tecnico: ernesto,
    entrada: hace(3),
    falla: 'La batería dura muy poco y el equipo se apaga',
    estado: EstadoOrden.reparacion,
  );
  await trabajo(o3, 'Diagnóstico de batería', 300);
  await uso(o3, bateriaIphone, 1, 2800);

  // 4. En reparación, tomada por Lázaro.
  final o4 = await orden(
    equipo: tablet,
    tecnico: lazaro,
    entrada: hace(2),
    falla: 'No carga con ningún cargador',
    estado: EstadoOrden.reparacion,
  );
  await trabajo(o4, 'Revisión del puerto de carga', 250);

  // 5. Lista para entregar, de Yaneisy.
  final o5 = await orden(
    equipo: xiaomi,
    tecnico: yaneisy,
    entrada: hace(4),
    falla: 'El puerto de carga está flojo',
    estado: EstadoOrden.lista,
  );
  await trabajo(o5, 'Cambio de conector de carga', 500);
  await uso(o5, conectorC, 1, 650);

  // 6. Recién recibida, sin responsable.
  await orden(
    equipo: a12,
    entrada: hace(0, horas: 2),
    falla: 'No da imagen aunque enciende',
    estado: EstadoOrden.recibida,
  );

  // 7. Cancelada.
  await orden(
    equipo: lenovo,
    tecnico: lazaro,
    entrada: hace(20),
    falla: 'Ventilador ruidoso',
    estado: EstadoOrden.cancelada,
  );
}
