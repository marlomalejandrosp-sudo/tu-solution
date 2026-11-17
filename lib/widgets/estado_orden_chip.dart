import 'package:flutter/material.dart';

import '../core/estado_colores.dart';
import '../models/enums.dart';

/// Etiqueta de color con el estado de una orden.
class EstadoOrdenChip extends StatelessWidget {
  const EstadoOrdenChip(this.estado, {super.key});

  final EstadoOrden estado;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final texto = estado.texto(colores);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: estado.fondo(colores),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(estado.icono, size: 14, color: texto),
            const SizedBox(width: 4),
            Text(
              estado.etiqueta,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: texto, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
