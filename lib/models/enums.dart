/// Estados por los que pasa una orden de reparación.
///
/// OJO: la base de datos guarda la posición (índice) de cada valor. Si se
/// añade un estado nuevo, va al final; no se reordenan los existentes.
enum EstadoOrden {
  recibida('Recibida'),
  reparacion('En reparación'),
  lista('Lista'),
  entregada('Entregada'),
  cancelada('Cancelada');

  const EstadoOrden(this.etiqueta);

  final String etiqueta;

  /// Una orden está abierta mientras el taller aún tiene trabajo con ella.
  bool get abierta => this != entregada && this != cancelada;
}

/// Tipo de equipo que se repara. También se guarda por su posición.
enum TipoEquipo {
  celular('Celular'),
  tablet('Tablet'),
  laptop('Laptop'),
  otro('Otro');

  const TipoEquipo(this.etiqueta);

  final String etiqueta;
}
