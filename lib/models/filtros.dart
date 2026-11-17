import 'enums.dart';

/// Opciones del filtro de la lista de órdenes.
enum FiltroOrden {
  abiertas('Abiertas'),
  sinResponsable('Sin responsable'),
  recibida('Recibidas'),
  reparacion('En reparación'),
  lista('Listas'),
  entregada('Entregadas'),
  cancelada('Canceladas'),
  todas('Todas');

  const FiltroOrden(this.etiqueta);

  final String etiqueta;

  /// ¿Esta orden entra en el filtro? ([tieneResponsable] y [estado] son
  /// los datos de la orden que se evalúa).
  bool acepta(EstadoOrden estado, bool tieneResponsable) => switch (this) {
        FiltroOrden.abiertas => estado.abierta,
        FiltroOrden.sinResponsable => estado.abierta && !tieneResponsable,
        FiltroOrden.recibida => estado == EstadoOrden.recibida,
        FiltroOrden.reparacion => estado == EstadoOrden.reparacion,
        FiltroOrden.lista => estado == EstadoOrden.lista,
        FiltroOrden.entregada => estado == EstadoOrden.entregada,
        FiltroOrden.cancelada => estado == EstadoOrden.cancelada,
        FiltroOrden.todas => true,
      };
}

/// Estado inmutable de los filtros de la pantalla de órdenes.
class FiltrosOrdenes {
  const FiltrosOrdenes({
    this.filtro = FiltroOrden.abiertas,
    this.tecnicoId,
    this.busqueda = '',
  });

  final FiltroOrden filtro;

  /// null = cualquier técnico.
  final int? tecnicoId;
  final String busqueda;

  FiltrosOrdenes copyWith({
    FiltroOrden? filtro,
    String? busqueda,
  }) =>
      FiltrosOrdenes(
        filtro: filtro ?? this.filtro,
        tecnicoId: tecnicoId,
        busqueda: busqueda ?? this.busqueda,
      );

  /// Aparte porque `copyWith` no distingue "no cambiar" de "quitar".
  FiltrosOrdenes conTecnico(int? id) =>
      FiltrosOrdenes(filtro: filtro, tecnicoId: id, busqueda: busqueda);

  @override
  bool operator ==(Object other) =>
      other is FiltrosOrdenes &&
      other.filtro == filtro &&
      other.tecnicoId == tecnicoId &&
      other.busqueda == busqueda;

  @override
  int get hashCode => Object.hash(filtro, tecnicoId, busqueda);
}

/// Opciones del filtro del inventario.
enum FiltroInventario {
  todos('Todos'),
  porAgotarse('Por agotarse'),
  agotados('Agotados');

  const FiltroInventario(this.etiqueta);

  final String etiqueta;
}

class FiltrosInventario {
  const FiltrosInventario({
    this.filtro = FiltroInventario.todos,
    this.busqueda = '',
  });

  final FiltroInventario filtro;
  final String busqueda;

  FiltrosInventario copyWith({FiltroInventario? filtro, String? busqueda}) =>
      FiltrosInventario(
        filtro: filtro ?? this.filtro,
        busqueda: busqueda ?? this.busqueda,
      );

  @override
  bool operator ==(Object other) =>
      other is FiltrosInventario &&
      other.filtro == filtro &&
      other.busqueda == busqueda;

  @override
  int get hashCode => Object.hash(filtro, busqueda);
}
