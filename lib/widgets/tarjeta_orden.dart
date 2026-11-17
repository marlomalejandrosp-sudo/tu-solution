import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/estado_colores.dart';
import '../core/formato.dart';
import '../models/vistas.dart';
import 'estado_orden_chip.dart';

/// Resumen de una orden: equipo, cliente, estado y quién la tiene.
class TarjetaOrden extends StatelessWidget {
  const TarjetaOrden({super.key, required this.orden, this.mostrarCliente = true});

  final OrdenVista orden;
  final bool mostrarCliente;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final equipo = orden.equipo;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/orden/${orden.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(equipo.tipo.icono, color: colores.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${equipo.marca} ${equipo.modelo}',
                      style: tema.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  EstadoOrdenChip(orden.estado),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '#${orden.id} · ${mostrarCliente ? '${orden.cliente.nombre} · ' : ''}'
                '${Formato.fecha(orden.orden.fechaEntrada)}',
                style: tema.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                orden.orden.falla,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tema.textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    orden.sinResponsable
                        ? Icons.person_off_outlined
                        : Icons.engineering_outlined,
                    size: 16,
                    color: orden.sinResponsable && orden.abierta
                        ? colores.error
                        : colores.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      orden.tecnico?.nombre ??
                          (orden.abierta ? 'Sin responsable' : '—'),
                      style: tema.textTheme.labelSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (orden.total > 0)
                    Text(Formato.dinero(orden.total),
                        style: tema.textTheme.labelSmall
                            ?.copyWith(color: colores.onSurface)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
