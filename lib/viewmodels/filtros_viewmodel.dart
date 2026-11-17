import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/filtros.dart';

/// Filtros de la pantalla de órdenes. El estado es inmutable: cada cambio
/// crea un objeto nuevo y Riverpod avisa a quien lo observe.
class FiltrosOrdenesViewModel extends Notifier<FiltrosOrdenes> {
  @override
  FiltrosOrdenes build() => const FiltrosOrdenes();

  void elegirFiltro(FiltroOrden filtro) =>
      state = state.copyWith(filtro: filtro);

  void elegirTecnico(int? id) => state = state.conTecnico(id);

  void buscar(String texto) => state = state.copyWith(busqueda: texto);
}

final filtrosOrdenesProvider =
    NotifierProvider<FiltrosOrdenesViewModel, FiltrosOrdenes>(
  FiltrosOrdenesViewModel.new,
);

/// Filtros del inventario.
class FiltrosInventarioViewModel extends Notifier<FiltrosInventario> {
  @override
  FiltrosInventario build() => const FiltrosInventario();

  void elegirFiltro(FiltroInventario filtro) =>
      state = state.copyWith(filtro: filtro);

  void buscar(String texto) => state = state.copyWith(busqueda: texto);
}

final filtrosInventarioProvider =
    NotifierProvider<FiltrosInventarioViewModel, FiltrosInventario>(
  FiltrosInventarioViewModel.new,
);

/// Texto de búsqueda (una instancia para equipos y otra para clientes).
class BusquedaViewModel extends Notifier<String> {
  @override
  String build() => '';

  void cambiar(String texto) => state = texto;
}

final busquedaEquiposProvider =
    NotifierProvider<BusquedaViewModel, String>(BusquedaViewModel.new);

final busquedaClientesProvider =
    NotifierProvider<BusquedaViewModel, String>(BusquedaViewModel.new);
