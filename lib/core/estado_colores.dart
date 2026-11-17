import 'package:flutter/material.dart';

import '../models/enums.dart';

/// Colores de cada estado de orden, tomados siempre del ColorScheme del
/// tema (así cambian solos entre modo claro y oscuro).
extension EstadoOrdenColores on EstadoOrden {
  Color fondo(ColorScheme c) => switch (this) {
        EstadoOrden.recibida => c.secondaryContainer,
        EstadoOrden.reparacion => c.primaryContainer,
        EstadoOrden.lista => c.primary,
        EstadoOrden.entregada => c.surfaceContainerHighest,
        EstadoOrden.cancelada => c.errorContainer,
      };

  Color texto(ColorScheme c) => switch (this) {
        EstadoOrden.recibida => c.onSecondaryContainer,
        EstadoOrden.reparacion => c.onPrimaryContainer,
        EstadoOrden.lista => c.onPrimary,
        EstadoOrden.entregada => c.onSurfaceVariant,
        EstadoOrden.cancelada => c.onErrorContainer,
      };

  IconData get icono => switch (this) {
        EstadoOrden.recibida => Icons.inbox_outlined,
        EstadoOrden.reparacion => Icons.build_outlined,
        EstadoOrden.lista => Icons.check_circle_outline,
        EstadoOrden.entregada => Icons.verified_outlined,
        EstadoOrden.cancelada => Icons.cancel_outlined,
      };
}

extension TipoEquipoIcono on TipoEquipo {
  IconData get icono => switch (this) {
        TipoEquipo.celular => Icons.smartphone,
        TipoEquipo.tablet => Icons.tablet_android,
        TipoEquipo.laptop => Icons.laptop,
        TipoEquipo.otro => Icons.devices_other,
      };
}
