import '../data/app_database.dart';
import 'enums.dart';

/// Un repuesto usado en una orden, junto con los datos del inventario.
class LineaRepuesto {
  const LineaRepuesto({required this.uso, required this.repuesto});

  final RepuestoUsado uso;
  final Repuesto repuesto;

  int get subtotal => uso.cantidad * uso.precioUnitario;
}

/// Una orden con todo lo que la rodea: equipo, dueño, técnico responsable,
/// trabajos y repuestos. Los totales se calculan aquí, en el modelo, y no
/// en las pantallas.
class OrdenVista {
  const OrdenVista({
    required this.orden,
    required this.equipo,
    required this.cliente,
    required this.tecnico,
    required this.trabajos,
    required this.repuestos,
  });

  final Orden orden;
  final Equipo equipo;
  final Cliente cliente;

  /// Técnico responsable; null si nadie ha tomado la orden.
  final Tecnico? tecnico;
  final List<Trabajo> trabajos;
  final List<LineaRepuesto> repuestos;

  int get id => orden.id;
  EstadoOrden get estado => orden.estado;
  bool get abierta => estado.abierta;
  bool get sinResponsable => tecnico == null;

  /// Los trabajos y repuestos solo se anotan mientras el técnico responsable
  /// la tiene en reparación.
  bool get editable => estado == EstadoOrden.reparacion;

  int get manoObra => trabajos.fold(0, (suma, t) => suma + t.costo);
  int get totalRepuestos => repuestos.fold(0, (suma, r) => suma + r.subtotal);

  /// Costo total: mano de obra más repuestos.
  int get total => manoObra + totalRepuestos;
}

/// Trabajo abierto de un técnico (órdenes en reparación o listas que tiene
/// asignadas).
class CargaTecnico {
  const CargaTecnico({
    required this.tecnico,
    required this.enReparacion,
    required this.listas,
  });

  final Tecnico tecnico;
  final int enReparacion;
  final int listas;

  int get abiertas => enReparacion + listas;
}

/// Equipo con su dueño y su orden abierta (si tiene).
class EquipoVista {
  const EquipoVista({
    required this.equipo,
    required this.cliente,
    required this.ordenAbierta,
    required this.totalOrdenes,
  });

  final Equipo equipo;
  final Cliente cliente;
  final OrdenVista? ordenAbierta;
  final int totalOrdenes;
}

/// Cliente con el resumen de sus equipos y órdenes.
class ClienteVista {
  const ClienteVista({
    required this.cliente,
    required this.equipos,
    required this.ordenesAbiertas,
    required this.totalOrdenes,
  });

  final Cliente cliente;
  final int equipos;
  final int ordenesAbiertas;
  final int totalOrdenes;
}

/// Estado del inventario de un repuesto, para no repetir la regla en cada
/// pantalla: "por agotarse" es tener igual o menos que el mínimo definido.
extension EstadoStock on Repuesto {
  bool get agotado => existencias <= 0;
  bool get porAgotarse => existencias <= minimo;
}
